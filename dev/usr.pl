use strict;
use warnings;

use Bio::Galaxy::API;
use List::Util qw/first/;
use Data::Dumper;
use Cwd qw/abs_path/;

my $ua = Bio::Galaxy::API->new(
    url => 'http://localhost:8080',
    check_secure => 0,
);

my @users = $ua->users('foo@bar.net')
    or die "no user found!\n";;
print Dumper $_ for (@users);

#my $key = $users[0]->get_key();
#print "KEY: $key\n";
my $desc = $users[0]->description();
print Dumper $desc;
