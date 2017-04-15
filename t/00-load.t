#!perl -T
use 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'API::Galaxy' ) || print "Bail out!\n";
}

diag( "Testing API::Galaxy $API::Galaxy::VERSION, Perl $], $^X" );
