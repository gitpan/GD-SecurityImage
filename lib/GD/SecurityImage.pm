package GD::SecurityImage;
use strict;
use vars qw[@ISA $VERSION];
use GD::SecurityImage::Styles;

@ISA     = qw(GD::SecurityImage::Styles);
$VERSION = "1.32";

sub import {
   # load the drawing interface
   my $class = shift;
   my %opt   = scalar(@_) % 2 ? () : (@_);
   if (exists $opt{use_magick} and $opt{use_magick}) {
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
      _RANDOM_NUMBER_ => '', # random security code
      _RNDMAX_        => 6,  # maximum number of characters in a random string.
      _COLOR_         => {}, # text and line colors
      _CREATECALLED_  => 0,  # create() called? (check for particle())
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
               frame      => defined($opt{frame}) ? $opt{frame} : 1,
   );
   $self->{$_} = $options{$_} foreach keys %options;
   $self->init;
   return $self;
}

sub gdf {
   my $self = shift;
   return if $self->{IS_MAGICK};
   return $self->gdfx(@_);
}

sub random_str { shift->{_RANDOM_NUMBER_} }

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
      $col1   = [ 0, 0, 0] if(not $col1 || not ref $col1 || ref $col1 ne 'ARRAY' || $#{$col1} != 2);
      $col2   = [ 0, 0, 0] if(not $col2 || not ref $col2 || ref $col2 ne 'ARRAY' || $#{$col2} != 2);
   my %color  = (
        text  => $self->{IS_MAGICK} ? $col1 : $self->{image}->colorAllocate(@{$col1}),
        lines => $self->{IS_MAGICK} ? $col2 : $self->{image}->colorAllocate(@{$col2}),
   );

   $self->{send_ctobg} = 0 if $style eq 'box'; # disable for that style

   $self->{_COLOR_} = \%color; # set the color hash
   $self->{gd_font} = GD::Font->Giant if $method eq 'normal' and not $self->{gd_font};

   $style = $self->can('style_'.$style) ? 'style_'.$style : 'style_default';
   $self->$style() unless $self->{send_ctobg};
   $self->insert_text($method);
   $self->$style() if     $self->{send_ctobg};
   $self->rectangle(0,0,$self->{width}-1,$self->{height}-1, $self->{_COLOR_}{lines})
      if $self->{frame}; # put a frame around the image
   $self->{_CREATECALLED_}++;
   return $self if defined wantarray;
}

sub particle {
   # Create random dots. They'll cover all over the surface
   my $self = shift;
   die "particle() must be called 'after' create()!" unless $self->{_CREATECALLED_};
   my $big  = $self->{height} > $self->{width} ? $self->{height} : $self->{width};
   my $f    = shift || $big * 20; # particle density
   my $dots = shift || 1; # number of multiple dots
   my $int  = int $big / 20;
   my @random;
   for (my $x = $int; $x <= $big; $x += $int) {
      push @random, $x;
   }
   my($x, $y, $z);
   for (1..$f) {
      $x = int rand $self->{width};
      $y = int rand $self->{height};
      foreach $z (1..$dots) {
         $self->setPixel($x + $z                            , $y + $z                            , $self->{_COLOR_}{text});
         $self->setPixel($x + $z + $random[int rand @random], $y + $z + $random[int rand @random], $self->{_COLOR_}{text});
      }
   }
   return $self if defined wantarray;
}

sub raw {shift->{image}} # raw image object

#--------------------[ PRIVATE ]--------------------#

sub r2h {
   # Convert RGB to Hex
   my $self = shift;
   @_ == 3 || return;
   my $color  = '#';
      $color .= sprintf("%02x", $_) foreach @_;
      $color;
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
      $image->particle;
   my($image_data, $mime_type, $random_number) = $image->out;

or you can just say (all public methods can be chained)

   my($image, $type, $rnd) = GD::SecurityImage->new->random->create->particle->out;

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

The background color of the image. Passed as an arrayref with three 
elements (red, green, blue).

=item send_ctobg

If has a true value, the random security code will be displayed in the 
background and the lines will pass over it. 
(send_ctobg = send code to background)

=item frame

If has a true value, a frame will be added around the image. This
option is enabled by default.

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

=back

=head2 random

Creates the random security string or B<sets the random string> to 
the value you have passed. If you pass your own random string, be aware 
that it must be at least six (defined by an object table) characters 
long.

=head2 random_str

Returns the random string. Must be called after C<random()>.

=head2 create

This method creates the actual image. It takes four arguments, but
none are mandatory.

   $image->create($method, $style, $text_color, $line_color);

C<$method> can be B<C<normal>> or B<C<ttf>>.

C<$style> can be one of the following:

=over 4

=item B<default>

The default style. Draws horizontal, vertical and angular lines.

=item B<rect>

Draws horizontal and vertical lines

=item B<box>

Draws two filled rectangles.

The C<lines> option passed to L<new|/new>, controls the size of the inner rectangle
for this style. If you increase the C<lines>, you'll get a smaller internal 
rectangle. Using smaller values like C<5> can be better.

=item B<circle>

Draws circles.

=item B<ellipse>

Draws ellipses.

=item B<ec>

This is the combination of ellipse and circle styles. Draws both ellipses
and circles.

=back

The last two arguments (C<$text_color> and C<$line_color>) are the 
colors used in the image (text and line color -- respectively) and 
they are passed as a 3-element (red, green and blue) arrayref.

   $image->create($method, $style, [0,0,0], [200,200,200]);

=head2 particle

Must be called after L<create|/create>.

Adds random dots to the image. They'll cover all over the surface. 
Accepts two parameters; the density (number) of the particles and 
the maximum number of dots around the main dot.

   $image->particle($density, $maxdots);

Default value of C<$density> is dependent on your image' s width or 
height value. The greater value of width and height is taken and 
multiplied by twenty. So; if your width is C<200> and height is C<70>, 
C<$density> is C<200 * 20 = 4000> (unless you pass your own value).
The default value of C<$density> can be too much for smaller images.

C<$maxdots> defines the maximum number of dots near the default dot. 
Default value is C<1>. If you set it to C<4>, The selected pixel and 3 
other pixels near it will be used and colored.

The color of the particles are the same as the color of your text 
(defined in L<create|/create>).

=head2 out

This method finally returns the created image, the mime type of the 
image and the random number generated. Older versions of GD only supports
C<gif> types, while new versions support C<jpeg> and C<png>.

The returned mime type is either C<gif> or C<jpeg> for C<GD> and 
C<gif> for C<Image::Magick>.

C<out> method accepts arguments:

   @data = $image->out(%args);

currently, you can only set output format with the C<force> key:

   @data = $image->out(force => 'png');

If C<png> is supported by the interface (via C<GD> or C<Image::Magick>); 
you'll get a png image, if the interface does not support this format, 
C<out()> method will use it's default configuration.

Currently, you can not define compression values for the formats that 
support it (eg: jpeg, png), but you can use L<raw|/raw> method instead 
of C<out> (for a direct communication with the graphic library -- but 
probably you do not want to do that, future versions may implement 
this feature).

=head2 raw

Depending on your usage of the module; returns the raw C<GD::Image> 
object:

   my $i = $image->raw;
   print $i->png;

or the raw C<Image::Magick> object:

   my $i = $image->raw;
   $i->Write("gif:-");

Can be usefull, if you want to modify the graphic yourself, or want to
use another output format like C<png>.

=head1 EXAMPLES

See the tests in the distribution.

=head1 ERROR HANDLING

Currently, the module does not check the return values of C<GD>'s and
C<Image::Magick>' s methods. So, if an error occurs, you may just get 
an empty image instead of die()ing.

=head1 SEE ALSO

L<GD>, L<Image::Magick>, L<ImagePwd>.

=head1 CAVEAT EMPTOR

Using the default library C<GD> is a better choice. Since it is faster 
and does not use that much memory, while C<Image::Magick> is slower and 
uses more memory.

The internal random code generator is used B<only> for demonstration 
purposes for this module. It may not be I<effective>. You must supply 
your own random code and use this module to display it.

=head1 BUGS

=over 4

=item Image::Magick bug

There is a bug in PerlMagick' s C<QueryFontMetrics()> method. ImageMagick
versions smaller than 6.0.4 is affected. Below text is from the ImageMagick 
6.0.4 Changelog: L<http://www.imagemagick.org/www/Changelog.html>.

"2004-05-06 PerlMagick's C<QueryFontMetrics()> incorrectly reports `unrecognized 
attribute'` for the `font' attribute."

Please upgrade to ImageMagick 6.0.4 or any newer version, if your ImageMagick 
version is smaller than 6.0.4 and you want to use Image::Magick as the backend
for GD::SecurityImage.

=back

Contact the author if you find any bugs. You can also send requests.

=head1 AUTHOR

Burak G�rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 Burak G�rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
