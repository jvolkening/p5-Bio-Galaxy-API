#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;

use Bio::Galaxy::API;
use YAML::Tiny;
use Term::ReadKey;
use Term::ReadLine;
use Text::ParseWords;
use List::Util qw/first/;

# initialize terminal session
my $term = Term::ReadLine->new('runner');
$term->ornaments(0);

my $ua = Bio::Galaxy::API->new(
    url => 'http://localhost:8080',
    check_secure => 0,
);

my $yaml = YAML::Tiny->read( $ARGV[0] )->[0]
    or die "Failed to read input YAML: $@";

for (qw/name id library inputs outputs/) {
    die "YAML missing required attribute $_"
        if (! defined $yaml->{$_});
}

say "Running workflow $yaml->{name}";
say '-' x 78;

#-----------------------------------------------------------------------------

say "Gathering inputs:";
my @inputs;
for my $idx (keys %{ $yaml->{inputs} }) {
    my $fn = $term->readline(
        "  $yaml->{inputs}->{$idx}->{description}: "
    );
    chomp $fn;
    die "File |$fn| not found\n" 
        if (! -e $fn);
    push @inputs, [$idx, $fn]
}

#-----------------------------------------------------------------------------

say "Gathering outputs:";
my $outputs;
for my $step (keys %{ $yaml->{outputs} }) {
    for my $name (keys %{ $yaml->{outputs}->{$step} }) {
        my $fn = $term->readline(
            "  $yaml->{outputs}->{$step}->{$name}->{description}: "
        );
        chomp $fn;
        die "File exists!\n" 
            if (-e $fn);

        $outputs->{$step}->{$name} = $fn;
    }
}

#-----------------------------------------------------------------------------

say "Gathering configurables:";
my $params;
for my $step (keys %{ $yaml->{configurable} }) {
    for my $name (keys %{ $yaml->{configurable}->{$step} }) {
        my $val = $term->readline(
            "  $yaml->{configurable}->{$step}->{$name}->{description}: "
        );
        chomp $val;
        $params->{$step}->{$name} = $val;
    }
}

my $ds_map;

my $lib = first {$_->name() eq $yaml->{library}} ($ua->libraries);
$lib // die "Failed to find library with ID $yaml->{library}\n";

my @wfs = $ua->workflows()
    or die "no workflows found!\n";;

my $wf = first {$_->id() eq $yaml->{id}} ($ua->workflows);
$wf // die "Failed to find workflow with Id $yaml->{id}\n";


for my $input (@inputs) {
    
    my ($idx, $fn) = @{ $input };

    my $path = $fn;
    
    my $f = $lib->get_item(path => $path);

    if (! defined $f) {
        warn "adding file $path\n";
        $f = $lib->add_file(
            file    => $path,
            path    => $path,
        ) or die "Error adding file\n";
    }
    $ds_map->{$idx} = {
        src => 'ld',
        id  => $f->id,
    }

}

say '-' x 78;
say "Running...\n";

my $inc = $wf->run(
    history     => $yaml->{name},
    parameters  => $params,
    ds_map      => $ds_map,
);

# wait for final job to complete
my @reported;
while (1) {
    
    my @states = $inc->states;
    for (0..$#states) {
        next if ($reported[$_]);
        next if ($states[$_] eq 'NA');
        if ($states[$_] eq 'ok') {
            say "  Step $_ complete";
            $reported[$_] = 1;
            if (defined $outputs->{$_}) {
                download($_);
            }
        }
    }

    last if ($states[-1] !~ /(new|queued|running)/);
    sleep 3;

}

sub download {

    my ($step) = @_;

    my @jobs = $inc->jobs();;

    my $job = $ua->get_job( $jobs[$step] );

    while (my ($output, $fn) = each %{ $outputs->{$step} }) {

        my $ds_id = $job->outputs()->{$output}->{id};

        my $ds = $ua->get_dataset( $ds_id );

        say "    Downloading $output to $fn";
        $ds->download($fn);

    }

}
