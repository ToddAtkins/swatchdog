package Swatchdog::Threshold;
require 5.000;
require Exporter;

use strict;
use Carp;
use Date::Calc;
use Date::Manip;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

@ISA = qw(Exporter);
@EXPORT = qw/
  threshold
/;
$VERSION = '20060721';

#
# $thresholds = ( # List of Hashes
#	<swid1> => { # swatchdog ID generated for each "watchfor" value
#          	<key1> =>  { # TRACK_BY value
#                       FIRST => seconds # time of first instance of this key
#                       EVENTS => <int>,  # num of logs seen since last report
#                       },
#		<key2> => {
#			...
#			}, 
#		...
#             	},
#	<swid2> => {
#		...
#		},
#	...
#             );
my $thresholds = {};
my $debug = 1;

################################################################
# threshold() - 
################################################################
sub threshold {
  my %opts = (
	      SWID => '0',
	      DEBUG => 0,
	      # TYPE
	      # TRACK_BY
	      # COUNT
	      # SECONDS
	      @_
	     );
  my ($takeAction,$doNothing) = (1,0);
  my $withinInterval = 1;
  my $time = time();
  my $endOfInterval = 0;

  if (exists($thresholds->{$opts{SWID}})
      and exists($thresholds->{$opts{SWID}}{$opts{TRACK_BY}})) {
    $endOfInterval = $thresholds->{$opts{SWID}}{$opts{TRACK_BY}}{FIRST} + $opts{SECONDS};
    $withinInterval = ($endOfInterval > $time) ? 1 : 0;
  }

  ####### TYPE is LIMIT #######

  if ($opts{TYPE} eq 'limit') {
    #
    # Alert on the 1st COUNT events during the time interval, then ignore events
    # for the rest of the time interval.
    #
    if (exists($thresholds->{$opts{SWID}}{$opts{TRACK_BY}})) {
      if ($thresholds->{$opts{SWID}}{$opts{TRACK_BY}}{EVENTS} < $opts{COUNT}) {
        $thresholds->{$opts{SWID}}{$opts{TRACK_BY}}{EVENTS}++;
        return $takeAction;
      } elsif (not $withinInterval) {
        $thresholds->{$opts{SWID}}{$opts{TRACK_BY}}{EVENTS} = 1;
        $thresholds->{$opts{SWID}}{$opts{TRACK_BY}}{FIRST} = $time;
        return $takeAction;
      } else {
        return $doNothing;
      } 
    } else {
      add_threshold(%opts);
      return $takeAction;
    }

  ####### TYPE is THRESHOLD #######

  } elsif ($opts{TYPE} eq 'threshold') {
    #
    # Alert every COUNT times we see this event during the time interval.
    #
    if (exists($thresholds->{$opts{SWID}}{$opts{TRACK_BY}})) {
      $thresholds->{$opts{SWID}}{$opts{TRACK_BY}}{EVENTS}++;
      if ($withinInterval) {
	if ($thresholds->{$opts{SWID}}{$opts{TRACK_BY}}{EVENTS} == $opts{COUNT}) {
          $thresholds->{$opts{SWID}}{$opts{TRACK_BY}}{EVENTS} = 0;
          return $takeAction;
        } else {
	  return $doNothing;
        }
      } else { ### not $withinInterval ###
	$thresholds->{$opts{SWID}}{$opts{TRACK_BY}}{FIRST} = $time;
        $thresholds->{$opts{SWID}}{$opts{TRACK_BY}}{EVENTS} = 1;
      }
    } else {
      add_threshold(%opts);
    }

    if ($opts{COUNT} == 1) {
      $thresholds->{$opts{SWID}}{$opts{TRACK_BY}}{EVENTS} = 0;
      return $takeAction;
    } else {
      return $doNothing;
    }

  ####### TYPE is BOTH #######

  } elsif ($opts{TYPE} eq 'both') {
    #
    # Alert once per time interval after seeing COUNT occurrences of the event,
    # then ignore any additional events during the time interval.
    #
    if (exists($thresholds->{$opts{SWID}}{$opts{TRACK_BY}})) {
      $thresholds->{$opts{SWID}}{$opts{TRACK_BY}}{EVENTS}++;
      if ($withinInterval and
          $thresholds->{$opts{SWID}}{$opts{TRACK_BY}}{EVENTS} == $opts{COUNT}) {
        return $takeAction;
      } elsif (not $withinInterval) {
        $thresholds->{$opts{SWID}}{$opts{TRACK_BY}}{EVENTS} = 1;
        $thresholds->{$opts{SWID}}{$opts{TRACK_BY}}{FIRST} = $time;
      }
    } else {
      add_threshold(%opts);
    }

    if ($thresholds->{$opts{SWID}}{$opts{TRACK_BY}}{EVENTS} == $opts{COUNT}) {
      return $takeAction;
    } else {
      return $doNothing;
    }

  ####### TYPE is incorrectly defined #######
  } else {
    die "Swatchdog::Threshold - unknown type, $opts{TYPE} given\n";
  }
}

################################################################

sub add_threshold {
  my %opts = (@_);
  my $rec = {};

  $rec->{EVENTS} = 1;
  $rec->{FIRST} = time();
  $thresholds->{$opts{SWID}}{$opts{TRACK_BY}} = $rec;
}

################################################################

## The POD ###

=head1 NAME

  Swatchdog::Threshold - Perl extension for thresholding in swatchdog(1)

=head1 SYNOPSIS

  use Swatchdog::Threshold;

  &Swatchdog::threshold(	SWID => <int>,
			TYPE => <limit|threshold|both>,
			TRACK_BY => <key>, # like an IP addr
			COUNT => <int>,
			SECONDS => <int>
			);


=head1 SWATCH SYNTAX

  threshold track_by=<key>,
     type=<limit|threshold|both>,
     count=<int>,
     seconds=<int>

=head1 DESCRIPTION

  SWID is swatchdog's internal ID number for the watchfor block

  TYPE can be limit, threshold, or both

	Limit - Alert on the 1st COUNT events during the time interval,
	   then ignore events for the rest of the time interval. 

        Threshold - Alert every COUNT times we see this event during the 
	   time interval.

        Both
           Alert once per time interval after seeing COUNT occurrences of the
           event, then ignore any additional events during the time interval.

  SECONDS is the time interval

=head1 AUTHOR

E. Todd Atkins, todd.atkins@stanfordalumni.org

=head1 SEE ALSO

perl(1), swatchdog(1).

=cut
  
1;
