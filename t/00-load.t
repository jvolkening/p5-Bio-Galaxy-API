#!perl -T
use 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Bio::Galaxy::API' ) || print "Bail out!\n";
}

diag( "Testing Bio::Galaxy::API $Bio::Galaxy::API::VERSION, Perl $], $^X" );
