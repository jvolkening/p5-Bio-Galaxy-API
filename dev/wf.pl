use strict;
use warnings;

use Bio::Galaxy::API;
use List::Util qw/first/;
use Data::Dumper;

my $ua = Bio::Galaxy::API->new(
    url => 'http://localhost:8080',
    check_secure => 0,
);


my @wfs = $ua->workflows()
    or die "no workflows found!\n";;

for my $wf (@wfs) {
    print Dumper $wf;
    print "-------------------------\n";
    print Dumper $wf->description();
    print "=========================\n";
}

