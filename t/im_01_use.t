#!/usr/bin/env perl -w
# Simple test. Just try to use the module.
use strict;
use Test;
BEGIN { 
   plan tests => 1;
   if (-e "skip_magick") {
      skip("You didn't select Image::Magick. Skipping...", sub{0});
      exit;
   }
}

require GD::SecurityImage;
import  GD::SecurityImage use_magick => 1;

ok(1);

exit;

__END__
