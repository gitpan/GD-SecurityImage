#!/usr/bin/perl -w
# -> GD::SecurityImage demo program
# -> Burak Gürsoy
package demo;
use strict;
use vars qw[$VERSION %config];
use Cwd;

$VERSION = "1.11";

%config = (
   database   => 'gdsi',                 # database name (for session storage)
   table_name => 'sessions',             # only change this value, if you *really* have to use another table name. Also change the SQL code below.
   user       => 'root',                 # database user name
   pass       => '',                     # database user's password
   font       => getcwd."/StayPuft.ttf", # ttf font
   itype      => 'gif',                  # image format. set this to gif or png or jpeg
   use_magick => 0,                      # use Image::Magick or GD
   img_stat   => 1,                      # display statistics on the image?
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
   $test->($_) foreach qw[DBI DBD::mysql Apache::Session::MySQL String::Random GD::SecurityImage Time::HiRes];
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

run() unless caller;

sub run {
   my $START = Time::HiRes::time();
   my $self = bless {}, __PACKAGE__;
   import GD::SecurityImage use_magick => $config{use_magick};

   $self->{cgi} = CGI->new;
   $self->{program} = $self->{cgi}->url;my @jp;($self->{program},@jp) = split /\?/, $self->{program};
   my %options = $self->all_options;
   my %styles  = $self->all_styles;
   $self->{CPAN} = "http://search.cpan.org/dist";

   my @optz = keys %options;
   my @styz = keys %styles;

   $self->{rnd_opt} = $options{$optz[int rand @optz]};
   $self->{rnd_sty} = $styles{ $styz[int rand @styz]};

   # our database handle
   my $dbh = DBI->connect("DBI:mysql:$config{database}", $config{user}, $config{pass}, {RaiseError => 1});

   my %session;
   my $create_ses = sub { # fetch/create session
      tie %session, 'Apache::Session::MySQL', @_ ? undef : ($self->{cgi}->cookie('GDSI_ID') || undef), {
         Handle     => $dbh,
         LockHandle => $dbh,
         TableName  => $config{table_name},
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

   my $display = $self->{cgi}->param('display');
   my $process = $self->{cgi}->param('process');
   my $help    = $self->{cgi}->param('help');
   my $output  = "";

   my $HEADER = sub {
      my %o = @_;
      $self->{cgi}->header(
         -type   => $o{type} ? $o{type} : ($display ? 'image/'.$config{itype} : 'text/html'), 
         -cookie => $self->{cgi}->cookie(-name => 'GDSI_ID',
                                 -value => $session{_session_id})
   )};

   $output = $HEADER->() . $self->html_head unless $display;

   if($process) {
      my $code = $self->{cgi}->param('code');
      if ($code and $code !~ m{[^0-9]} and $code eq $session{security_code}) {
         $output .= qq~<b>'$code' == '$session{security_code}'</b><br>Congratulations! You have passed the test!<br><br><a href="$self->{program}">Try again</a>~;
      } else {
         $code    = CGI::escapeHTML($code);
         $output .= qq~<b>'$code' != '$session{security_code}'</b><br><span style="color:red;font-weight:bold">You have failed to identify yourself as a human!</span><br>~.form();
      }
   } elsif ($help) {
      $output .= $self->help;
   } elsif ($display) {
      my($image, $mime, $random) = $self->create_image($session{security_code}, $START = Time::HiRes::time());
      $output  = $HEADER->(type => "image/$mime");
      $output .= $image;
   } else {
      $output .= form();
   }

   unless($display) { # don't do these if we are displaying the image.
      # make the code always random
      $session{security_code} = String::Random->new->randregex('\d\d\d\d\d\d');
      $output .= "<p>Security image generated with <b>";
      $output .= defined($GD::VERSION)
                 ? qq~<a href="$self->{CPAN}/GD"         target="_blank">GD</a> v$GD::VERSION~ 
                 : qq~<a href="$self->{CPAN}/PerlMagick" target="_blank">Image::Magick</a> v$Image::Magick::VERSION~;
      my $bench = sprintf "Execution time: %.3f seconds", Time::HiRes::time() - $START;
      $output .= qq*</b>
      <span class="small"> | <a href   = "http://search.cpan.org/~burak"
         target = "_blank">\$CPAN/Burak G&uuml;rsoy</a> | $bench | <a href="#" onClick="javascript:help()">?<a/></span>
      </p>
      </body>
      </html>*;
   }

   untie %session;
   $dbh->disconnect;
   print $output;
   exit;
}

#--------------> FUNCTIONS <--------------#

sub help {
   my $self = shift;
   qq~

If you want to change the image generation options, open this file with
a text editor and search for the <b>%config</b> hash.
Database options are used to access to a MySQL Database Server. MySQL is
used for session data storage.

<table border="1">
<tr><td class="htitle">Parameter</td><td class="htitle">Default</td><td class="htitle">Explanation</td></tr>
<tr><td> database   </td><td><i>gdsi</i></td>
   <td>The database name we will use for session storage</td></tr>
<tr><td> table_name </td><td>sessions</td>
   <td>The name of the table for session storage. 
       Only change this value, if you *really* have to use 
       another table name. Also you must change the table
       generation (SQL) code.</td></tr>
<tr><td> user       </td><td><i>root</i>
   </td><td>Database user name</td></tr>
<tr><td> pass       </td><td><i>&nbsp;</i></td>
   <td>Database password</td></tr>
<tr><td> font       </td><td><i>StayPuft.ttf</i></td>
   <td>TTF font for SecurityImage generation. 
       Put the sample font into the same folder as 
       this program.</td></tr>
<tr><td> itype      </td><td><i>gif</i></td>
   <td>Image format. You can set this to <i>png</i>
   or <i>gif</i> or <i>jpeg</i>.</td></tr>
<tr><td> use_magick </td><td><i>FALSE</i></td>
<td>False value: <b>GD</b> will be used; True value: <b>Image::Magick</b> 
will be used. If you use GD, please do not use a prehistoric version.
The module itself is highly compatible with older versions, but this demo 
needs <b>\$GD::VERSION >= 1.31</b>
</td></tr>
<tr><td> img_stat   </td><td><i>TRUE</i></td>
   <td>If has a true value, some statistics like "image generation" 
   and "total execution" times will be placed on the image. 
   The page you see this also shows that information, 
   but image generation is an <b><i>another</i></b> process and we can only
   show the stats this way. This option uses the minimal amount of space,
   but if you want to cancel it just give it a false value.
</td></tr>
</table>

   ~;
}

sub form {
   my $self = shift;
   qq~<form action="$self->{program}" method="post">
    <table border="0" cellpadding="2" cellspacing="1">
     <tr>
      <td>
       <b>Enter the security code:</b><br>
       <span class="small">to identify yourself as a human</span><br>
        <input type="text"   name="code"    value="" size="10">
              <input type="submit" name="submit"  value="GO!">
       <input type="hidden" name="process" value="true">
      </td>
      <td><img src="$self->{program}?display=1" alt="Security Image"></td>
      <td>
      
      </td>
     </tr>
    </table>
   </form>
   ~
}

sub html_head {
   my $self = shift;
   qq~<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
<html>
   <head>
    <title>GD::SecurityImage v$GD::SecurityImage::VERSION - DEMO v$VERSION</title>
    <style type="text/css">
      body   {
            font-family : Verdana, serif;
            font-size   : 12px;
      }
      a:link    { color : #0066CC; text-decoration : none      }
      a:active  { color : #FF0000; text-decoration : none      }
      a:visited { color : #003399; text-decoration : none      }
      a:hover   { color : #009900; text-decoration : underline }
      .small {font-size:10px}
      .htitle {
      font-weight: bold;
      }
    </style>
    <script language='JavaScript'>

    function help () {
       window.open('$self->{program}?help=1',
                   'HELP',
                   'width=630,height=500,resizable=yes,scrollbars=yes');
    }
    </script>
   </head>
   <body>
    <h2><a href   = "$self->{CPAN}/GD-SecurityImage"
           target = "_blank"
           >GD::SecurityImage</a> v$GD::SecurityImage::VERSION - DEMO v$VERSION</h2>
   ~
}

sub create_image { # create a security image with random options and styles
   my $self  = shift;
   my $code  = shift;
   my $START = shift;
   my $s     = $self->{rnd_sty};
   my $i     = GD::SecurityImage
   ->new(lines   => $s->{lines},
         bgcolor => $s->{bgcolor},
         %{ $self->{rnd_opt} })
   ->random  ($code)
   ->create  (ttf => $s->{name}, $s->{text_color}, $s->{line_color})
   ->particle($s->{dots} ? ($s->{particle},$s->{dots}) 
                         : ($s->{particle})
   );
   if ($config{img_stat}) {
      $i->set_tl(x      => 'right',
                 y      => 'up',
                 gd     => 1,
                 strip  => 1,
                 color  => "#000000",
                 scolor => "#FFFFFF",
                 ptsize => $i->{IS_MAGICK} ? 12 : 8,
                 text   => sprintf "Security Image generated at %.3f seconds", Time::HiRes::time() - $START,
      )->insert_text('ttf');
   }
   my @image = $i->out(force => $config{itype});
   return @image;
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
      width      => 360,
      height     => 100,
      send_ctobg => 1,
      font       => $config{font},
      ptsize     => 25,
      scramble   => 1,
   },
   gd_ttf_scramble_fixed =>  {
      width      => 360,
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
      height     => 100,
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
   Time::HiRes

Also, be sure to use recent versions of GD. This demo needs at least
version 1.31 of GD. And if you want to use C<Image::Magick> it must 
be C<6.0.4> or newer.

You'll also need a MySQL server to run the program. You must create 
a table with this SQL code:

   CREATE TABLE sessions (
      id char(32) not null primary key,
      a_session text
   );

If you want to use another table name (not C<sessions>), set the 
C<$config{table_name}> to the value you want and also modify the 
C<SQL> code above.

Security images are generated with the sample ttf font "StayPuft.ttf".
Put it into the same folder as this program of alter C<$config{font}> value.
If you want to use another font file, you may need to alter the image 
generation options (see the C<%config> hash on top of the program code).

Note that this is only a demo, no security checks are performed. And it may 
not be secure or memory friendly.

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
