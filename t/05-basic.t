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

my ($r, $data);

$data = "flurble\n";
print $master $data;
$r = <$slave>;
is($r, $data, "stuff written to master appears on slave");

$data = "wibble\n";
print $slave $data;
$r = <$master>;
is($r, $data, "stuff written to slave appears on master");
