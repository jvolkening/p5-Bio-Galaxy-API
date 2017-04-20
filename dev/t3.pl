use strict;
use warnings;

use Bio::Galaxy::API;
use List::Util qw/first/;
use Data::Dumper;

my $ua = Bio::Galaxy::API->new(
    url => 'http://localhost:8080',
    check_secure => 0,
);


my @libs = $ua->libraries()
    or die "no libs found!\n";;
for my $lib (@libs) {
    print $lib->name(), "\n";
    my @contents = $lib->contents();
    for (@contents) {
        print "\t", $_->name(), "\n";
    }
}

