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

my $user = 'foo@bar.net';
my @users = $ua->users($user);
die "Wrong number of users returned"
    if (scalar(@users) != 1);
$user = $users[0];

print Dumper $user;

say "adding library...";
my $lib = $ua->new_library(
    name        => $user->{email},
    description => 'Personal library for Foo Bar',
    synopsis    => 'short synopsis',
);

$lib->set_permissions(
    access_ids => [$user->{id}],
    manage_ids => [$user->{id}],
    add_ids => [$user->{id}],
) or die "failed to set permissions: $!";

$lib->add_folder(
    path => 'foo/bar/baz/net',
) or die "failed to add folder: $!";


print Dumper $lib;

