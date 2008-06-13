use warnings;
use strict;

use Test::More qw(no_plan);

use Test::MockTerm;

my $mock = Test::MockTerm->new;
my $master = $mock->master;
my $slave = $mock->slave;

my ($r, $data);

diag("mode: normal");
$mock->mode("normal");

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

$data = "burble";
print $master $data;
$r = <$slave>;
ok(!$r, "incomplete lines written to master don't appear on the slave");

$r = <$master>;
is($r, $data, "but get echoed back to me");

print $master "\n";
$r = <$slave>;
is($r, "$data\n", "sending newline flushes the buffer");

<$master>;  # clear the input buffer

diag("mode: noecho");
$mock->mode("noecho");

$data = "flurble\n";
print $master $data;
$r = <$slave>;
is($r, $data, "stuff written to master appears on slave");

$r = <$master>;
ok(!$r, "but is not echoed back to me");

$data = "wibble\n";
print $slave $data;
$r = <$master>;
is($r, $data, "stuff written to slave appears on master");

$r = <$slave>;
ok(!$r, "but is not echoed back to me");

diag("mode: cbreak");
$mock->mode("cbreak");

$data = "flurble";
print $master $data;
$r = <$slave>;
is($r, $data, "stuff written to master appears on slave immediately");

$r = <$master>;
ok(!$r, "but is not echoed back to me");

$data = "wibble\n";
print $slave $data;
$r = <$master>;
is($r, $data, "stuff written to slave appears on master");

$r = <$slave>;
ok(!$r, "but is not echoed back to me");
