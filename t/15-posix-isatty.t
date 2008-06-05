use warnings;
use strict;

use Test::More qw(no_plan);

use POSIX qw(isatty);

BEGIN {
    use_ok("Test::MockTerm");
}

open my $file, "<", $0;
ok(!isatty($file), "regular file is not a tty");

close $file;

my $mock = Test::MockTerm->new;
$mock->bind($0);

open $file, "<", $0;
ok(isatty($file), "mocked term is a tty");
