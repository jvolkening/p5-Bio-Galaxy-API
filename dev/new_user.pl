use strict;
use warnings;

use Bio::Galaxy::API;
use Data::Dumper;

my $ua = Bio::Galaxy::API->new(
    url => 'http://localhost:8080',
    check_secure => 0,
);

my $usr = $ua->new_user(
    name     => 'john-doe',
    email    => 'jdoe@base2bio.com',
    password => 'jdjdjd9',
);

print Dumper $usr;
