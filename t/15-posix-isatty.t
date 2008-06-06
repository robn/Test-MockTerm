use warnings;
use strict;

use Test::More qw(no_plan);

use POSIX ();

BEGIN {
    use_ok("Test::MockTerm");
}

open my $file, "<", $0;
ok(!POSIX::isatty($file), "regular file is not a tty");

close $file;

my $mock = Test::MockTerm->new;
$mock->bind($0);

open $file, "<", $0;
ok(POSIX::isatty($file), "mocked term is a tty");