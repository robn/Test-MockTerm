use warnings;
use strict;

use Test::More qw(no_plan);

BEGIN {
    use_ok("Test::MockTerm");
}

my $mock = Test::MockTerm->new;
isa_ok($mock, "Test::MockTerm", "mockterm object returned by constructor");

my $master = $mock->master;
isa_ok($master, "GLOB", "master is a filehandle");

my $slave = $mock->slave;
isa_ok($master, "GLOB", "slave is a filehandle");

undef $mock;

ok(!defined(tied *$master), "master not tied after mockterm object destruction");
ok(!defined(tied *$slave), "slave not tied after mockterm object destruction");
