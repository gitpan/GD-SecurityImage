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
   width      => 200,
   height     => 20,
   send_ctobg => 1,
   gd_font    => 'giant',
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
          ->new(lines => 1, bgcolor => [0,0,0], %same)
          ->random('EC0123')
          ->create(normal => 'ec', [84, 207, 112], [0,0,0])
          ->particle(150,2)
}

sub ellipse {
   return GD::SecurityImage
          ->new(lines => 8, bgcolor => [208, 202, 206], %same)
          ->random('ELLIPSE')
          ->create(normal => 'ellipse', [156,101,49], [156,101,49])
          ->particle(300)
}

sub circle {
   return GD::SecurityImage
          ->new(lines => 4, bgcolor => [210, 215, 196], %same)
          ->random('CIRCLE')
          ->create(normal => 'circle', [163, 100, 167], [210, 215, 196])
          ->particle(300)
}

sub box {
   return GD::SecurityImage
          ->new(lines => 4, %same)
          ->random('BOX012')
          ->create(normal => 'box', [63, 143, 167], [226, 223, 169])
          ->particle(300,2)
}

sub rect {
   return GD::SecurityImage
          ->new(lines => 8, %same)
          ->random('RECT01')
          ->create(normal => 'rect', [63, 25, 167], [226, 223, 169])
          ->particle(300)
}

sub default {
   return GD::SecurityImage
          ->new(lines => 4, %same)
          ->random('DEFAULT')
          ->create(normal => 'default', [68,150,125], [255,0,0])
          ->particle(250)
}
