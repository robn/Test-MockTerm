use warnings;
use strict;

use Test::More qw(no_plan);

use Test::MockTerm;

my $mock = Test::MockTerm->new;
my $master = $mock->master;
my $slave = $mock->slave;

my ($r, $data);

$data = "flurble\n";
print $master $data;
$r = <$slave>;
is($r, $data, "stuff written to master appears on slave");

$r = <$master>;
is($r, $data, "and is echoed back to me");

$data = "wibble\n";
print $slave $data;
$r = <$master>;
is($r, $data, "stuff written to slave appears on master");

$r = <$slave>;
ok(!$r, "but is not echoed back to me");
