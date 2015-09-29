package Swatchdog::SendMail;
require 5.000;
require Exporter;

use strict;
use Carp;
use Mail::Sendmail;
use Sys::Hostname;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

@ISA = qw(Exporter);
@EXPORT = qw/
  &send_mail
/;
$VERSION = '20031118';

################################################################

sub send_mail {
  my $login = (getpwuid($<))[0];
  my $host = hostname;
  my %opts = (
              'ADDRESSES' => $login,
              'FROM' => "$login\@$host",
              'SUBJECT' => 'Message from Swatchdog',
	      @_
  );

  (my $to_line = $opts{'ADDRESSES'}) =~ s/:/,/g;

  my %mail = ( To => $to_line,
               From => $opts{FROM},,
	       Subject => $opts{SUBJECT},
	       Message => $opts{MESSAGE},
  );
  sendmail(%mail) or warn $Mail::Sendmail::error;
  return 0;
}

################################################################
## The POD ###

=head1 NAME

  Swatchdog::SendMail - Swatchdog interface to the Mail::Sendmail module

=head1 SYNOPSIS

  use Swatchdog::SendMail;

=head1 SWATCH SYNTAX

=head1 DESCRIPTION

=head1 AUTHOR

E. Todd Atkins, todd.atkins@stanfordalumni.org

=head1 SEE ALSO

perl(1), swatchdog(1).

=cut
  
1;
