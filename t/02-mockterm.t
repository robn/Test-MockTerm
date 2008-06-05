use warnings;
use strict;

#use Test::More tests => 14;
use Test::More qw(no_plan);

my $dev = "/dev/term";
my $dev2 = "-";

BEGIN {
    use_ok("Test::MockTerm");
}

my $term = Test::MockTerm->new($dev);

open my ($in), "<", $dev;
isa_ok($in, "GLOB", "read handle");

open my ($out), ">", $dev;
isa_ok($out, "GLOB", "write handle");

is($in, $out, "and they're the same");

open my ($in2), "<", $dev;
is($in, $in2, "opening again for read returns the same object");

open my ($out2), ">", $dev;
is($out, $out2, "and for write");

undef $in2;
open $in2, "<$dev";
is($in, $in2, "two argument form for reads returns the same object");

undef $out2;
open $out2, ">$dev";
is($out, $out2, "and for write");

undef $in2; undef $out2;

#ok(-t $in, "read handle appears to be connected to a terminal");
#ok(-t $out, "and so does write");

print $term "flurble\n";
my $read = <$in>;
is($read, "flurble\n", '"typing" stuff appears on the other end');

my $echoed = <$term>;
is($echoed, "flurble\n", "and gets echoed back");

print $out "wibble\n";
my $written = <$term>;
is($written, "wibble\n", 'stuff written by the other end gets onto the "screen"');

close $in;
close $out;
undef $term;

$term = Test::MockTerm->new($dev, $dev2);

open $in, "<", $dev;
open $in2, "<", $dev2;

is(fileno $in, fileno $in2, "overriding multiple files then opening returns the same (underlying) handle");
