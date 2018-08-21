package Bio::Galaxy::API::Workflow;

use 5.012;
use strict;
use warnings FATAL => 'all';
use Carp;

use parent 'Bio::Galaxy::API::Object';

sub _base { return 'workflows' }
sub _required_params { return qw/id name tags owner deleted/ }

use Bio::Galaxy::API::Workflow::Invocation;


sub run {

    my ($self, %args) = @_;

    # parameters
    # ds_map
    # history

    for my $required (qw/ds_map/) {
        croak "Required parameter $required missing"
            if (! defined $args{$required});
    }

    my $payload = {
        workflow_id => $self->id(),
        ds_map      => $args{ds_map},
    };

    for my $optional (qw/history parameters/) {
        $payload->{$optional} = $args{$optional}
            if (defined $args{$optional});
    }

    my $inv = $self->{ua}->_post( 'workflows', $payload );
    return $inv if (! defined $inv);
    return Bio::Galaxy::API::Workflow::Invocation->new( $self->{ua}, $inv );

}
    
1;


__END__

=head1 NAME

Bio::Galaxy::API::Workflow - object representing a Galaxy workflow


=head1 SYNOPSIS

    use Bio::Galaxy::API;

    my $ua = Bio::Galaxy::API->new( @args );

    for my $workflow ($ua->workflows) {

        # $workflow is a Bio::Galaxy::API::Workflow object

        say $workflow->id;
        say $workflow->name;

        #etc

    }

=head1 DESCRIPTION

This class is used to represent individual users on a Galaxy server. Objects
of this class are not generally created directly but are returned by methods
of the C<Bio::Galaxy::API> class.

=head1 METHODS

See C<Bio::Galaxy::API::Object> for common methods.

=head2 name

    my $name = $workflow->name;

Returns the name associated with the workflow. Note that this value is not
necessarily unique.

=head2 deleted

    my $is_deleted = $workflow->deleted;

Returns a boolean value indicating whether the workflow has been marked
deleted in the Galaxy database.

=head2 run

    my $invocation = $workflow->run(
        history => 'A test history',
        ds_map => {
            $input_1_id => {
                id => $dataset_id_1,
                src => $input_src,
            }
            $input_2_id => {
                id => $dataset_id_2,
                src => $input_src,
            }
        },
        parameters => {
            3 => {
                param1 => 9,
                param2 => 'foo',
            },
            5 => {
                someparam => '0.002',
            },
        },
    );

Runs the workflow on a given set of inputs and returns a
C<Bio::Galaxy::API::Workflow::Invocation> object representing the current run.
Accepts the following parameters:

=over 1

=item * ds_map - (required) reference to a data structure describing the input files to
use. Each key should be the ID of the input (currently needs to be found
manually by applying Data::Dumper, etc, to this object) and the value another
hash reference with the following keys:

=over 1

=item * id - the dataset ID

=item * src - the dataset source, one of [ldda|ld|hda]

=back

=item * history - the name of a new history to create contanining the run. If
not given, a generic history name will be used.

=item * parameters - reference to a hash describing parameters to be set at
runtime. Each key should be the index of the workflow step and the value
another hash reference with key/value parameter pairs.

=back

=head2 update

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
