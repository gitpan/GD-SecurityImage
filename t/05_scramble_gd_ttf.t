#!/usr/bin/env perl -w
use strict;
use subs qw[save];

use Test;
use Cwd;

BEGIN { 
   require GD::SecurityImage;
   eval "require GD";
   if (-e "skip_gd" || $@) {
      my $skip = $@ ? "You don't have GD installed." : "You didn't select GD.";
      plan tests => 1;
      skip($skip . " Skipping...", sub{0});
      exit;
   } else {
      plan tests => 6;
      import GD::SecurityImage;
   }
}

my %same = (
   width      => 450,
   height     => 80,
   send_ctobg => 1,
   font       => getcwd.'/StayPuft.ttf',
   ptsize     => 25,
   scramble   => 1,

);

my $counter = 1;
(my $ID = $0) =~ s[.+?(\d+)_.*$][$1];

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
   my $name = sprintf "%s_%02d_%s.%s", $ID, $counter, $style, $mime;
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
          ->particle(4000)
}

sub ellipse {
   return GD::SecurityImage
          ->new(lines => 70, bgcolor => [208, 202, 206], %same)
          ->random('ELLIPSE')
          ->create(ttf => 'ellipse', [156,101,49], [156,101,49])
          ->particle(8000,2)
}

sub circle {
   return GD::SecurityImage
          ->new(lines => 50, bgcolor => [210, 215, 196], %same)
          ->random('CIRCLE')
          ->create(ttf => 'circle', [163, 100, 167], [210, 215, 196])
          ->particle(3000,2)
}

sub box {
   return GD::SecurityImage
          ->new(lines => 10, %same)
          ->random('BOX012')
          ->create(ttf => 'box', [63, 143, 167], [226, 223, 169])
          ->particle(5000,4)
}

sub rect {
   return GD::SecurityImage
          ->new(lines => 40, %same)
          ->random('RECT01')
          ->create(ttf => 'rect', [63, 25, 167], [226, 223, 169])
          ->particle(5000)
}

sub default {
   return GD::SecurityImage
          ->new(lines => 30, %same)
          ->random('DEFAULT')
          ->create(ttf => 'default', [68,150,125], [255,0,0])
          ->particle(10000)
}
