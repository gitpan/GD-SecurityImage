#!/usr/bin/env perl -w
# Simple test. Just try to use the module.
use strict;
use Test;
BEGIN { 
   plan tests => 1;
   if (-e "skip_gd") {
      skip("You didn't select GD. Skipping...", sub{0});
      exit;
   }
}

use GD::SecurityImage; 

ok(1);

exit;

__END__
