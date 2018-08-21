package Bio::Galaxy::API::Dataset;

use strict;
use warnings;
use 5.012;

use Carp;

use parent 'Bio::Galaxy::API::Object';

sub _base { return 'datasets' }
sub _required_params { return qw/id history_id state/ }

sub download {

    my ($self, $fn) = @_;

    croak "Must specify target filename"
        if (! defined $fn);

    $self->update;

    if ($self->{state} ne 'ok') {
        carp "Dataset status not OK, download aborted.";
        return 0;
    }

    my $history = $self->{history_id}
        // croak "No history ID found";

    return $self->{ua}->_download(
        "histories/$history/contents/$self->{id}/display",
        $fn,
    );

}

1;


__END__

=head1 NAME

Bio::Galaxy::API::Dataset - object representing a Galaxy dataset


=head1 SYNOPSIS

    use Bio::Galaxy::API;

    my $ua = Bio::Galaxy::API->new( @args );

    for my $dataset ($ua->datasets) {

        # $dataset is a Bio::Galaxy::API::Dataset object

        say $dataset->id;

        #etc

    }

=head1 DESCRIPTION

This class is used to represent datasets on a Galaxy server. Objects
of this class are not generally created directly but are returned by methods
of the C<Bio::Galaxy::API> class.

=head1 METHODS

See C<Bio::Galaxy::API::Object> for common methods.

=head2 download

    my $success = $dataset->download( $local_filename );

Downloads the dataset to a specified location locally.

=head1 AUTHOR

Jeremy Volkening, C<< <jdv@base2bio.com> >>

=head1 CAVEATS AND BUGS

Please report any bugs or feature requests to the issue tracker
at L<https://github.com/jvolkening/p5-Bio-Galaxy-API>.

=head1 COPYRIGHT AND LICENSE

Copyright 2017-2018 Jeremy Volkening.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
