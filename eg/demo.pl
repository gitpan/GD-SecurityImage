#!/usr/bin/perl -w
# -> GD::SecurityImage demo program
# -> Burak Gürsoy
use strict;
use vars qw[$VERSION];
use Cwd;

$VERSION = "1.0";

my %config = (
   database   => 'gdsi',                 # database name (for session storage)
   user       => 'root',                 # database user name
   pass       => '',                     # database user's password
   font       => getcwd."/StayPuft.ttf", # ttf font
   itype      => 'jpeg',                 # image format. set this to gif or png, if you get errors.
   use_magick => 0,                      # use Image::Magick or GD
);

# you'll need this to create the sessions table. 
#
#CREATE TABLE sessions (
#   id char(32) not null primary key,
#   a_session text
#);

BEGIN {
   use CGI::Carp qw[fatalsToBrowser];
   use CGI       qw[header escapeHTML];
   my @errors;
   my $test = sub { eval "require ".$_[0]; push @errors, [$_[0], $@] if $@};
   $test->($_) foreach qw[DBI DBD::mysql Apache::Session::MySQL String::Random GD::SecurityImage];
   if (@errors) {
      my $err = header;
      $err .= "<pre>This demo program needs several CPAN modules to run:\n\n";
      $err .= qq~<b><span style="color:red">[FAILED]</span> $_->[0]</b>: $_->[1]<br>~ foreach @errors;
      $err .= '</pre>';
      print $err;
      exit;
   }
}

#--------------> START PROGRAM <--------------#

import GD::SecurityImage use_magick => $config{use_magick};

my $cgi     = CGI->new;
my $program = $cgi->url;
my %options = all_options();
my %styles  = all_styles();

my @optz = map {$_} keys %options;
my @styz = map {$_} keys %styles;

my $rnd_opt = $options{$optz[int rand @optz]};
my $rnd_sty = $styles{ $styz[int rand @styz]};

# our database handle
my $dbh = DBI->connect("DBI:mysql:$config{database}", $config{user}, $config{pass}, {RaiseError => 1});

my  %session;
my $create_ses = sub { # fetch/create session
   tie %session, 'Apache::Session::MySQL', @_ ? undef : ($cgi->cookie('GDSI_ID') || undef), {
      Handle     => $dbh,
      LockHandle => $dbh,
   };
};
eval {$create_ses->()};

# I'm doing a little trick to by-pass exceptions if the session id
# coming from the user no longer exists in the database. 
# Also, I'm not validating the session key here, you can also check
# IP and browser string to validate the session. But, this is beyond this demo...
$create_ses->('new') if $@ and $@ =~ m[^Object does not exist in the data store];

unless ($session{security_code}) { # initialize random code
   $session{security_code} = String::Random->new->randregex('\d\d\d\d\d\d');
}

my $display = $cgi->param('display');
my $process = $cgi->param('process');
my $output  = $cgi->header(-type => $display ? 'image/'.$config{itype} : 'text/html', -cookie => $cgi->cookie(-name => 'GDSI_ID', -value => $session{_session_id}));
   $output .= html_head() unless $display;

if($process) {
   my $code = $cgi->param('code');
   if ($code and $code !~ m{[^0-9]} and $code eq $session{security_code}) {
      $output .= qq~<b>'$code' == '$session{security_code}'</b><br>Congratulations! You have passed the test!<br><br><a href="$program">Try again</a>~;
   } else {
      $code    = escapeHTML $code;
      $output .= qq~<b>'$code' != '$session{security_code}'</b><br><span style="color:red;font-weight:bold">You have failed to identify yourself as a human!</span><br>~.form();
   }
} elsif ($display) {
   $output .= create_image();
} else {
   $output .= form();
}

unless($display) { # make the code always random
   $session{security_code} = String::Random->new->randregex('\d\d\d\d\d\d');
   $output .= "<p>Security image generated with <b>";
   $output .= defined($GD::VERSION) ? "GD v$GD::VERSION" : "Image::Magick v$Image::Magick::VERSION";
   $output .= "</b></p>";
}

untie %session;
print $output;

#--------------> FUNCTIONS <--------------#

sub form {qq~
   <form action="$program" method="post">
    <table border="0" cellpadding="2" cellspacing="1">
     <tr>
      <td>
       <b>Enter the security code:</b><br>
       <span class="small">to identify yourself as a human<br>
        <input type="text"   name="code"    value="" size="10">
              <input type="submit" name="submit"  value="GO!">
       <input type="hidden" name="process" value="true">
      </td>
      <td><img src="$program?display=1" alt="Security Image"></td>
      <td>
      
      </td>
     </tr>
    </table>
   </form>
   ~
}

sub html_head {
   qq~<html>
   <head>
    <title>GD::SecurityImage v$GD::SecurityImage::VERSION - DEMO v$VERSION</title>
    <style>
      body   {
            font-family : Verdana, serif;
            font-size   : 12px;
      } 
      .small {font-size:10px}
    </style>
   </head>
   <body>
    <h2>GD::SecurityImage v$GD::SecurityImage::VERSION - DEMO v$VERSION</h2>
   ~
}

sub create_image { # create a security image with random options and styles
   my @image = GD::SecurityImage
   ->new(lines   => $rnd_sty->{lines}, 
         bgcolor => $rnd_sty->{bgcolor},
         %{ $rnd_opt })
   ->random  ($session{security_code})
   ->create  (ttf => $rnd_sty->{name}, $rnd_sty->{text_color}, $rnd_sty->{line_color})
   ->particle($rnd_sty->{dots} ? ($rnd_sty->{particle},$rnd_sty->{dots}) 
                               : ($rnd_sty->{particle})
   )
   ->out(force => $config{itype});
   return $image[0];
}

# below is taken from the test api "tapi"

sub all_options {
   my %gd = (
   gd_ttf => {
      width      => 210,
      height     => 60,
      send_ctobg => 1,
      font       => $config{font},
      ptsize     => 30,
   },
   gd_ttf_scramble =>  {
      width      => 330,
      height     => 80,
      send_ctobg => 1,
      font       => $config{font},
      ptsize     => 25,
      scramble   => 1,
   },
   gd_ttf_scramble_fixed =>  {
      width      => 330,
      height     => 80,
      send_ctobg => 1,
      font       => $config{font},
      ptsize     => 25,
      scramble   => 1,
      angle      => 30,
   },
   );
   my %magick = (
   magick => {
      width      => 250,
      height     => 80,
      send_ctobg => 1,
      font       => $config{font},
      ptsize     => 50,
   },
   magick_scramble => {
      width      => 350,
      height     => 80,
      send_ctobg => 1,
      font       => $config{font},
      ptsize     => 30,
      scramble   => 1,
   },
   magick_scramble_fixed => {
      width      => 350,
      height     => 80,
      send_ctobg => 1,
      font       => $config{font},
      ptsize     => 30,
      scramble   => 1,
      angle      => 32,
   },
   );
   return defined($GD::VERSION) ? (%gd) : (%magick);
}

sub all_styles {
   ec => {
      name       => 'ec',
      lines      => 16,
      bgcolor    => [ 0,   0,   0],
      text_color => [84, 207, 112],
      line_color => [ 0,   0,   0],
      particle   => 1000,
   },
   ellipse => {
      name       => 'ellipse',
      lines      => 15, 
      bgcolor    => [208, 202, 206],
      text_color => [184,  20, 180],
      line_color => [184,  20, 180],
      particle   => 2000,
   },
   circle => {
      name       => 'circle',
      lines      => 40, 
      bgcolor    => [210, 215, 196],
      text_color => [ 63, 143, 167], 
      line_color => [210, 215, 196],
      particle   => 3500,
   },
   box => {
      name       => 'box',
      lines      => 6,
      text_color => [245, 240, 220],
      line_color => [115, 115, 115],
      particle   => 3000,
      dots       => 2,
   },
   rect => {
      name       => 'rect',
      lines      => 30,
      text_color => [ 63, 143, 167], 
      line_color => [226, 223, 169],
      particle   => 2000,
   },
   default => {
      name       => 'default',
      lines      => 10,
      text_color => [ 68, 150, 125],
      line_color => [255,   0,   0],
      particle   => 5000,
   },
}

__END__

=head1 NAME

demo.pl - GD::SecurityImage demo program.

=head1 SYNOPSIS

This is a CGI program. Run from web.

=head1 DESCRIPTION

This program demonstrates the abilities of C<GD::SecurityImage>.
The program needs these CPAN modules: 

   DBI 
   DBD::mysql
   Apache::Session::MySQL 
   String::Random 
   GD::SecurityImage	(with GD or Image::Magick)

and these CORE modules:

   CGI
   Cwd

You'll also need a MySQL server to run the program.

Security images are generated with the sample ttf font "StayPuft.ttf".
If you want to use another font file, you may need to alter the image 
generation options.

=head1 SEE ALSO

L<GD::SecurityImage>.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
