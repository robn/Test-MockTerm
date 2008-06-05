use warnings;
use strict;

use Test::More qw(no_plan);

BEGIN {
    use_ok("Test::MockTerm");
}

my $dev = "/dev/tty";

my $mock = Test::MockTerm->new;

$mock->bind($dev);

open my $slave, "<", $dev;
isa_ok($slave, "GLOB", "open returns a filehandle");

is($slave, $mock->slave, "open returned the slave handle");
