#!/usr/bin/env perl -w
use strict;
use subs qw[save];

use Test;

BEGIN {
   require GD::SecurityImage;
   eval "require Image::Magick";
   my $skip;
   if ($@) {
      $skip = "You don't have Image::Magick installed.";
   } elsif (-e "skip_magick") {
      $skip = "You didn't select Image::Magick.";
   } elsif ($Image::Magick::VERSION lt '6.0.4') {
      $skip = "There is a bug in your PerlMagick version's ($Image::Magick::VERSION) QueryFontMetrics() method. Please upgrade to 6.0.4.";
   } else {
      $skip = '';
   }

   if ($skip) {
      plan tests => 1;
      skip($skip . " Skipping...", sub{1});
      exit;
   } else {
      plan tests => 6;
      import GD::SecurityImage use_magick => 1;
   }
}

use Cwd;

my %same = (
   width      => 250,
   height     => 80,
   send_ctobg => 1,
   font       => getcwd.'/StayPuft.ttf',
   ptsize     => 50,

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
   my $name = sprintf "magick_%02d_%s.%s", $counter, $style, $mime;
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
          ->new(lines => 60, bgcolor => [0,0,0], %same)
          ->random('EC0123')
          ->create(ttf => 'ec', [84, 207, 112], [0,0,0])
          ->particle(3000)
}

sub ellipse {
   return GD::SecurityImage
          ->new(lines => 80, bgcolor => [208, 202, 206], %same)
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
          ->particle(8000)
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
