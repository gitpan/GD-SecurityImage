package GD::SecurityImage::Magick;
# GD method emulation class for Image::Magick
use strict;
use vars qw[$VERSION];
use constant IM_WIDTH    => 4;
use constant IM_ASCENDER => 2;

use Image::Magick;

$VERSION = "1.12";

sub gdbox_empty {0} # fake method for GD compatibility.

sub rgbx {
   # Convert color data to hex for Image::Magick
   my $self   = shift;
   my @data   = (ref $_[0] and ref $_[0] eq 'ARRAY') ? (@{$_[0]}) : (@_);
   return $self->r2h(@data);
}

sub init {
   # Create the image object
   my $self = shift;
   my $bg   = $self->rgbx($self->{bgcolor}); 
      $self->{image} = Image::Magick->new;
      $self->{image}->Set(size=> "$self->{width}x$self->{height}");
      $self->{image}->Read('null:' . $bg);
      $self->{image}->Set(background => $bg);
      $self->{MAGICK} = {strokewidth => 0.6};
}

sub out {
   my $self = shift;
   my %opt  = scalar @_ % 2 ? () : (@_);
   my $type = 'gif'; # default format
   if ($opt{force}) {
      my %g = map {$_, 1} $self->{image}->QueryFormat;
      $type = $opt{force} if exists $g{$opt{force}};
   }
   $self->{image}->Set(magick => $type);
   return $self->{image}->ImageToBlob, $type, $self->{_RANDOM_NUMBER_};
}

sub insert_text {
   # Draw text using Image::Magick
   my $self   = shift;
   my $method = shift; # not needed with Image::Magick (always use ttf)
   my $key    = $self->{_RANDOM_NUMBER_}; # random string
   my @metric = $self->{image}
                     ->QueryFontMetrics(font      => $self->{font},
                                        text      => $key,
                                        pointsize => $self->{ptsize});
   # Text is not in the middle. There is a minimal error placing the text.
   # Some manual altering is required unless there is a better way...
   my $x = ($self->{width}  - $metric[IM_WIDTH]   ) / 2;
   my $y = ($self->{height} + $metric[IM_ASCENDER]) / 2;

   $self->{image}->Annotate(font      => $self->{font},
                            encoding  => 'UTF-8',
                            text      => $key,
                            pointsize => $self->{ptsize},
                            fill      => $self->rgbx($self->{_COLOR_}{text}),
                            x         => $x,
                            y         => $y );
}

sub setPixel {
   my $self = shift;
   my($x, $y, $color) = @_;
   $self->{image}->Set("pixel[$x,$y]" => $self->rgbx($color) );
}

sub line {
   my $self = shift;
   my($x1, $y1, $x2, $y2, $color) = @_;
      $self->{image}->Draw(
         primitive   => "line",
         points      => "$x1,$y1 $x2,$y2",
         stroke      => $self->rgbx($color),
         strokewidth => $self->{MAGICK}{strokewidth},
      );
}

sub rectangle {
   my $self = shift;
   my($x1,$y1,$x2,$y2,$color) = @_;
      $self->{image}->Draw(
         primitive   => "rectangle",
         points      => "$x1,$y1 $x2,$y2",
         stroke      => $self->rgbx($color),
         strokewidth => $self->{MAGICK}{strokewidth},
      );
}

sub filledRectangle {
   my $self = shift;
   my($x1,$y1,$x2,$y2,$color) = @_;
      $self->{image}->Draw(
         primitive   => "rectangle",
         points      => "$x1,$y1 $x2,$y2",
         fill        => $self->rgbx($color),
         stroke      => $self->rgbx($color),
         strokewidth => 0,
      );
}

sub ellipse {
   my $self = shift;
   my($cx,$cy,$width,$height,$color) = @_;
      $self->{image}->Draw(
         primitive   => "ellipse",
         points      => "$cx,$cy $width,$height 0,360",
         stroke      => $self->rgbx($color),
         strokewidth => $self->{MAGICK}{strokewidth},
      );
}

sub arc {
   my $self = shift;
   my($cx,$cy,$width,$height,$start,$end,$color) = @_;
      $self->{image}->Draw(
         primitive   => "ellipse", # I couldn't do that with "arc" primitive. patches are welcome, but this seems to work :)
         points      => "$cx,$cy $width,$height $start,$end",
         stroke      => $self->rgbx($color),
         strokewidth => $self->{MAGICK}{strokewidth},
      );
}

1;

__END__

=head1 NAME

GD::SecurityImage::Magick -  Image::Magick backend for GD::SecurityImage.

=head1 SYNOPSIS

See L<GD::SecurityImage>.

=head1 DESCRIPTION

Includes GD method emulations for Image::Magick.

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
