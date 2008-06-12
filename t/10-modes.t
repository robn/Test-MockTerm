use warnings;
use strict;

use Test::More qw(no_plan);
use Test::Exception;

use Test::MockTerm;

my $mock = Test::MockTerm->new;
my $master = $mock->master;
my $slave = $mock->slave;

is($mock->mode, "normal", "term starts in normal (cooked) mode");

$mock->mode("restore");
is($mock->mode, "normal", "restore is a synonym for normal");

$mock->mode("normal");
is($mock->mode, "normal", "setting normal mode works");
$mock->mode("noecho");
is($mock->mode, "noecho", "setting noecho mode works");
$mock->mode("cbreak");
is($mock->mode, "cbreak", "setting cbreak mode works");
$mock->mode("raw");
is($mock->mode, "raw", "setting raw mode works");
$mock->mode("ultra-raw");
is($mock->mode, "ultra-raw", "setting ultra-raw mode works");

$mock->mode(0);
is($mock->mode, "normal", "setting mode 0 sets normal mode");
$mock->mode(1);
is($mock->mode, "normal", "setting mode 1 sets normal mode");
$mock->mode(2);
is($mock->mode, "noecho", "setting mode 2 sets noecho mode");
$mock->mode(3);
is($mock->mode, "cbreak", "setting mode 3 sets cbreak mode");
$mock->mode(4);
is($mock->mode, "raw", "setting mode 4 sets raw mode");
$mock->mode(5);
is($mock->mode, "ultra-raw", "setting mode 5 sets ultra-raw mode");

=pod
my ($r, $data);

$data = "flurble\n";
print $master $data;
$r = <$slave>;
is($r, $data, "stuff written to master appears on slave");

$data = "wibble\n";
print $slave $data;
$r = <$master>;
is($r, $data, "stuff written to slave appears on master");
=cut
