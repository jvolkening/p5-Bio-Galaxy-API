use strict;
use warnings;

use Bio::Galaxy::API;
use List::Util qw/first/;
use Data::Dumper;

my $ua = Bio::Galaxy::API->new(
    url => 'http://localhost:8080',
    check_secure => 0,
);

my $lib = 'foo@bar.net';

my @libs = $ua->libraries()
    or die "no libs found!\n";;
my $want = first {$_->name() eq $lib} @libs;
my $id = $want->id();

if (defined $want) {
    my @contents = $want->contents();
    print Dumper $_ for (@contents);
}

