package GD::SecurityImage::GD;
# GD method wrapper class
use strict;
use vars qw[$VERSION];

use constant LOW_LEFT_X  => 0;
use constant LOW_LEFT_Y  => 1;
use constant LOW_RIGHT_X => 2;
use constant UP_LEFT_Y   => 7;

use GD;

$VERSION = "1.2";

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
      my $methTTF = $GD::VERSION >= 1.31 ? 'stringFT' : 'stringTTF';
      # don' t draw. we just need info...
      my @box = GD::Image->$methTTF($self->{_COLOR_}{text},$self->{font},$self->{ptsize},0,0,0,$key)
                # or die "I can not get the boundary list: $@"
                # I think that libgd also has some problems 
                # with paths that have spaces in it.
                ;
      # use fake values instead of die-ing :p I hate die-ing :p
      # I'm beginning to hate tests :p
      # I'm beginning to hate windows :p
      # I'm beginning to hate GD :p
      unless (@box) {
         $self->{GDBOX_EMPTY} = 1; # set this for error checking.
         $#box    = 7;
         # lets initialize to silence the warnings
         $box[$_] = 1 foreach(LOW_RIGHT_X, LOW_LEFT_X, UP_LEFT_Y, LOW_LEFT_Y);
      }
      my $x = ($self->{width}  - ($box[LOW_RIGHT_X] - $box[LOW_LEFT_X])) / 2;
      my $y = ($self->{height} - ($box[UP_LEFT_Y]   - $box[LOW_LEFT_Y])) / 2;
      $self->{image}->$methTTF($self->{_COLOR_}{text}, $self->{font}, $self->{ptsize}, 0, $x, $y, $key);
   } else {
      my $sw = $self->{gd_font}->width * length($key);
      my $sh = $self->{gd_font}->height;
      my $x  = ($self->{width}  - $sw) / 2;
      my $y  = ($self->{height} - $sh) / 2;
      $self->{image}->string($self->{gd_font}, $x, $y, $key, $self->{_COLOR_}{text});
   }
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
