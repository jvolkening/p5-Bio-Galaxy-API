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

my $lib = 'foo@bar.net';
my $new_file = 'user2/project_01/test.fa';
die "regular file not found\n"
    if (! -f $new_file);



my @libs = $ua->libraries()
    or die "no libs found!\n";;
my $want = first {$_->name() eq $lib} @libs;
die "no lib found\n" if (! defined $want);

my $new = $want->add_folder(
    path => $ARGV[0],
    parent => $ARGV[1],
);

if ($new) {
    print Dumper $new;
}
elsif (! defined $new) {
    print "Error creating\n";
}
else {
    print "File exists\n";
}
