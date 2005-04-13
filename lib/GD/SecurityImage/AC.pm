package GD::SecurityImage::AC;
# drop-in replacement for Authen::Captcha
use strict;
use vars qw[$VERSION $AUTOLOAD];
use GD::SecurityImage;
use Digest::MD5 qw(md5_hex);
use File::Spec;
use Fcntl qw(:flock);

$VERSION = '1.0';

sub new {
   my $class = shift;
   my %opts  = scalar(@_) % 2 ? () : (@_);
   my $self  = { gdsi => { map {$_ => ''} qw[new create particle] }, GDSI_CALLED => 0};
   bless $self, $class;
   $self->{_data_folder}   = $opts{data_folder}   if $opts{data_folder};
   $self->{_output_folder} = $opts{output_folder} if $opts{output_folder};
   foreach my $p ([expire => 300], [width => 100], [height => 32]) {
      $self->{"_".$p->[0]} = $opts{$p->[0]} && ($opts{$p->[0]} !~ /[^0-9]/) ? $opts{$p->[0]} : $p->[1];
   }
   $self->{_keep_failures} = $opts{keep_failures} ? 1 : 0;
   srand( time() ^ ($$ + ($$ << 15)) ) if $] < 5.005; # create a random seed if perl version less than 5.005
   $self;
}

sub gdsi {
   my $self = shift;
   my %opt  = scalar(@_) % 2 ? () : (@_);
      $self->{gdsi}{'new'}    = delete $opt{'new'}    if ($opt{'new'}    && ref $opt{'new'}    && ref $opt{'new'}    eq 'HASH' );
      $self->{gdsi}{create}   = delete $opt{create}   if ($opt{create}   && ref $opt{create}   && ref $opt{create}   eq 'ARRAY');
      $self->{gdsi}{particle} = delete $opt{particle} if ($opt{particle} && ref $opt{particle} && ref $opt{particle} eq 'ARRAY');
      $self->{GDSI_CALLED} = 1;
      $self;
}

sub create_image_file {
   my $self = shift;
   my $code = shift;
   my $md5  = shift; # junk
   my $i    = GD::SecurityImage->new($self->{gdsi}{'new'} ? %{$self->{gdsi}{'new'}} : (
                  # defaults
                  width      => $self->{_width} < 60 ? 60 : $self->{_width},
                  height     => $self->{_height},
                  gd_font    => 'giant',
                  lines      => 2,
                  send_ctobg => 1,
   ),             rndmax     => 1);
   $i->random($code);
   $i->create($self->{gdsi}{create} ? @{$self->{gdsi}{create}} : (normal => 'default', '#6C7186', '#917862'));
   $i->particle(@{ $self->{gdsi}{particle} }) if $self->{gdsi}{particle};
   my @data = $i->out(force => 'png');
   return $data[0];
}

sub database_file {
   my $self = shift;
   my $file = File::Spec->catfile($self->{_data_folder},'codes.txt');
   unless(-e $file) { # create database file if it doesn't already exist
      open  DATA, '>>'.$file or die "Can't create File: $file\n";
      close DATA;
   }
   return $file;
}

sub database_data {
   my $self = shift;
   my $db   = $self->database_file;
   open   DATA, '<'.$db  or die "Can't open $db for reading: $!\n";
   flock  DATA, LOCK_SH;
   my @data = <DATA>;
   close  DATA;
   return @data;
}

sub check_code {
   my $self   = shift;
   my $code   = shift;
   my $crypt  = shift;
   my $db     = $self->database_file;
     ($code   = lc $code) =~ tr/01/ol/;
   my $md5    = md5_hex($code); # remove 0-1
   my $now    = time;
   my $rvalue = 0;
   my $passed = 0;
   my $new    = ''; # saved entries
   my $found;
   foreach my $line ($self->database_data) {
      chomp $line;
      my ($data_time, $data_code) = split /::/, $line;
      my $png_file = File::Spec->catfile($self->{_output_folder}, $data_code . '.png');
      if ($data_code eq $crypt) { # the crypt was found in the database
         if (($now - $data_time) > $self->{_expire}) { 
            $rvalue = -1; # the crypt was found but has expired
         } else {
            $found = 1;
         }
         if ( ($md5 ne $crypt) && ($rvalue != -1) && $self->{_keep_failures}) { # solution was wrong, not expired, and we're keeping failures
            $new .= $line."\n";
         } else {
            unlink($png_file) or die "Can't remove [$png_file]: $!\n"; # remove the found crypt so it can't be used again
         }
      } elsif (($now - $data_time) > $self->{_expire}) {
         unlink($png_file) or die "Can't remove [$png_file]: $!\n"; # removed expired crypt
      } else {
         $new .= $line."\n"; # crypt not found or expired, keep it
      }
   }

   # update database
   open  DATA, '>'.$db  or die "Can't open $db for writing: $!\n";
   flock DATA, LOCK_EX;
   print DATA $new;
   close DATA;
   if ($md5 eq $crypt) { # solution was correct
      if ($found) {
         $rvalue = 1;  # solution was correct and was found in database - passed
      } elsif (!$rvalue) {
         $rvalue = -2; # solution was not found in database
      }
   } else {
      $rvalue = -3; # incorrect solution
   }
   return $rvalue;
}

sub generate_code {
   my $self  = shift;
   my $len   = shift;
   my $code  = '';
      $code .= chr( int(rand 4) == 0 ? (int(rand 7)+50) : (int(rand 25)+97)) for 1..$len;
   my $md5   = md5_hex($code);
   my $now   = time;
   my $new   = "";
   my $db    = $self->database_file;
   foreach my $line ($self->database_data) { # clean expired codes and images
      $line =~ s/\n//;
      my ($data_time,$data_code) = split(/::/,$line);
      if (($now - $data_time) > $self->{_expire} || $data_code eq $md5) {   # remove expired captcha, or a dup
         my $png_file = File::Spec->catfile($self->{_output_folder},$data_code . ".png");
         unlink($png_file) or die "Can't remove png file [$png_file]\n";
      } else {
         $new .= $line."\n";
      }
   }

   # first, test if we can open all files
   my $file = File::Spec->catfile($self->{_output_folder},$md5 . '.png');
   open    FILE, '>'.$file or die "Can't open $file for writing: $!\n";
   open    DATA, '>'.$db   or die "Can't open $db   for writing: $!\n";

   # save image data
   flock   FILE, LOCK_EX;
   binmode FILE;
   print   FILE $self->create_image_file($code, $md5);
   close   FILE;

   # save the code to database
   flock   DATA, LOCK_EX;
   print   DATA $new, $now,"::",$md5,"\n";
   close   DATA;
   return  wantarray ? ($md5, $code) : $md5;
}

sub AUTOLOAD { # junk methods
   my $self = shift;
  (my $name = $AUTOLOAD) =~ s[.*:][];
      if ($name =~ m[^(output_folder|images_folder|data_folder|debug)$]) { $self->{"_$name"} = $_[0] if $_[0];                return $self->{"_$name"}         } 
   elsif ($name =~ m[^(expire|width|height)$]                          ) { $self->{"_$name"} = $_[0] if $_[0] and $_[0] >= 0; return $self->{"_$name"}         } 
   elsif ($name eq 'keep_failures'                                     ) { $self->{_keep_failures} = $_[0] ? 1 : 0;           return $self->{_keep_failures}   }
   elsif ($name eq 'version'                                           ) {                                                    return $VERSION                  } 
   elsif ($name eq 'create_sound_file'                                 ) {                                                    return "there is no such thing!" }
   elsif ($name eq 'type'                                              ) {                                                    return 'image'                   }
   else  { die "No such method $name!" }
}

sub DESTROY {}

package Authen::Captcha; # enable emulation by name
use base qw[GD::SecurityImage::AC];

1;

__END__

=head1 NAME

GD::SecurityImage::AC - A drop-in replacement for Authen::Captcha.

=head1 SYNOPSIS

  use GD::SecurityImage::AC;

  # create a new object
  my $captcha = Authen::Captcha->new();

  # set the data_folder. contains flatfile db to maintain state
  $captcha->data_folder('/some/folder');

  # set directory to hold publicly accessable images
  $captcha->output_folder('/some/http/folder');

  # Alternitively, any of the methods to set variables may also be
  # used directly in the constructor

  my $captcha = Authen::Captcha->new(
    data_folder => '/some/folder',
    output_folder => '/some/http/folder',
    );

  # create a captcha. Image filename is "$md5sum.png"
  my $md5sum = $captcha->generate_code($number_of_characters);

  # check for a valid submitted captcha
  #   $code is the submitted letter combination guess from the user
  #   $md5sum is the submitted md5sum from the user (that we gave them)
  my $results = $captcha->check_code($code,$md5sum);
  # $results will be one of:
  #          1 : Passed
  #          0 : Code not checked (file error)
  #         -1 : Failed: code expired
  #         -2 : Failed: invalid code (not in database)
  #         -3 : Failed: invalid code (code does not match crypt)
  ##############

=head1 DESCRIPTION

This module is a drop-in GD::SecurityImage replacement for Authen::Captcha. 
Module is mostly compatible with Authen::Captcha. You can just replace

   use Authen::Captcha;

line in your programs with

   use GD::SecurityImage::AC;

to enable GD::SecurityImage interface. Regular GD::SecurityImage interface 
is supported with an extra method: C<gdsi>.

This module uses: C<GD::SecurityImage>, C<Digest::MD5>, C<File::Spec> and 
C<Fcntl> modules.

=head1 METHODS

See L<Authen::Captcha> for the methods and usage.

=head2 gdsi

This method is used to set L<GD::SecurityImage> parameters. Three
methods are supported: C<new>, C<create> and C<particle>. Parameter
types and names are identical to GD::SecurityImage parameters:

   $captcha->gdsi(new      => {name => value},
                  create   => [param1, param2, ...],
                  particle => [param1, param2]);

C<new> is a hashref while the other two are arrayrefs. 
See L<GD::SecurityImage> for information about these parameters.

C<gdsi> method must be called just after creating the object:

   my $captcha = Authen::Captcha->new;
   $captcha->gdsi(
      new => {
               width    => 350,
               height   => 100,
               lines    => 10,
               font     => "/absolute/path/to/your.ttf",
               scramble => 1,
               ptsize   => 24,
      },
      create   => [ttf => 'box', '#80C0F0', '#0F644B'],
      particle => [115, 250],
   );

If you don't use this method, the captcha image will be generated with
default options.

C<gdsi> returns the object itself. So, you can create your object like this:

   my $captcha = Authen::Captcha->new( ... )->gdsi( ... );

=head1 CAVEATS

=over 4

=item *

width and height parameters are *not* character's width and height,
but they define the image dimensions. 

=item *

No outside images. Captchas are generated with the GD::SecurityImage
interface, not with third party "letter" graphics (but you can use true 
type fonts, see C<gdsi> method). As a side effect, captcha size is not 
(actually "can not be") determined automatically. so, you have to specify 
a width and height value at the beginning.

=item *

Setting C<images_folder> has no effect.

=item *

No background images. Backgrounds are drawn with GD::SecurityImage styles.

=item *

You have to specify a TTF font, if you want to use another font (other than GD
built-in C<GD::Font-E<gt>Giant>).

=item *

Setting C<debug> has no effect. You can still set C<debug>, but it is not used 
inside this module.

=back

=head1 SEE ALSO

L<GD::SecurityImage>, L<Authen::Captcha>.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2005 Burak Gürsoy. All rights reserved.

Some portions of this module adapted from L<Authen::Captcha>. 
L<Authen::Captcha> Copyright 2003 by First Productions, Inc. & Seth Jackson.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
