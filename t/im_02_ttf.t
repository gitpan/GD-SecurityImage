#!/usr/bin/env perl -w
# Create the image with a ttf font.
use strict;
use Test;
BEGIN { 
   plan tests => 1;
   if (-e "skip_magick") {
      skip("You didn't select Image::Magick. Skipping...", sub{0});
      exit;
   }
}

use Cwd;
use GD::SecurityImage use_magick => 1;

ttf_test();
ok(1);

exit;

sub ttf_test {
   my $image = GD::SecurityImage->new(
                  width    => 150,
                  height   => 60,
                  ptsize   => 30,
                  lines    => 40,
                  font     => getcwd.'/StayPuft.ttf',
                  bgcolor  => [115, 255, 255],
                  send_ctobg => 1,
   );

   $image->random('MAGICK'); # define our own random string.
   $image->create(ttf => 'ellipse', [75,145,260], [210,210,50]);

   my($image_data, $mime_type, $random_string) = $image->out;

   my $file = "im_02_ttf.$mime_type";

   open IMAGE, '>'.$file or die "Can not create the graphic: $!";
   binmode IMAGE;
   print IMAGE $image_data;
   close IMAGE;
}

__END__
