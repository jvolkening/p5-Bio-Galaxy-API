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
my $new_file_1 = $ARGV[0];
my $new_file_2 = $ARGV[1];
die "regular file 1 not found\n"
    if (! -f $new_file_1);
die "regular file 2 not found\n"
    if (! -f $new_file_2);

my @ids;

for my $fn ($new_file_1, $new_file_2) {

    my @dirs = split /\//, $fn;
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
        @contents = $want->contents();
        my $root_path = '/' . join '/', @dirs, $file;
        my $final_leaf = first {$_->name() eq $root_path} @contents;
        if (! defined $final_leaf) {
            warn "adding file $file\n";
            my $f = $want->add_file($leaf->id() => $file, abs_path($fn))
                or die "Error adding file\n";
            push @ids, $f->id();
        }
        else {
            warn "file $file already exists\n";
            push @ids, $final_leaf->id();
        }

    }

}

die "Bad id number\n" if (scalar(@ids) != 2);

my $wf_id = 'f2db41e1fa331b3e';

my @wfs = $ua->workflows()
    or die "no workflows found!\n";;

my $wf = first {$_->id() eq $wf_id} @wfs;

die "workflow not found\n" if (! defined $wf);

my $ret = $wf->run(
    workflow_id => $wf_id,
    history     => 'test_run_ABC',
    ds_map      => {
        0 => {
            id => $ids[0],
            src => 'ld'
        },
        1 => {
            id => $ids[1],
            src => 'ld'
        }
    }
);

while (1) {
    print "$ret->{state}\n";
    sleep 5;
    $ret->update();
}
