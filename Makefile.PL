use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'GD::SecurityImage',
    'VERSION_FROM' => 'lib/GD/SecurityImage.pm',
    'PREREQ_PM'    => { 'GD' => 0 },
    ($] >= 5.005 ? (
    'AUTHOR'       => 'Burak Gursoy <burak@cpan.org>',
    'ABSTRACT'     => 'Create a security image with a random string on it',
     ) : ()),
);
