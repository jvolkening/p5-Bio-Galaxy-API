#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;

use Bio::Galaxy::API;
use Data::Dumper;

say "connecting...";
my $ua = Bio::Galaxy::API->new(
    url => 'http://localhost:8080',
    check_secure => 0,
);

say "fetching jobs...";
my @jobs = $ua->jobs();

for (@jobs) {
    print Dumper $_;
}
