use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %prereq;

my $makec = $^O eq 'MSWin32' ? 'nmake' : 'make';

my $ask = qq~This module needs a graphic library to function properly.
The supported modules are GD and Image::Magick.

Note that; both GD and Image::Magick related modules will be 
installed.
But your selection affects the tests (if you do a `$makec test`)
and the prerequisites.

Please select an option below (default is 1):

[1] I want to use GD
[2] I want to use Image::Magick
[3] I want both GD and Image::Magick

Enter your choice: ~;

my $input  = prompt($ask, "1");
   $input += 0;
   $input  = 1 if ! $input || $input > 3 || $input < 1;

print "Your selection is [$input]\n";

%prereq = ('GD' => 0                      ) if $input == 1;
%prereq = ('Image::Magick' => 0           ) if $input == 2;
%prereq = ('Image::Magick' => 0, 'GD' => 0) if $input == 3;

skip_t($input);

WriteMakefile(
    'NAME'         => 'GD::SecurityImage',
    'VERSION_FROM' => 'lib/GD/SecurityImage.pm',
    'PREREQ_PM'    => \%prereq,
    ($] >= 5.005 ? (
    'AUTHOR'       => 'Burak Gursoy <burak@cpan.org>',
    'ABSTRACT'     => 'Create a security image with a random string on it',
     ) : ()),
);

sub skip_t {
   my $v = shift;
   return if $v == 3;
   my $file = 'skip_' . (($v == 1) ? 'magick' : 'gd');
   open SKIP, ">" . $file or die "I can not create file: $!";
   print SKIP $file,"\n";
   close SKIP;
}