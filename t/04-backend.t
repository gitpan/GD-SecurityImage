#!/usr/bin/env perl -w
use strict;
use Test;
use Cwd;

BEGIN {

   eval "require Image::Magick";
   my $skip = $@ ? "You don't have Image::Magick installed." : '';

   if ($skip) {
      plan tests => 1;
      skip($skip . " Skipping...", sub{1});
      exit;
   }
   else {
      plan tests => 5;
      require GD::SecurityImage;
      eval { GD::SecurityImage->new };
      ok($@); # if there is an error == OK [since we didn't import() so far]
      # test if we've loaded the right library
      import  GD::SecurityImage use_magick => 0       ; ok(GD::SecurityImage->new->raw->isa('GD::Image'    ));
      import  GD::SecurityImage use_magick => 1       ; ok(GD::SecurityImage->new->raw->isa('Image::Magick'));
      import  GD::SecurityImage backend    => 'GD'    ; ok(GD::SecurityImage->new->raw->isa('GD::Image'    ));
      import  GD::SecurityImage backend    => 'Magick'; ok(GD::SecurityImage->new->raw->isa('Image::Magick'));
      exit;
   }

}
