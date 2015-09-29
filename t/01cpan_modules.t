
BEGIN { $| = 1; $tx=1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}

use Time::HiRes 1.12;
use Date::Calc;
use Date::Format;
use File::Tail;

$loaded=1;

sub ok { print "ok $tx\n"; $tx++; }
sub not_ok { print "not ok $tx\n"; $tx++; }

ok;

