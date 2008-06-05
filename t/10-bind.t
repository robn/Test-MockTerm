use warnings;
use strict;

use Test::More qw(no_plan);

BEGIN {
    use_ok("Test::MockTerm");
}

my $mock = Test::MockTerm->new;

$mock->bind($0);

open my $slave, "<", $0;
isa_ok($slave, "GLOB", "open returns a filehandle");

is($slave, $mock->slave, "open returned the slave handle");

undef $mock;

open $slave, "<", $0;
ok(!defined(tied *$slave), "open returned a regular filehandle");
