#!/usr/bin/env perl -w
use strict;
use subs qw[save];

use Test;

BEGIN { 
   if (-e "skip_gd") {
      plan tests => 1;
      skip("You didn't select GD. Skipping...", sub{0});
      exit;
   } else {
      plan tests => 6;
   }
}

use GD::SecurityImage;
use Cwd;

my %same = (
   width      => 250,
   height     => 80,
   send_ctobg => 1,
   font       => getcwd.'/StayPuft.ttf',
   ptsize     => 40,

);
my $counter = 1;

generate();

sub generate {
   no strict 'refs';
   foreach my $style (qw[default rect box circle ellipse ec]) {
      ok(save &$style()->out(force => 'png'), $style);
      $counter++;
   }
}

sub save {
   my ($image, $mime, $random, $style) = @_;
   my $name = sprintf "gdttf_%02d_%s.%s", $counter, $style, $mime;
   local  *SI;
   open    SI, ">$name" or die "Error writing the image '$name' to disk: $!";
   binmode SI;
   print   SI $image;
   close   SI;
   print "[OK] $name\n";
   return 'SUCCESS';
}

sub ec {
   return GD::SecurityImage
          ->new(lines => 40, bgcolor => [0,0,0], %same)
          ->random('EC0123')
          ->create(ttf => 'ec', [84, 207, 112], [0,0,0])
          ->particle(3000)
}

sub ellipse {
   return GD::SecurityImage
          ->new(lines => 70, bgcolor => [208, 202, 206], %same)
          ->random('ELLIPSE')
          ->create(ttf => 'ellipse', [231,219,180], [231,219,180])
          ->particle
}

sub circle {
   return GD::SecurityImage
          ->new(lines => 70, bgcolor => [210, 215, 196], %same)
          ->random('CIRCLE')
          ->create(ttf => 'circle', [63, 143, 167], [210, 215, 196])
          ->particle
}

sub box {
   return GD::SecurityImage
          ->new(lines => 10, %same, frame => 0)
          ->random('BOX012')
          ->create(ttf => 'box', [255,255,255], [115, 115, 115])
          ->particle(8000, 2)
}

sub rect {
   return GD::SecurityImage
          ->new(lines => 40, %same)
          ->random('RECT01')
          ->create(ttf => 'rect', [63, 143, 167], [226, 223, 169])
          ->particle
}

sub default {
   return GD::SecurityImage
          ->new(lines => 15, %same)
          ->random('DEFAULT')
          ->create(ttf => 'default', [68,150,125], [255,0,0])
          ->particle(10000)
}
