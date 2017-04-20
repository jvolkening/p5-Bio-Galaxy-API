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

my @users = $ua->users($ARGV[0]);
my $n = scalar(@users);

#my $key = $users[0]->get_key();
#print "KEY: $key\n";
print Dumper $users[0];
print "----------------------\n";
$users[0]->update();
print Dumper $users[0];
