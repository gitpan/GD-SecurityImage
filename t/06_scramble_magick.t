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
   width      => 350,
   height     => 80,
   send_ctobg => 1,
   font       => getcwd.'/StayPuft.ttf',
   ptsize     => 30,
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
          ->new(lines => 100, bgcolor => [0,0,0], %same)
          ->random('EC0123')
          ->create(normal => 'ec', [84, 207, 112], [0,0,0])
          ->particle(4000)
}

sub ellipse {
   return GD::SecurityImage
          ->new(lines => 600, bgcolor => [208, 202, 206], %same)
          ->random('ELLIPSE')
          ->create(normal => 'ellipse', [156,101,49], [208, 202, 206])
          ->particle(8000)
}

sub circle {
   return GD::SecurityImage
          ->new(lines => 300, bgcolor => [210, 215, 196], %same)
          ->random('CIRCLE')
          ->create(normal => 'circle', [163, 100, 167], [210, 215, 196])
          ->particle(3000,2)
}

sub box {
   return GD::SecurityImage
          ->new(lines => 10, %same)
          ->random('BOX012')
          ->create(normal => 'box', [63, 143, 167], [226, 223, 169])
          ->particle(4000,4)
}

sub rect {
   return GD::SecurityImage
          ->new(lines => 40, %same)
          ->random('RECT01')
          ->create(normal => 'rect', [63, 25, 167], [226, 223, 169])
          ->particle(5000)
}

sub default {
   return GD::SecurityImage
          ->new(lines => 45, %same)
          ->random('DEFAULT')
          ->create(normal => 'default', [68,150,125], [25,200,25])
          ->particle(10000)
}
