#!/usr/bin/env perl -w
# Simple test. Just try to use the module.
use strict;
use Test;
BEGIN { plan tests => 1 }

use GD::SecurityImage; 

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

$image->random; # let the module create this
printf STDERR "\nRandom string: %s\n", $image->random_str;
$image->create(normal => 'rect', [10,10,10], [210,210,50]);

my($image_data, $mime_type, $random_string) = $image->out;

my $file = "02_normal.$mime_type";

open IMAGE, '>'.$file or die "Can not create the graphic: $!";
binmode IMAGE;
print IMAGE $image_data;
close IMAGE;

ok(1);

exit;

__END__
