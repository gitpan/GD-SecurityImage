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
   width      => 80,
   height     => 30,
   send_ctobg => 1,
   gd_font    => 'giant',
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
   my $name = sprintf "gd_%02d_%s.%s", $counter, $style, $mime;
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
          ->new(lines => 5, bgcolor => [0,0,0], %same)
          ->random('EC0123')
          ->create(normal => 'ec', [84, 207, 112], [0,0,0])
          ->particle(100)
}

sub ellipse {
   return GD::SecurityImage
          ->new(lines => 10, bgcolor => [208, 202, 206], %same)
          ->random('ELLIPSE')
          ->create(normal => 'ellipse', [31,219,180], [231,219,180])
          ->particle(100)
}

sub circle {
   return GD::SecurityImage
          ->new(lines => 5, bgcolor => [210, 215, 196], %same)
          ->random('CIRCLE')
          ->create(normal => 'circle', [63, 143, 167], [90, 195, 176])
          ->particle(250, 2)
}

sub box {
   return GD::SecurityImage
          ->new(lines => 5, %same)
          ->random('BOX012')
          ->create(normal => 'box', [63, 143, 167], [226, 223, 169])
          ->particle(150, 4)
}

sub rect {
   return GD::SecurityImage
          ->new(lines => 10, %same)
          ->random('RECT01')
          ->create(normal => 'rect', [63, 143, 167], [226, 223, 169])
          ->particle(200)
}

sub default {
   return GD::SecurityImage
          ->new(lines => 10, %same, send_ctobg => 0)
          ->random('DEFAULT')
          ->create(normal => 'default', [68,150,125], [255,0,0])
          ->particle(250)
}


