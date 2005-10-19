use strict;
use Module::Build;
Module::Build->new(
   module_name => 'GD::SecurityImage',
   license     => 'perl',
   requires    => { 'GD'            => 0      },
   recommends  => { 'Image::Magick' => '6.0.4'},
   sign        => 1,
   dist_author => 'Burak Gursoy <burak@cpan.org>',
)->create_build_script;
