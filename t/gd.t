#!/usr/bin/env perl -w
use strict;
use vars qw[%API];
use Test;
use Cwd;

BEGIN {
   %API = (
      gd_normal             => 6,
      gd_ttf                => 6,
      gd_normal_scramble    => 6,
      gd_ttf_scramble       => 6,
      gd_ttf_scramble_fixed => 6,
   );
   my $total  = 0;
      $total += $API{$_} foreach keys %API;
   plan tests => $total;
   require GD::SecurityImage;
   import  GD::SecurityImage;
}

require 't/t.api';
my $tapi = 'tapi';
$tapi->clear;

my $font = getcwd.'/StayPuft.ttf';

foreach my $api (keys %API) {
   $tapi->options(args($api));
   my $c = 1;
   foreach my $style ($tapi->styles) {
      ok($tapi->save($api->$style()->out(force => 'png', compress => 1), $style, $api, $c++));
   }
}

sub args {
   my $name = shift;
   my %options = (
   gd_normal => {
      width      => 120,
      height     => 30,
      send_ctobg => 1,
      gd_font    => 'Giant',
   },
   gd_ttf => {
      width      => 350,
      height     => 60,
      send_ctobg => 1,
      font       => $font,
      ptsize     => 25,
   },
   gd_normal_scramble =>  {
      width      => 120,
      height     => 30,
      send_ctobg => 1,
      gd_font    => 'Giant',
      scramble   => 1,
   },
   gd_ttf_scramble =>  {
      width      => 350,
      height     => 60,
      send_ctobg => 1,
      font       => $font,
      ptsize     => 25,
      scramble   => 1,
   },
   gd_ttf_scramble_fixed =>  {
      width      => 350,
      height     => 60,
      send_ctobg => 1,
      font       => $font,
      ptsize     => 25,
      scramble   => 1,
      angle      => 30,
   },
   );
   my $o = $options{$name};
   return %{$o}
}
