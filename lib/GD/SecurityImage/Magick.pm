package GD::SecurityImage::Magick;
# GD method emulation class for Image::Magick
use strict;
use vars qw[$VERSION];
use constant IM_WIDTH       => 4;
use constant IM_ASCENDER    => 2;

use Image::Magick;

$VERSION = "1.0";

sub init {
   # Create the image object
   my $self = shift;
   my $bg = sprintf "rgb(%s)", join ",", @{ $self->{bgcolor} }; 
      $self->{image} = Image::Magick->new;
      $self->{image}->Set(size=> "$self->{width}x$self->{height}");
      $self->{image}->Read('null:' . $bg);
      $self->{image}->Set(background => $bg);
      $self->{MAGICK} = {strokewidth => 0.6};
}

sub insert_text {
   # Draw text using Image::Magick
   my $self   = shift;
   my $method = shift; # not needed with Image::Magick (always use ttf)
   my $color  = shift;
   my $key = $self->{_RANDOM_NUMBER_}; # random string
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
                            fill      => sprintf("rgb(%s)", join(",", @{$color->{text}})),
                            x         => $x,
                            y         => $y );
}

sub line {
   my $self = shift;
   my($x1,$y1,$x2,$y2,$color) = @_;
      $self->{image}->Draw(
         primitive => "line",
         points    => "$x1,$y1 $x2,$y2",
         stroke    => sprintf("rgb(%s)", join(",", @{$color})),
         strokewidth => $self->{MAGICK}{strokewidth},
      );
}

sub rectangle {
   my $self = shift;
   my($x1,$y1,$x2,$y2,$color) = @_;
      $self->{image}->Draw(
         primitive => "rectangle",
         points    => "$x1,$y1 $x2,$y2",
         stroke    => sprintf("rgb(%s)", join(",", @{$color})),
         strokewidth => $self->{MAGICK}{strokewidth},
      );
}

sub filledRectangle {
   my $self = shift;
   my($x1,$y1,$x2,$y2,$color) = @_;
      $self->{image}->Draw(
         primitive   => "rectangle",
         points      => "$x1,$y1 $x2,$y2",
         fill        => sprintf("rgb(%s)", join(",", @{$color})),
         stroke      => sprintf("rgb(%s)", join(",", @{$color})),
         strokewidth => 0,
      );
}

sub ellipse {
   my $self = shift;
   my($cx,$cy,$width,$height,$color) = @_;
      $self->{image}->Draw(
         primitive => "ellipse",
         points    => "$cx,$cy $width,$height 0,360",
         stroke    => sprintf("rgb(%s)", join(",", @{$color})),
         strokewidth => $self->{MAGICK}{strokewidth},
      );
}

sub arc {
   my $self = shift;
   my($cx,$cy,$width,$height,$start,$end,$color) = @_;
      $self->{image}->Draw(
         primitive => "ellipse", # I couldn't do that with "arc" primitive. patches are welcome, but this seems to work :)
         points    => "$cx,$cy $width,$height $start,$end",
         stroke    => sprintf("rgb(%s)", join(",", @{$color})),
         strokewidth => $self->{MAGICK}{strokewidth},
      );
}

1;

__END__

=head1 NAME

GD::SecurityImage::Magick - Create a security image with a random string on it.

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
