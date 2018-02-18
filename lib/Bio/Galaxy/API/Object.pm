package Bio::Galaxy::API::Object;

use strict;
use warnings;
use 5.012;

use vars '$AUTOLOAD';

use Carp;

sub new {

    my ($class, $ua, $props) = @_;

    $props->{ua} = $ua;

    my $self =  bless $props => $class;

    for my $required ($self->required_params) {
        croak "Required parameter $required missing"
            if (! defined $self->{$required});
    }

    $self->update;

    return $self;

}

sub AUTOLOAD {

    my ($self) = @_;

    my $key = $AUTOLOAD;
    $key =~ s/.*:://;

    croak "Attempt to access undefined key $key"
        if (! defined $self->{$key});

    return $self->{$key};

}

sub DESTROY {} # necessary to keep from sending to AUTOLOAD()

sub update {
    
    my ($self) = @_;

    my $base = $self->base;

    my $ref = $self->{ua}->_get(
        "$base/$self->{id}",
    );

    for (keys %{$ref}) {
        $self->{$_} = $ref->{$_};
    }

    return;

}

1;


__END__

=head1 NAME

Bio::Galaxy::API::Object - base class providing methods common to most Galaxy
objects


=head1 SYNOPSIS

    package Bio::Galaxy::API::SomeFoo

    use parent qw/Bio::Galaxy::API::Object/;

    sub base           {return 'somefoo'}
    sub require_params {return qw/id name/}

    # subclass-specific methods

    }

=head1 DESCRIPTION

This class is the base class for most/all Galaxy objects, providing methods
common to most endpoints in the API. To use this, subclasses must at a
minimum implement two accessors:

=head2 base

    sub base {return 'basename'}

Should return the base of the Galaxy API URL for the subclass, i.e. the first
element in the URL path after 'api/'.

=head2 required_params

    sub require_params {return qw/id name/}

Should return an array of parameters which are required to be supplied when
creating a new object of the subclass.

=head1 METHODS

=head2 id

    my $id = $obj->id;

Return the object ID.

=head2 update

    $obj->update;

Refreshes the object metadata from the server.

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
