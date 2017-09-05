#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;

use Bio::Galaxy::API;
use Data::Dumper;

my ($usr, $grp) = @ARGV;

my $ua = Bio::Galaxy::API->new(
    url => 'http://localhost:8080',
    check_secure => 0,
);

my @usrs = $ua->users;
my @grps = $ua->groups;

my @u = grep { $_->email eq $usr } @usrs;
my @g = grep { $_->name eq $grp  } @grps;

die "No matching user found\n"  if (! scalar @u);
die "No matching group found\n" if (! scalar @g);
die "Too many users found\n"   if (scalar @u > 1);
die "Too many groups found\n"  if (scalar @g > 1);

my $new_u = $g[0]->add_user(user => $u[0])
    // die "add failed\n";

say Dumper $new_u;
