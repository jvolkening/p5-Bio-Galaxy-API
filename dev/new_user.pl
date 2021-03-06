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

say "adding user...";
my $usr = $ua->new_user(
    user     => 'john-doe',
    email    => 'jdoe@base2bio.com',
    password => 'jdjdjd9',
);

print Dumper $usr;
