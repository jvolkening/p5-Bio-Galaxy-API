#!perl -T
use 5.012;
use strict;
use warnings FATAL => 'all';
use List::Util qw/any/;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

my $trustme = { trustme => [qr/^new$/] };

my @skip = qw/Bio::Galaxy::API::Util/;

for my $mod ( all_modules() ) {

    next if (any {$_ eq $mod} @skip);
    pod_coverage_ok($mod, $trustme);

}

#all_pod_coverage_ok($trustme);

done_testing();

