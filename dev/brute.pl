use strict;
use warnings;

use HTTP::Tiny;

my $ua = HTTP::Tiny->new;

my $dict = '/usr/share/hunspell/en_US.dic';

open my $in, '<', $dict;
my $url =  'https://localhost:9443/api/';


my $c = 0;
while (my $word = <$in>) {
    chomp $word;

    warn "$c\n" if (($c++ % 1000) == 0);

    $word =~ s/\W.*$//;

    next if ($word !~ /^[a-z]/);

    my @plural;
    if ($word =~ /y$/) {
        my $p = $word;
        $p =~ s/y$/ies/;
        push @plural, $p;
    }
    elsif ($word =~ /s$/) {
        push @plural, "${word}es";
    }
    else {
        push @plural, "${word}s";
    }

    for ($word, @plural) {

        my $res = $ua->get($url . $_);
        print "$_\n" if ($res->{status} != 404);

    }


}
