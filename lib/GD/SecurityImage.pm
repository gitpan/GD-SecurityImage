package GD::SecurityImage;
use strict;
use vars qw[@ISA $VERSION];
use GD::SecurityImage::Styles;

@ISA     = qw(GD::SecurityImage::Styles);
$VERSION = "1.2";

sub import {
   # load the drawing interface
   my $class = shift;
   my %opt   = scalar(@_) % 2 ? () : (@_);
   if ($opt{use_magick}) {
      require GD::SecurityImage::Magick;
      push @ISA, qw(GD::SecurityImage::Magick);
   } else {
      require GD::SecurityImage::GD;
      push @ISA, qw(GD::SecurityImage::GD);
   }
}

sub new {
   my $class = shift;
   my %opt   = scalar @_ % 2 ? () : (@_);
   my $self  = {
      IS_MAGICK       => defined($Image::Magick::VERSION) ? 1 : 0,
      MAGICK          => {}, # Image::Magick configuration options
      _RANDOM_NUMBER_ => '',
      _RNDMAX_        => 6, # maximum number of characters in a random string.
   };
   bless $self, $class;
   my %options = (
               width      => $opt{width}               || 80,
               height     => $opt{height}              || 30,
               ptsize     => $opt{ptsize}              || 20,
               lines      => $opt{lines}               || 10,
               rndmax     => $opt{rndmax}              || $self->{_RNDMAX_},
               rnd_data   => $opt{rnd_data}            || [0..9],
               font       => $opt{font}                || '',
               gd_font    => $self->gdf($opt{gd_font}) || '',
               bgcolor    => $opt{bgcolor}             || [255, 255, 255],
               send_ctobg => $opt{send_ctobg}          || 0,
   );
   $self->{$_}    = $options{$_} foreach keys %options;
   $self->init;
   return $self;
}

sub gdf {
   my $self = shift;
   return if $self->{IS_MAGICK};
   return $self->gdfx(@_);
}

sub random_str {
   my $self = shift;
   return $self->{_RANDOM_NUMBER_};
}

sub random {
   my $self = shift;
   my $user = shift;
   if($user and length($user) >= $self->{_RNDMAX_}) {
      $self->{_RANDOM_NUMBER_} = $user;
   } else {
      my @keys = @{ $self->{rnd_data} };
      my $lk   = scalar @keys;
      my $random;
         $random .= $keys[int rand $lk] for 1..$self->{rndmax};
         $self->{_RANDOM_NUMBER_} = $random;
   }
   return $self if defined wantarray;
}

sub create {
   my $self   = shift;
   my $method = shift || 'normal';  # ttf or normal
   my $style  = shift || 'default'; # default or rect or box
   my $col1   = shift; # text color
   my $col2   = shift; # line/box color
      $col1 = [ 0, 0, 0] if(not $col1 || not ref $col1 || ref $col1 ne 'ARRAY' || $#{$col1} != 2);
      $col2 = [ 0, 0, 0] if(not $col2 || not ref $col2 || ref $col2 ne 'ARRAY' || $#{$col2} != 2);
   my %color  = (
        text  => $self->{IS_MAGICK} ? $col1 : $self->{image}->colorAllocate(@{$col1}),
        lines => $self->{IS_MAGICK} ? $col2 : $self->{image}->colorAllocate(@{$col2}),
   );

   if ($method eq 'normal' and not $self->{gd_font}) {
      $self->{gd_font} = GD::Font->Giant;
   }

   $style = $self->can('style_'.$style) ? 'style_'.$style : 'style_default';
   $self->$style(%color) unless $self->{send_ctobg};
   $self->insert_text($method, \%color);
   $self->$style(%color) if     $self->{send_ctobg};
   return $self if defined wantarray;
}

# return $image_data, $image_mime_type, $random_number
sub out {
   my $self = shift;
   if ($self->{IS_MAGICK}) {
      $self->{image}->Set(magick => 'gif');
      return $self->{image}->ImageToBlob, 'gif', $self->{_RANDOM_NUMBER_};
   } else {
      my $type = $self->{image}->can('gif') ? 'gif' : 'jpeg'; # check for older GDs
      return $self->{image}->$type(), $type, $self->{_RANDOM_NUMBER_};
   }
}

sub raw {shift->{image}} # raw image object

1;

__END__

=head1 NAME

GD::SecurityImage - Create a security image with a random string on it.

=head1 SYNOPSIS

   use GD::SecurityImage;

   # Create a normal image
   my $image = GD::SecurityImage->new(width   => 80,
                                      height  => 30,
                                      lines   => 10,
                                      gd_font => 'giant');
      $image->random($your_random_str);
      $image->create(normal => 'rect');
   my($image_data, $mime_type, $random_number) = $image->out;

   # use external ttf font
   my $image = GD::SecurityImage->new(width  => 100,
                                      height => 40,
                                      lines  => 10,
                                      font   => "/absolute/path/to/your.ttf");
      $image->random($your_random_str);
      $image->create(ttf => 'default');
   my($image_data, $mime_type, $random_number) = $image->out;

or you can just say

   my($image, $type, $rnd) = GD::SecurityImage->new->random->create->out;

to create a security image with the default settings. But that may not be 
usefull.

If you C<require> the module, you B<must> import it also:

   require GD::SecurityImage;
   import GD::SecurityImage;

or:

   require GD::SecurityImage;
   GD::SecurityImage->import;

if you don't like indirect object syntax.

If you dont C<import>, the required modules will not be loaded and probably, 
you'll C<die()>.

Beginning with v1.2, the module supports C<Image::Magick>, but the default
interface uses C<GD> module. To enable C<Image::Magick> support, you must 
call the module with the C<use_magick> option:

   use GD::SecurityImage use_magick => 1;

If you C<require> the module, you B<must> import it also:

   require GD::SecurityImage;
   import GD::SecurityImage use_magick => 1;

or:

   require GD::SecurityImage;
   GD::SecurityImage->import(use_magick => 1);

if you don't like indirect object syntax.

If you dont C<import>, the required modules will not be loaded and probably, 
you'll C<die()>.

The module does not I<export> anything actually. But C<import> loads the 
necessary sub modules.

=head1 DESCRIPTION

The (so called) I<"Security Images"> are so popular. Most internet 
software use these in their registration screens to block robot programs
(which may register tons of  fake member accounts). This module gives
you a basic interface to create such an image. The final output is
the actual graphic data, the mime type of the graphic and the created
random string.

The module also has some I<"styles"> that are used to create the background 
of the image.

=head1 METHODS

=head2 new

C<new()> method takes several arguments. These arguments are listed below.

=over 4

=item width

The width of the image (in pixels).

=item height

The height of the image (in pixels).

=item ptsize

Numerical value. The point size of the ttf character. 
Not necessarry unless you want to use ttf fonts in the image.

=item lines

The number of lines that you' ll see in the background of the image.
The alignment of lines can be vertical, horizontal or angled or 
all of them. If you increase this parameter' s value, the image will
be more cryptic.

=item rndmax

The length of the random string. Default value is C<6>.

Not necessary and will not be used if you pass your own random
string.

=item rnd_data

Default character set used to create the random string is C<0..9>.
But, if you want to use letters also, you can set this paramater.
This paramater takes an array reference as the value.

Not necessary and will not be used if you pass your own random
string.

=item font

The absolute path to your TrueType (.ttf) font file. Be aware that 
relative font paths are not recognized due to problems in the C<libgd>
library.

If you are sure that you've set this parameter to a correct value and
you get warnings or you get an empty image, be sure that your path
does not include spaces in it. It looks like libgd also have problems
with this kind of paths (eg: '/Documents and Settings/user' under Windows).

Set this parameter if you want to use ttf in your image.

=item gd_font

If you want to use the default interface, set this paramater. The 
recognized values are C<Small>, C<Large>, C<MediumBold>, C<Tiny>, C<Giant>.
The names are case-insensitive; you can pass lower-cased parameters.

=item bgcolor

The background color of the image.

=item send_ctobg

If has a true value, the random security code will be showed on the 
background and the lines will pass over it. 
(send_ctobg = send code to background)

Do not use with the C<box> style.

=back

=head2 random

Creates the random security string or sets the random string to 
the value you have passed. If you pass your own random string, be aware 
that it must be at least six (defined by a class variable) characters 
long.

=head2 random_str

Returns the random string. Must be called after C<random()>.

=head2 create

This method creates the actual image. It takes four arguments, but
none are mandatory.

   $image->create($method, $style, $text_color, $line_color);

C<$method> can be C<normal> or C<ttf>.

C<$style> can be one of the following:

=over 4

=item default

The default style. Draws horizontal, vertical and angular lines.

=item rect

Draws horizontal and vertical lines

=item box

Draws two filled rectangles.

The C<lines> option passed to L<new|/new>, controls the size of the inner rectangle
for this style. If you increase the C<lines>, you'll get a smaller internal 
rectangle. Using smaller values like C<5> can be better.

=item circle

Draws circles.

=item ellipse

Drawas ellipses.

=item ec

This is the combination of ellipse and circle styles. Draws both ellipses
and circles.

=back

The last two arguments are the colors used in the image 
(text and line color -- respectively) and they are passed 
as a 3-element (red, green and blue) arrayref.

   $image->create($method, $style, [0,0,0], [200,200,200]);

=head2 out

This method finally returns the created image, the mime type of the 
image and the random number generated. Older versions of GD only supports
C<gif> types, while new versions support C<jpeg> and C<png>.

The returned mime type is either C<gif> or C<jpeg>.

=head2 raw

Returns the raw C<GD::Image> object:

   my $i = $image->raw;
   print $i->png;

or the raw C<Image::Magick> object:

   my $i = $image->raw;
   $i->Write("gif:-");

Can be usefull, if you want to modify the graphic yourself, or want to
use another output format like C<png>.

=head1 SEE ALSO

L<GD>, L<ImagePwd>.

=head1 EXAMPLES

=head2 TTF example

   #!/usr/bin/perl -w
   use strict;
   use CGI;
   use GD::SecurityImage;

   my $cgi = CGI->new;

   my $ttf = "/absolute/path/to/your.ttf";

   my $image = GD::SecurityImage->new(
                  width    => 90,
                  height   => 35,
                  ptsize   => 15,
                  lines    => 10,
                  rndmax   => 6,
                  rnd_data => [0..9, 'A'..'Z'],
                  font     => $ttf,
                  bgcolor  => [115, 255, 255],
   );

   $image->random;
   $image->create(ttf => 'rect', [10,10,10], [210,210,50]);

   my($image_data, $mime_type, $random_string) = $image->out;

   print $cgi->header(-type => "image/$mime_type");
   print $image_data;

=head2 Normal example

   #!/usr/bin/perl -w
   use strict;
   use CGI;
   use GD::SecurityImage;

   my $cgi = CGI->new;

   my $image = GD::SecurityImage->new(
                  width    => 90,
                  height   => 35,
                  ptsize   => 15,
                  lines    => 10,
                  gd_font  => 'giant',
                  bgcolor  => [115, 255, 255],
   );

   $image->random('12GH88');
   $image->create(normal => 'rect', [10,10,10], [210,210,50]);

   my($image_data, $mime_type, $random_string) = $image->out;

   print $cgi->header(-type => "image/$mime_type");
   print $image_data;

=head2 Image::Magick example

   #!/usr/bin/perl -w
   use strict;
   use CGI;
   use GD::SecurityImage use_magick => 1;

   my $cgi = CGI->new;

   my $ttf = "/absolute/path/to/your.ttf";

   my $image = GD::SecurityImage->new(
                  width    => 90,
                  height   => 35,
                  ptsize   => 15,
                  lines    => 10,
                  font     => $ttf,
                  bgcolor  => [115, 255, 255],
   );

   $image->random('BLAH');
   $image->create(ttf => 'ec', [10,10,10], [210,210,50]);

   my($image_data, $mime_type, $random_string) = $image->out;

   print $cgi->header(-type => "image/$mime_type");
   print $image_data;

=head2 require example

   #!/usr/bin/perl -w
   use strict;
   use CGI;
   require GD::SecurityImage;
   import  GD::SecurityImage use_magick => 1;

   my $cgi = CGI->new;

   my $ttf = "/absolute/path/to/your.ttf";

   my $image = GD::SecurityImage->new(
                  width    => 90,
                  height   => 35,
                  ptsize   => 15,
                  lines    => 10,
                  font     => $ttf,
                  bgcolor  => [115, 255, 255],
   );

   $image->random('FOOBAR');
   $image->create(ttf => 'ec', [10,10,10], [210,210,50]);

   my($image_data, $mime_type, $random_string) = $image->out;

   print $cgi->header(-type => "image/$mime_type");
   print $image_data;

=head1 ERROR HANDLING

Currently, the module does not check the return values of C<GD>'s and
C<Image::Magick>' s methods. So, if an error occurs, you may just get 
an empty image instead of die()ing.

=head1 BUGS

Contact the author if you find any. You can also send requests.

=head1 AUTHOR

Burak G�rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 Burak G�rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
