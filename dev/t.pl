use strict;
use warnings;

use API::Galaxy;
use List::Util qw/first/;
use Data::Dumper;
use Cwd qw/abs_path/;

my $ua = API::Galaxy->new(
    url => 'http://localhost:8080',
    check_secure => 0,
);

my $lib = 'foo@bar.net';
my $new_file = 'user/project_01/test.fa';
die "regular file not found\n"
    if (! -f $new_file);


my @dirs = split /\//, $new_file;
my $file = pop @dirs;


my @libs = $ua->libraries()
    or die "no libs found!\n";;
my $want = first {$_->name() eq $lib} @libs;

if (defined $want) {

    my @contents = $want->contents();
    my $leaf = first {$_->name() eq '/'} @contents;
    die "root not found\n" if (! defined $leaf);

    for (0..$#dirs) {
        my $root = $dirs[$_];
        my $root_path = '/' . join '/', @dirs[0..$_];
        my @contents = $want->contents();
        warn "comparing $root_path against" . join(',', map {$_->name()} @contents) . "\n";
        my $new_leaf = first {$_->name() eq $root_path} @contents;
        if (! defined $new_leaf) {
            warn "add folder $root\n";
            $new_leaf = $want->add_folder($leaf->id() => $root)
                or die "Error adding folder\n";
        }
        $leaf = $new_leaf;
    }
    warn "adding file $file\n";
    my $f = $want->add_file($leaf->id() => $file, abs_path($new_file))
        or die "Error adding file\n";

}

