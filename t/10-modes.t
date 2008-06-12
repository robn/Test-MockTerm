use warnings;
use strict;

use Test::More qw(no_plan);
use Test::Exception;

use Test::MockTerm;

my $mock = Test::MockTerm->new;
my $master = $mock->master;
my $slave = $mock->slave;

is($mock->mode, "normal", "term starts in normal (cooked) mode");



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
