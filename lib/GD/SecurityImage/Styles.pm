package GD::SecurityImage::Styles;
use strict;
use vars qw[$VERSION];

$VERSION = "1.0";

sub style_default {
   my $self  = shift;
   my $fx    = $self->{width}  / $self->{lines};
   my $fy    = $self->{height} / $self->{lines};
   my %color = @_;

   $self->rectangle(0,0,$self->{width}-1,$self->{height}-1, $color{lines}); # put a frame around the image

   for my $i (0..$self->{lines}) {
      $self->line($i * $fx, 0,  $i * $fx     , $self->{height}, $color{lines}); # | line
      $self->line($i * $fx, 0, ($i * $fx)+$fx, $self->{height}, $color{lines}); # \ line
   }

   for my $i (1..$self->{lines}) {
      $self->line(0, $i * $fy, $self->{width}, $i * $fy, $color{lines}); # - line
   }
}

sub style_rect {
   my $self  = shift;
   my $fx    = $self->{width}  / $self->{lines};
   my $fy    = $self->{height} / $self->{lines};
   my %color = @_;

   $self->rectangle(0,0,$self->{width}-1,$self->{height}-1, $color{lines}); # put a frame around the image

   for my $i (0..$self->{lines}) {
      $self->line($i * $fx, 0,  $i * $fx     , $self->{height}, $color{lines}); # | line
   }

   for my $i (1..$self->{lines}) {
      $self->line(0, $i * $fy, $self->{width}, $i * $fy, $color{lines}); # - line
   }
}

sub style_box {
   my $self  = shift;
   my %color = @_;
   my $w = $self->{lines};
   $self->filledRectangle(0 , 0 , $self->{width}         , $self->{height}         , $color{text});
   $self->filledRectangle($w, $w, $self->{width} - $w - 1, $self->{height} - $w - 1, $color{lines} );
}

sub style_circle {
   my $self  = shift;
   my $cx    = $self->{width}  / 2;
   my $cy    = $self->{height} / 2;
   my %color = @_;
   my $max   = int $self->{width} / $self->{lines};
      $max++;

   for(1..$self->{lines}){
      $self->arc($cx,$cy,$max*$_,$max*$_,0,360,$color{lines});
   }
}

sub style_ellipse {
   my $self  = shift;
   my $cx    = $self->{width}  / 2;
   my $cy    = $self->{height} / 2;
   my %color = @_;
   my $max   = int $self->{width} / $self->{lines};
      $max++;

   for(1..$self->{lines}){
      $self->ellipse($cx,$cy,$max*$_*2,$max*$_,$color{lines});
   }
}

sub style_ec {
   my $self  = shift;
      $self->style_ellipse(@_);
      $self->style_circle(@_);
}

1;

__END__

=head1 NAME

GD::SecurityImage::Styles - Create a security image with a random string on it.

=head1 SYNOPSIS

See L<GD::SecurityImage>.

=head1 DESCRIPTION

This module contains the styles used in the security image.

Used internally by L<GD::SecurityImage>. Nothing public here.

=head1 SEE ALSO

L<GD::SecurityImage>.

=head1 AUTHOR

Burak G�rsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 Burak G�rsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
