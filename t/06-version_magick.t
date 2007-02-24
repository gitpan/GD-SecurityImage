#!/usr/bin/env perl -w
use strict;
use Test;
use Cwd;

BEGIN {
   eval "require Image::Magick;";
   my $skip;

   if ( $@ ) {
      $skip = "You don't have Image::Magick installed.";
   }
   elsif ($Image::Magick::VERSION lt '6.0.4') {
      $skip = "There may be a bug in your PerlMagick version's "
             ."($Image::Magick::VERSION) QueryFontMetrics() method. "
             ."Please upgrade to 6.0.4 or newer.";
   }
   else {
      $skip = '';
   }

   my $TOTAL = 6;
   plan tests => $TOTAL;

   if ($skip) {
      skip($skip . " Skipping...", sub{1}) for 1..$TOTAL;
      exit;
   }
   else {
      require GD::SecurityImage;
      GD::SecurityImage->import( use_magick => 1 );
   }
}

my $i = GD::SecurityImage->new;

my $gt = $i->_versiongt(6.0);
my $lt = $i->_versionlt('6.4.3');
ok( defined $gt );
ok( defined $lt );

GT: {
   local $Image::Magick::VERSION = '6.0.3';
   ok( $i->_versiongt(  6.0    ) );
   ok( $i->_versiongt( '6.0.3' ) );
   ok( $i->_versionlt(  6.2    ) );
   ok( $i->_versionlt( '6.2.6' ) );
}
