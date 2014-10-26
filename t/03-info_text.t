#!/usr/bin/env perl -w
use strict;
use Test;
use Cwd;
use GD::SecurityImage;

plan tests => 1;

my $i      = GD::SecurityImage->new->random;
my $random = $i->random_str;
$i->create;
$i->info_text(
   gd     => 1,
   strip  => 1,
   color  => '#000000',
   scolor => '#FFFFFF',
   text   => 'GD::SecurityImage',
);

my( $image, $mime, $random2 ) = $i->out;

ok( $random eq $random2 ); # info_text must not affect random string
