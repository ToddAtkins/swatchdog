package Swatch::JSON;
require 5.000;
require Exporter;

use strict;
use Carp;
use JSON;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

@ISA = qw(Exporter);
@EXPORT = qw/
  &write_json
/;
$VERSION = '20031118';

################################################################

sub write_json {
    my %opts = ( @_);
    my %data = undef;
    delete $opts{'MESSAGE'};
    while (my ($k, $v) = each(%opts)) {
        if (defined($v) and $k ne 'MESSAGE' and $k ne 'FILENAME') {
            $data{lc($k)} = $v;
        }
    }
    delete $data{''};
    if (exists $opts{"FILENAME"}) {
        if (open(LOGFILE, ">> $opts{'FILENAME'}")) {
            my $json = encode_json \%data; 
            print LOGFILE $json;
            print LOGFILE "\n";
            close LOGFILE 
         } else {
            warn "Couldn't open $opts{'FILENAME'} for writing: $!\n";
         } 
    }
    return 0;
}

################################################################
## The POD ###

=head1 NAME

  Swatch::JSON - Swatch module for writing JSON to a file

=head1 SYNOPSIS

  use Swatch::JSON;

=head1 SWATCH SYNTAX

  write_json filename=</path/to/output>,<field_name1>=<value1>,<field_name2>=<value2>,...
      
=head1 EXAMPLE

  #
  # p0f OS detection
  #
  watchfor /\[(\d+\/\d+\/\d+\s+\d+:\d+:\d+)\].*\|cli=(128\.111\.\d+\.\d+).*\|os=([A-Za-z0-9_. ]+)/
      threshold track_by="$2 $3",type=both,count=1,seconds=3600
	    write_json filename=/var/log/p0f/p0f.json,ts=$1,asset=$2,os=$3
  #
  # p0f NAT Detection
  # 
  watchfor /\[(\d+\/\d+\/\d+\s+\d+:\d+:\d+)\]\s+mod=(ip\s+sharing)\|cli=(128\.111\.\d+\.\d+).*\|reason=([A-Za-z0-9_. ]+)/
      threshold track_by="$2 $3 $4",type=both,count=1,seconds=3600
	    write_json filename=/var/log/p0f/p0f.json,ts=$1,asset=$3,os=$2,reason=$4
  
=head1 AUTHOR

E. Todd Atkins, todd.atkins@stanfordalumni.org

=head1 SEE ALSO

perl(1), swatch(1).

=cut
  
1;
