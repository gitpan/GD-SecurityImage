#!/usr/bin/env perl -w
# Simple test. Just try to use the module.
use strict;
use Test;
BEGIN { plan tests => 1 }

use Cwd;
use GD::SecurityImage;

skip(
    $GD::VERSION < 1.20 ? "Your version of GD does not implement ttf methods." : 0,
    \&ttf_test
);

exit;

sub ttf_test {
   my $image = GD::SecurityImage->new(
                  width    => 110,
                  height   => 40,
                  ptsize   => 15,
                  lines    => 20,
                  rndmax   => 6,
                  rnd_data => [0..9, 'A'..'Z'],
                  font     => getcwd.'/StayPuft.ttf',
                  bgcolor  => [115, 255, 255],
                  send_ctobg => 1,
   );

   $image->random('PERL58'); # define our own random string.
   $image->create(ttf => 'ellipse', [10,10,10], [210,210,50]);

   my($image_data, $mime_type, $random_string) = $image->out;

   my $file = "03_ttf.$mime_type";

   open IMAGE, '>'.$file or die "Can not create the graphic: $!";
   binmode IMAGE;
   print IMAGE $image_data;
   close IMAGE;
}

__END__
