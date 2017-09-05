#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;

use Bio::Galaxy::API;

my $ua = Bio::Galaxy::API->new(
    url => 'http://localhost:8080',
    check_secure => 0,
);

my @groups = $ua->groups;

for my $g (@groups) {
    say $g->id, "\t", $g->name;
    for my $u ($g->users) {
        say "\t", $u->id, "\t", $u->email;
    }

}

