#!/usr/bin/env perl -w
use strict;
use Test;
use Cwd;
use GD::SecurityImage backend => 'Magick';

plan tests => 6;

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
