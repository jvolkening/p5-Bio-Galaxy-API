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

say "fetching libs...";
my @libs = $ua->libraries();

for (@libs) {
    print Dumper $_;
    print Dumper $_->get_permissions;
}
