use strict;
use warnings;

use API::Galaxy;
use List::Util qw/first/;
use Data::Dumper;

my $ua = API::Galaxy->new(
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

