package GD::SecurityImage;
use strict;
use vars qw[$VERSION];
use GD;

# See the create() method for these constants
use constant LOW_LEFT_X  => 0;
use constant LOW_LEFT_Y  => 1;
use constant LOW_RIGHT_X => 2;
use constant UP_LEFT_Y   => 7;

$VERSION = "1.0";

sub new {
   my $class = shift;
   my %opt   = scalar @_ % 2 ? () : (@_);
   my $self  = {};
   bless $self, $class;
   my %options = (
               width    => $opt{width}    || 80,
               height   => $opt{height}   || 30,
               ptsize   => $opt{ptsize}   || 20,
               lines    => $opt{lines}    || 10,
               rndmax   => $opt{rndmax}   || 6,
               rnd_data => $opt{rnd_data} || [0..9],
               font     => $opt{font}     || '',
               gd_font  => $self->gdf($opt{gd_font}) || GD::Font->Giant,
               bgcolor  => $opt{bgcolor}  || [255, 255, 255],
   );
   $self->{$_}    = $options{$_} foreach keys %options;
   $self->{image} = GD::Image->new($self->{width}, $self->{height});
   $self->{image}->colorAllocate(@{ $self->{bgcolor} }); # set background color
   return $self;
}

sub gdf {
   my $self = shift;
   my $font = shift || return;
      $font = lc $font;
   # GD' s standard fonts
   my %f = map { lc $_ => $_ } qw[ Small Large MediumBold Tiny Giant ];
   if (exists $f{$font}) {
      $font = $f{$font};
      return GD::Font->$font();
   }
   return;
}

sub random_str {
   my $self = shift;
   return $self->{_RANDOM_NUMBER_};
}

sub random {
   my $self = shift;
   my $user = shift;
   if($user and length($user) >= 6) {
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
   my %color  = (
        text  => $self->{image}->colorAllocate($col1 ? @{$col1} : (  0,   0,   0)),
        lines => $self->{image}->colorAllocate($col2 ? @{$col2} : (200, 200, 200)),
   );

   $style = $self->can('style_'.$style) ? 'style_'.$style : 'style_default';
   $self->$style(%color);

   my $key = $self->{_RANDOM_NUMBER_}; # random string

   if ($method eq 'ttf') {
      # don' t draw. we just need info...
      my @box = GD::Image->stringFT($color{text},$self->{font},$self->{ptsize},0,0,0,$key)
                # or die "I can not get the boundary list: $@"
                # I think that libgd also has some problems 
                # with paths that have spaces in it.
                ; 
      my $x = ($self->{width}  - ($box[LOW_RIGHT_X] - $box[LOW_LEFT_X])) / 2;
      my $y = ($self->{height} - ($box[UP_LEFT_Y]   - $box[LOW_LEFT_Y])) / 2;
      $self->{image}->stringFT($color{text}, $self->{font}, $self->{ptsize}, 0, $x, $y, $key);
   } else {
      my $sw = $self->{gd_font}->width * length($key);
      my $sh = $self->{gd_font}->height;
      my $x  = ($self->{width}  - $sw) / 2;
      my $y  = ($self->{height} - $sh) / 2;
      $self->{image}->string($self->{gd_font}, $x, $y, $key, $color{text});
   }

   return $self if defined wantarray;
}

# return $image_data, $image_mime_type, $random_number
sub out {
   my $self = shift;
   my $type = $self->{image}->can('gif') ? 'gif' : 'jpeg'; # check for older GDs
   return $self->{image}->$type(), $type, $self->{_RANDOM_NUMBER_};
}

sub style_default {
   my $self  = shift;
   my $fx    = $self->{width}  / $self->{lines};
   my $fy    = $self->{height} / $self->{lines};
   my %color = @_;

   $self->{image}->rectangle(0,0,$self->{width}-1,$self->{height}-1, $color{lines}); # put a frame around the image

   for my $i (0..$self->{lines}) {
      $self->{image}->line($i * $fx, 0,  $i * $fx     , $self->{height}, $color{lines}); # | line
      $self->{image}->line($i * $fx, 0, ($i * $fx)+$fx, $self->{height}, $color{lines}); # \ line
   }

   for my $i (1..$self->{lines}) {
      $self->{image}->line(0, $i * $fy, $self->{width}, $i * $fy, $color{lines}); # - line
   }
}

sub style_rect {
   my $self  = shift;
   my $fx    = $self->{width}  / $self->{lines};
   my $fy    = $self->{height} / $self->{lines};
   my %color = @_;

   $self->{image}->rectangle(0,0,$self->{width}-1,$self->{height}-1, $color{lines}); # put a frame around the image

   for my $i (0..$self->{lines}) {
      $self->{image}->line($i * $fx, 0,  $i * $fx     , $self->{height}, $color{lines}); # | line
   }

   for my $i (1..$self->{lines}) {
      $self->{image}->line(0, $i * $fy, $self->{width}, $i * $fy, $color{lines}); # - line
   }
}

sub style_box {
   my $self  = shift;
   my %color = @_;
   my $w = $self->{lines};
   $self->{image}->filledRectangle(0 , 0 , $self->{width}         , $self->{height}         , $color{text});
   $self->{image}->filledRectangle($w, $w, $self->{width} - $w - 1, $self->{height} - $w - 1, $color{lines} );
}

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

=back

=head2 random

Creates the random security string or sets the random string to 
the value you have passed. If you pass your own random string, be aware 
that it must be at least six characters long.

=item random_str

Returns the random string. Must be called after C<random()>.

=head2 create

This method creates the actual image. It takes four arguments, but
none are mandatory.

   $image->create($method, $style, $text_color, $line_color);

C<$method> can be C<normal> or C<ttf>.
C<$style> can be C<default> or C<rect> or C<box>.
The last two arguments are the colors used in the image and they are 
passed as a 3-element (red, green and blue) arrayref.

   $image->create($method, $style, [0,0,0], [200,200,200]);

=head2 out

This method finally returns the created image, the mime type of the 
image and the random number generated. Older versions of GD only supports
C<gif> types, while new versions support C<jpeg> and C<png>.

The returned mime type is either C<gif> or C<jpeg>.

=head1 SEE ALSO

L<GD>.

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
                  rndmax   => 6,
                  rnd_data => [0..9, 'A'..'Z'],
                  gd_font  => 'giant',
                  bgcolor  => [115, 255, 255],
   );

   $image->random('12GH88');
   $image->create(normal => 'rect', [10,10,10], [210,210,50]);

   my($image_data, $mime_type, $random_string) = $image->out;

   print $cgi->header(-type => "image/$mime_type");
   print $image_data;

=head1 ERROR HANDLING

Currently, the module does not check the return values of GD's methods.
So, if an error occurs, you can just get an empty image instead of 
die()ing.

=head1 BUGS

Contact the author if you find any.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
