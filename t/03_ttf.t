#!/usr/bin/env perl -w
# Simple test. Just try to use the module.
use strict;
use Test;
BEGIN { plan tests => 1 }

use Cwd;
use GD::SecurityImage;

my $image = GD::SecurityImage->new(
               width    => 110,
               height   => 40,
               ptsize   => 15,
               lines    => 10,
               rndmax   => 6,
               rnd_data => [0..9, 'A'..'Z'],
               font     => getcwd.'/StayPuft.ttf',
               bgcolor  => [115, 255, 255],
);

$image->random('PERL58'); # define our own random string.
$image->create(ttf => 'rect', [10,10,10], [210,210,50]);

my($image_data, $mime_type, $random_string) = $image->out;

my $file = "03_ttf.$mime_type";

open IMAGE, '>'.$file or die "Can not create the graphic: $!";
binmode IMAGE;
print IMAGE $image_data;
close IMAGE;

ok(1);

exit;

__END__
