#!/usr/bin/env perl -w
# Create the image with a ttf font.
use strict;
use Test;
BEGIN { 
   plan tests => 1;
   if (-e "skip_gd") {
      skip("You didn't select GD. Skipping...", sub{0});
      exit;
   }
}

use Cwd;
use GD::SecurityImage;

skip(
    $GD::VERSION < 1.20 ? "Your version of GD does not implement ttf methods." : 0,
    \&ttf_test
);

exit;

sub ttf_test {
   my $image = GD::SecurityImage->new(
                  width    => 150,
                  height   => 60,
                  ptsize   => 30,
                  lines    => 20,
                  font     => getcwd.'/StayPuft.ttf',
                  bgcolor  => [115, 255, 255],
                  send_ctobg => 1,
   );

   $image->random('PERL58'); # define our own random string.
   $image->create(ttf => 'ellipse', [10,10,10], [210,210,50]);

   my($image_data, $mime_type, $random_string) = $image->out;

   my $file = "gd_03_ttf.$mime_type";

   open IMAGE, '>'.$file or die "Can not create the graphic: $!";
   binmode IMAGE;
   print IMAGE $image_data;
   close IMAGE;
}

__END__
