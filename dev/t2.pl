use strict;
use warnings;

use API::Galaxy;
use List::Util qw/first/;
use Data::Dumper;

my $ua = API::Galaxy->new(
    url => 'http://localhost:8080',
    check_secure => 0,
);

my $lib = 'foo@bar.net';
my $new_file = 'user/project_01/test.fa';
die "regular file not found\n"
    if (! -f $new_file);
$new_file = "/$new_file"
    if ($new_file !~ /^\//);


my @dirs = split /\//, $new_file;
my $file = pop @dirs;


my @libs = $ua->libraries()
    or die "no libs found!\n";;
my $want = first {$_->name() eq $lib} @libs;
my $id = $want->id();
warn "ID: $id\n";

if (defined $want) {
    my @contents = $want->contents();
    print Dumper $_ for (@contents);
}

