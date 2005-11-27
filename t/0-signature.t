#!/usr/bin/env perl -w
use strict;
BEGIN { do 't/skip.test' or die "Can't include skip.test!" }

if (!eval { require Module::Signature; 1 }) {
    plan skip_all => 
      "Next time around, consider installing Module::Signature, ".
      "so you can verify the integrity of this distribution.";
} elsif ($Module::Signature::VERSION <= 0.50 && $^O ne 'MSWin32') {
    plan skip_all => "Module::Signature currently has a problem with CRLF files. By-passing signature test.";
} elsif ( !-e 'SIGNATURE' ) {
    plan skip_all => "SIGNATURE not found";
} elsif ( -s 'SIGNATURE' == 0 ) {
    plan skip_all => "SIGNATURE file empty";
} elsif (!eval { require Socket; Socket::inet_aton('pgp.mit.edu') }) {
    plan skip_all => "Cannot connect to the keyserver to check module ".
                     "signature";
} else {
    plan tests => 1;
}

my $ret = Module::Signature::verify();
SKIP: {
    skip "Module::Signature cannot verify", 1 
      if $ret eq Module::Signature::CANNOT_VERIFY();

    cmp_ok $ret, '==', Module::Signature::SIGNATURE_OK(), "Valid signature";
}
