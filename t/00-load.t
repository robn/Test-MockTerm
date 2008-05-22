#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::MockTerm' );
}

diag( "Testing Test::MockTerm $Test::MockTerm::VERSION, Perl $], $^X" );
