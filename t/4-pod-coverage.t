#!/usr/bin/env perl -w
use strict;
BEGIN { do 't/skip.test' or die "Can't include skip.test!" }

eval "use Test::Pod::Coverage;1";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;

plan tests => 2;
unless($@) {
   # cheat a little
   pod_coverage_ok('GD::SecurityImage'    , { trustme => [qw/add_strip  cconvert gdf h2r  is_hex r2h    random_angle/]});
   pod_coverage_ok('GD::SecurityImage::AC', { trustme => [qw/check_code create_image_file database_data database_file generate_code new unt_output_folder/]});
}
