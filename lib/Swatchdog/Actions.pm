package Swatchdog::Actions;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
require Exporter;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
             ring_bell
	     echo
             exec_command
	     send_message_to_pipe
);
$VERSION = '20060502';

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

################################################################
# "bell" action
#
# ring_bell(args) -- ring the terminal bell some number 
#    of times (default is 1)
################################################################
use Time::HiRes qw(sleep);
sub ring_bell {
  my %args = (
              'RINGS' => 1,
              'DELAY' => 0.2,
              @_
             );
  
  return if exists($args{'WHEN'}) and not inside_time_window($args{'WHEN'});

  return if (exists($args{'THRESHOLDING'})
	     and $args{'THRESHOLDING'} eq 'on'
	     and not &Swatchdog::Threshold::threshold(%args));
  
  my $bells = $args{'RINGS'};
  for ( ; $bells > 0 ; $bells-- ) {
    print "\a";
    sleep($args{'DELAY'});
  }
}

################################################################
# "echo" Action
################################################################
use Term::ANSIColor;
sub echo {
  my %args = (
              'MODES' => [ ],
              @_
             );
  return if (exists($args{'WHEN'}) and not inside_time_window($args{'WHEN'}));

  return if (exists($args{'THRESHOLDING'})
	     and $args{'THRESHOLDING'} eq 'on'
	     and not &Swatchdog::Threshold::threshold(%args));
  
  if (${$args{'MODES'}}[0] =~ /^normal$/i) { # for backward compatability
    print "$args{'MESSAGE'}\n";
  } else {
    print colored("$args{'MESSAGE'}\n", @{$args{'MODES'}});
  }
}

################################################################
# "exec" Action
#
# exec_command(args) -- fork and execute a command
################################################################
use POSIX ":sys_wait_h";

sub exec_command {
  my %args = (@_);
  my $exec_pid;
  my $command;

  if (exists $args{'COMMAND'}) {
    $command = $args{'COMMAND'};
  } else {
    warn "$0: No command was specified in exec action.\n";
    return 1;
  }

  return 0 if exists($args{'WHEN'}) and not inside_time_window($args{'WHEN'});

  return if (exists($args{'THRESHOLDING'})
	     and $args{'THRESHOLDING'} eq 'on'
	     and not &Swatchdog::Threshold::threshold(%args));

 EXECFORK: {
    if ($exec_pid = fork) {
      waitpid($exec_pid, 0);
      return 0;
    } elsif (defined $exec_pid) {
      exec($command);
      } elsif ($! =~ /No more processes/) {
        # EAGAIN, supposedly recoverable fork error
        sleep 5;
        redo EXECFORK;
      } else {
        warn "$0: Can't fork to exec $command: $!\n";
        return 1;
      }
  }
  return 0;
}

################################################################
# "mail" Action
#
# send_email -- send some mail using $MAILER.
#
# usage: &send_email(%options);
#
################################################################

sub send_email {
  my $login = (getpwuid($<))[0];
  my %args = (
              'ADDRESSES' => $login,
              'SUBJECT' => 'Message from Swatchdog',
              @_
             );

  return if exists($args{'WHEN'}) and not inside_time_window($args{'WHEN'});

  return if (exists($args{'THRESHOLDING'})
	     and $args{'THRESHOLDING'} eq 'on'
	     and not &Swatchdog::Threshold::threshold(%args));

  if (! $args{'MAILER'} ) {
    foreach my $mailer (qw(/usr/lib/sendmail /usr/sbin/sendmail)) {
      $args{'MAILER'} = $mailer if ( -x $mailer );
    }
    if ($args{'MAILER'} ne '') {
      $args{'MAILER'} .= ' -oi -t -odq';
    }
  }

  (my $to_line = $args{'ADDRESSES'}) =~ s/:/,/g;

  local $SIG{CHLD} = 'default';
  open(MAIL_PIPE, "| $args{'MAILER'}") 
    or (warn "$0: cannot open pipe to $args{MAILER}: $!\n" and  return);

  print MAIL_PIPE <<"EOF";
To: $to_line
Subject: $args{SUBJECT}

$args{'MESSAGE'}
EOF

  close(MAIL_PIPE);
}

################################################################
# "pipe" Action
#
# send_message_to_pipe -- send text to a pipe.
#
# usage: &send_message_to_pipe(
#               $program_to_pipe_to_including_the_vertical_bar_symbol,
#               $message_to_send_to_the_pipe);
# 
################################################################
{
  my $pipe_is_open;
  my $current_command_name;

  sub send_message_to_pipe {
    my %args = (@_);
    my $command;

    if (exists $args{'COMMAND'}) {
      $command = $args{'COMMAND'};
    } else {
      warn "$0: No command was specified in pipe action.\n";
      return;
    }

    return if exists($args{'WHEN'}) and not inside_time_window($args{'WHEN'});

    return if (exists($args{'THRESHOLDING'})
	       and $args{'THRESHOLDING'} eq 'on'
	       and not &Swatchdog::Threshold::threshold(%args));

    # open a new pipe if necessary
    if ( !$pipe_is_open or $current_command_name ne $command ) {
      # first close an open pipe
      close(PIPE) if $pipe_is_open;
      $pipe_is_open = 0;
      open(PIPE, "| $command") 
        or warn "$0: cannot open pipe to $command: $!\n" && return;
      PIPE->autoflush(1);
      $pipe_is_open = 1;
      $current_command_name = $command;
    }
    # send the text
    print PIPE "$args{'MESSAGE'}";

    if (not exists $args{'KEEP_OPEN'}) {
      close(PIPE) if $pipe_is_open;
      $pipe_is_open = 0;
    }
  }

  #
  # close_pipe_if_open -- used at the end of a script to close a pipe
  #     opened by &pipe_it().
  #
  # usage: &close_pipe_if_open();
  #
  sub close_pipe_if_open {
    if ($pipe_is_open) {
      close(PIPE);
    }
  }
}


################################################################
# "write" Action
#
# write_message -- send a message logged on users.
#
################################################################
sub write_message {
  my %args = (WRITE => '/usr/bin/write',
	      @_);

  return if exists($args{'WHEN'}) and not inside_time_window($args{'WHEN'});

  return if (exists($args{'THRESHOLDING'})
	     and $args{'THRESHOLDING'} eq 'on'
	     and not &Swatchdog::Threshold::threshold(%args));

  if ($args{WRITE} eq '') {
    warn "ERROR: $0 cannot find the write(1) program\n";
    return;
  }

  if (exists($args{'USERS'})) {
    foreach my $user (split(/:/, $args{'USERS'})) {
      send_message_to_pipe(COMMAND => "$args{'WRITE'} $user 2>/dev/null", 
                           MESSAGE => "$args{'MESSAGE'}\n");
    }
  }
}

################################################################
# in_range($range, $number) 
# returns 1 if $number is inside $range, 0 if not
#
################################################################
sub in_range {
  my $range = shift;
  my $num = shift;

  foreach my $f (split(/,/, $range)) {
    if ($f =~ /-/) {
      my ($low,$high) = split(/-/, $f);
      return 1 if ($low <= $num and $num <= $high);
    } elsif ($f == $num) {
      return 1;
    }
  }
  return 0;
}

################################################################
# inside_time_window($days,$hours)
# returns 1 if inside window, 0 if outside window
#
################################################################
sub inside_time_window {
  my $range = shift;
  my($days, $hours) = split(/:/, $range);

  my ($hr, $wday) = (localtime(time))[2,6];

  if (($days eq '*' or in_range($days, $wday))
      and ($hours eq '*' or in_range($hours, $hr))) {
    return 1;
  } else {
    return 0;
  }
}


1;

__END__

################################################################
# Perl Documentation
################################################################

=head1 NAME

Swatchdog::Actions - actions for swatchdog(1)

=head1 SYNOPSIS

  use Swatchdog::Actions

  ring_bell(RINGS => $number_of_times_to_ring,
            DELAY => $delay_in_seconds,
            WHEN => $time_window);

  echo(MESSAGE => 'some text', MODES => @modes);

  exec(COMMAND => $command_string,
       WHEN => $time_window);


=head1 DESCRIPTION

=head1 AUTHOR

E. Todd Atkins - Todd.Atkins@StanfordAlumni.ORG

=head1 SEE ALSO

swatchdog(1), Term::ANSIColor(1), perl(1).

=cut
