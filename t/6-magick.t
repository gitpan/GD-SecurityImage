#!/usr/bin/env perl -w
use strict;
use vars qw[%API];
use Test;
use Cwd;

BEGIN {
   eval "require Image::Magick;";
   my $skip;
   if ($@) {
      $skip = "You don't have Image::Magick installed.";
   } elsif ($Image::Magick::VERSION lt '6.0.4') {
      $skip = "There may be a bug in your PerlMagick version's ($Image::Magick::VERSION) QueryFontMetrics() method. Please upgrade to 6.0.4 or newer.";
   } else {
      $skip = '';
   }

   if ($skip) {
      plan tests => 1;
      skip($skip . " Skipping...", sub{1});
      exit;
   } else {
      %API = (
         magick                          => 6,
         magick_scramble                 => 6,
         magick_scramble_fixed           => 6,
         magick_info_text                => 6,
         magick_scramble_info_text       => 6,
         magick_scramble_fixed_info_text => 6,
      );
      my $total  = 0;
         $total += $API{$_} foreach keys %API;
      plan tests => $total;
      require GD::SecurityImage;
      import  GD::SecurityImage use_magick => 1;
   }
}

require 't/t.api';
my $tapi = 'tapi';
   $tapi->clear;

my $font = getcwd.'/StayPuft.ttf';

my %info_text = (
   text   => $tapi->the_info_text,
   ptsize => 12,
   color  => '#000000',
   scolor => '#FFFFFF',
);

foreach my $api (keys %API) {
   $tapi->options(args($api), extra($api));
   my $c = 1;
   foreach my $style ($tapi->styles) {
      ok($tapi->save($api->$style()->out(force => 'png', compress => 1), $style, $api, $c++));
   }
   $tapi->clear;
}

sub extra {
   my $name = shift;
   if ($name =~ m/_info_text$/) {
      return info_text => {%info_text};
   }
   return +();
}

sub args {
   my $name = shift;
   my %options = (
   magick => {
      width      => 250,
      height     => 80,
      send_ctobg => 1,
      font       => $font,
      ptsize     => 50,
   },
   magick_scramble => {
      width      => 350,
      height     => 80,
      send_ctobg => 1,
      font       => $font,
      ptsize     => 30,
      scramble   => 1,
   },
   magick_scramble_fixed => {
      width      => 350,
      height     => 80,
      send_ctobg => 1,
      font       => $font,
      ptsize     => 30,
      scramble   => 1,
      angle      => 32,
   },
   );
   my $o = $options{$name};
   unless ($o) {
     (my $tmp = $name) =~ s,_info_text,,;
      $o = $options{$tmp};
   }
   $o or die "Bogus arg name $name!";
   return %{$o}
}
