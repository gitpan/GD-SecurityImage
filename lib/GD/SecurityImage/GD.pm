package GD::SecurityImage::GD;
# GD method wrapper class
use strict;
use vars qw[$VERSION];

use constant LOW_LEFT_X  => 0;
use constant LOW_LEFT_Y  => 1;
use constant LOW_RIGHT_X => 2;
use constant LOW_RIGHT_Y => 3;
use constant UP_RIGHT_X  => 4;
use constant UP_RIGHT_Y  => 5;
use constant UP_LEFT_X   => 6;
use constant UP_LEFT_Y   => 7;

use constant ANGLE       => -2;
use constant CHAR        => -1;

use constant MAX         => -1;

use GD;

$VERSION = "1.3";

sub init {
   # Create the image object
   my $self = shift;
      $self->{image} = GD::Image->new($self->{width}, $self->{height});
      $self->{image}->colorAllocate(@{ $self->{bgcolor} }); # set background color
}

sub out {
   # return $image_data, $image_mime_type, $random_number
   my $self = shift;
   my %opt  = scalar @_ % 2 ? () : (@_);
   my $type;
   if($opt{force} and $self->{image}->can($opt{force})){
      $type = $opt{force};
   } else {
      $type = $self->{image}->can('gif') ? 'gif' : 'jpeg'; # check for older GDs and newer GDs as the new versions include gif() again!
   }
   return $self->{image}->$type(), $type, $self->{_RANDOM_NUMBER_};
}

sub gdbox_empty {shift->{GDBOX_EMPTY}}

sub gdfx {
   # Sets the font for simple GD usage. 
   # Unfortunately, Image::Magick does not have a similar interface.
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

sub insert_text {
   # Draw text using GD
   my $self   = shift;
   my $method = shift;
   my $key    = $self->{_RANDOM_NUMBER_}; # random string
   if ($method eq 'ttf') {
      require Math::Trig;
      my $methTTF = $GD::VERSION >= 1.31 ? 'stringFT' : 'stringTTF';
      # don' t draw. we just need info...
      my $info = sub {
                      my $txt = shift;
                      my $ang = shift || 0;
                         $ang = Math::Trig::deg2rad($ang) if $ang;
                      my @box = GD::Image->$methTTF($self->{_COLOR_}{text},$self->{font},$self->{ptsize},$ang,0,0,$txt);
                      unless (@box) { # use fake values instead of die-ing
                         $self->{GDBOX_EMPTY} = 1; # set this for error checking.
                         $#box    = 7;
                         # lets initialize to silence the warnings
                         $box[$_] = 1 for 0..7;
                      }
                      return @box;
      };
      if ($self->{scramble}) {
         my $space = [$info->(' '), 0, ' ']; # get " " parameters
         my @char;
         foreach (split //, $key) { # get char parameters
            push @char, [$info->($_), $self->random_angle, $_], $space, $space, $space;
         }
         my $total  = 0;
            $total += $_->[LOW_RIGHT_X] - $_->[LOW_LEFT_X] foreach @char;
         my @config = ($self->{_COLOR_}{text}, $self->{font}, $self->{ptsize});
         my($diffx,$diffy,$x,$y,@xy);
         foreach my $box (@char) {
            @xy     = $self->_charw($box->[ANGLE],@$box);
            $diffx  = $xy[0];
            $diffy  = $box->[UP_LEFT_Y] - $box->[LOW_LEFT_Y];
            $total -= $diffx * 2;
            $x      = ($self->{width}  - $total - $diffx) / 2;
            $y      = ($self->{height} - $diffy) / 2;
            $self->{image}->$methTTF(@config, Math::Trig::deg2rad($box->[ANGLE]), $x, $y, $box->[CHAR]);
         }
      } else {
         my @box = $info->($key);
         my $x   = ($self->{width}  - ($box[LOW_RIGHT_X] - $box[LOW_LEFT_X])) / 2;
         my $y   = ($self->{height} - ($box[UP_LEFT_Y]   - $box[LOW_LEFT_Y])) / 2;
         $self->{image}->$methTTF($self->{_COLOR_}{text}, $self->{font}, $self->{ptsize}, 0, $x, $y, $key);
      }
   } else {
      if ($self->{scramble}) {
         # without ttf, we can only have 0 and 90 degrees.
         my @char;
         my @styles = qw(string stringUp);
         my $style  = $styles[int rand @styles];
         foreach (split //, $key) { # get char parameters
            push @char, [$_, $style], [' ','string'];
            $style = $style eq 'string' ? 'stringUp' : 'string';
         }
         my $sw = $self->{gd_font}->width;
         my $sh = $self->{gd_font}->height;
         my($x, $y, $m);
         my $total = $sw * @char;
         foreach my $c (@char) {
            $m = $c->[1];
            $x = ($self->{width}  - $total) / 2;
            $y = $self->{height}/2 + ($m eq 'string' ? -$sh : $sh/2) / 2;
            $total -= $sw * 2;
            $self->{image}->$m($self->{gd_font}, $x, $y, $c->[0], $self->{_COLOR_}{text});
         }
      } else {
         my $sw = $self->{gd_font}->width * length($key);
         my $sh = $self->{gd_font}->height;
         my $x  = ($self->{width}  - $sw) / 2;
         my $y  = ($self->{height} - $sh) / 2;
         $self->{image}->string($self->{gd_font}, $x, $y, $key, $self->{_COLOR_}{text});
      }
   }
}

sub _charw {
   # this is buggy :p and I'm not sure if this is really necessary...
   my $self  = shift;
   my $angle = shift;
   my @box   = @_;
      $angle = 360 + $angle if $angle < 0;
   my(@fx, @fy);
   #   A.----.D
   #    .    .
   #   B.----.C
   my $Ax = $box[ UP_LEFT_X ];
   my $Bx = $box[LOW_LEFT_X ];
   my $Cx = $box[LOW_RIGHT_X];
   my $Dx = $box[ UP_RIGHT_X];
   my $Ay = $box[UP_LEFT_Y  ];
   my $By = $box[LOW_LEFT_Y ];
   my $Cy = $box[LOW_RIGHT_Y];
   my $Dy = $box[UP_RIGHT_Y ];

      if ($angle ==   0                 ) { @fx = ($Cx - $Bx, $Dx - $Ax); @fy = ($Ay - $By, $Dy - $Cy) }
   elsif ($angle >    0 and $angle <  90) { @fx = ($Cx - $Ax           ); @fy = ($Dy - $By           ) } 
   elsif ($angle ==  90                 ) { @fx = ($Bx - $Ax, $Cx - $Dx); @fy = ($Dy - $Ay, $Cy - $By) } 
   elsif ($angle >   90 and $angle < 180) { @fx = ($Bx - $Dx           ); @fy = ($Cy - $Ay           ) } 
   elsif ($angle == 180                 ) { @fx = ($Ax - $Dx, $Bx - $Cx); @fy = ($Cy - $Dy, $By - $Ay) } 
   elsif ($angle >  180 and $angle < 270) { @fx = ($Ax - $Cx           ); @fy = ($By - $Dy           ) } 
   elsif ($angle == 270                 ) { @fx = ($Dx - $Cx, $Ax - $Bx); @fy = ($By - $Cy, $Ay - $Dy) } 
   elsif ($angle >  270 and $angle < 360) { @fx = ($Dx - $Bx           ); @fy = ($Ay - $Cy           ) } 
   elsif ($angle == 360                 ) { @fx = ($Cx - $Bx, $Dx - $Ax); @fy = ($Ay - $By, $Dy - $Cy) } 
   else {
      die "Angle can not be greater than 360 degrees!";
   }
   @fx = sort {$a <=> $b} @fx;
   @fy = sort {$a <=> $b} @fy;
   return $fx[MAX],($self->{height} - $fy[MAX]) / 2;
}

sub setPixel        {shift->{image}->setPixel(@_)       }
sub line            {shift->{image}->line(@_)           }
sub rectangle       {shift->{image}->rectangle(@_)      }
sub filledRectangle {shift->{image}->filledRectangle(@_)}
sub ellipse         {shift->{image}->ellipse(@_)        }
sub arc             {shift->{image}->arc(@_)            }

1;

__END__

=head1 NAME

GD::SecurityImage::GD - GD backend for GD::SecurityImage.

=head1 SYNOPSIS

See L<GD::SecurityImage>.

=head1 DESCRIPTION

Used internally by L<GD::SecurityImage>. Nothing public here.

=head1 SEE ALSO

L<GD::SecurityImage>.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
