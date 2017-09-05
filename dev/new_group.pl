#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;

use Bio::Galaxy::API;

my $ua = Bio::Galaxy::API->new(
    url => 'http://localhost:8080',
    check_secure => 0,
);

my $name = $ARGV[0] // die "no name specified!\n";

my $grp = $ua->new_group(name => $name);
say "\t", $grp->id, "\t", $grp->name;

