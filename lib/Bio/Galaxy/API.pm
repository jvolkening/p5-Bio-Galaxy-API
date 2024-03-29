package Bio::Galaxy::API;

use 5.012;
use strict;
use warnings FATAL => 'all';

use Carp;
use File::Basename qw/basename/;
use HTTP::Tiny;
use JSON;
use URI;
use URI::Escape;

use Bio::Galaxy::API::Library;
use Bio::Galaxy::API::User;
use Bio::Galaxy::API::Group;
use Bio::Galaxy::API::Role;
use Bio::Galaxy::API::Workflow;
use Bio::Galaxy::API::Job;
use Bio::Galaxy::API::Dataset;
use Bio::Galaxy::API::Util qw/_check_id/;

our $VERSION = '0.004001';

sub new {

    my ($class, %args) = @_;

    # set defaults where appropriate
    my $self = bless {
        check_secure => 1,
        retry        => 3,
    } => $class;

    for my $required (qw/url/) {
        croak "Required parameter $required missing"
            if (! defined $args{$required});
    }

    # handle simple pass-through values
    $self->{check_secure} = $args{check_secure}
        if (defined $args{check_secure});

    # validate URL
    my $url = URI->new( $args{url} );
    croak "Unrecognized URL scheme (please use e.g. \"https://server.org\")"
        if (! $url->has_recognized_scheme);
    croak "Insecure URL (set 'check_secure => 0' if you really want to do this"
        if (! $url->secure && $self->{check_secure});
    # set default base path if missing
    $url->path('api') if (! length $url->path);

    $self->{url} = $url;
    $self->{ua} = HTTP::Tiny->new(
        'agent' => "Bio::Galaxy::API/$VERSION",
    );

    # check connectivity
    my $version = $self->version;
    croak "Attempt to test API connection failed"
        if (! defined $version);

    # attempt to parse or find API key (otherwise it will be undefined and the
    # functionality will be limited to non-account interfaces such as server
    # version, etc
    if (defined $args{api_key}) {
        $self->{key} = $args{api_key};
    }
    elsif (-r "$ENV{HOME}/.galaxy_api_key") {
        open my $in, '<', "$ENV{HOME}/.galaxy_api_key";
        my $key = <$in>;
        chomp $key;
        $self->{key} = $key;
    }

    return $self;

}

sub version {

    my ($self) = @_;

    my $res = $self->_get('version');

    return $res->{version_major};

}

sub libraries {

    my ($self) = @_;

    my $libs = $self->_get('libraries')
        // return undef;
    return 
        grep {! $_->deleted()}
        map  {Bio::Galaxy::API::Library->new($self, $_)} @{$libs};

}

sub workflows {

    my ($self) = @_;

    my $wfs = $self->_get('workflows')
        // return undef;
    return 
        grep {! $_->deleted()}
        map  {Bio::Galaxy::API::Workflow->new($self, $_)} @{$wfs};

}

sub jobs {

    my ($self) = @_;

    my $jobs = $self->_get('jobs')
        // return undef;
    return 
        grep {! $_->deleted()}
        map  {Bio::Galaxy::API::Job->new($self, $_)} @{$jobs};

}

sub users {

    my ($self, $user) = @_;

    $user //= '';

    my $users = $self->_get('users', 'f_any' => $user)
        // return undef;
    return 
        grep {! $_->deleted()}
        map  {Bio::Galaxy::API::User->new($self, $_)} @{$users};

}

sub groups {

    my ($self, $group) = @_;

    my $groups = $self->_get('groups')
        // return undef;
    return 
        map  {Bio::Galaxy::API::Group->new($self, $_)} @{$groups};

}

sub roles {

    my ($self, $role) = @_;

    my $roles = $self->_get('roles')
        // return undef;
    return 
        map  {Bio::Galaxy::API::Role->new($self, $_)} @{$roles};

}

sub new_user {

    my ($self, %args) = @_;

    my $data = $self->_post(
        'users',
        {
            username => ($args{user}     // die "Missing name"),
            email    => ($args{email}    // die "Missing email"),
            password => ($args{password} // die "Missing password"),
        },
    ) // return undef;

    return Bio::Galaxy::API::User->new($self, $data);

}

sub new_library {

    my ($self, %args) = @_;
   
    my $data = $self->_post(
        'libraries',
        {
            name        => ($args{name}        // die "Missing name"),
            description => ($args{description} // ''),
            synopsis    => ($args{synopsis}    // ''),
        },
    ) // return undef;

    return Bio::Galaxy::API::Library->new($self, $data);

}

sub new_group {

    my ($self, %args) = @_;

    #TODO: implement 'user_ids' and 'role_ids' arguments
   
    my $data = $self->_post(
        'groups',
        {
            name => ($args{name} // die "Missing name"),
        },
    ) // return undef;

    # $data references array of one item
    return Bio::Galaxy::API::Group->new($self, $data->[0]);

}

sub get_dataset {

    my ($self, $ds_id) = @_;

    _check_id( $ds_id );

    my $res = $self->_get(
        "datasets/$ds_id"
    );
    
    return Bio::Galaxy::API::Dataset->new($self, $res);

}

sub get_job {

    my ($self, $job_id) = @_;

    _check_id( $job_id );

    my $res = $self->_get(
        "jobs/$job_id",
        full => 'True',
    );
    
    return Bio::Galaxy::API::Job->new($self, $res);

}

sub api_key {

    my ($self, $key) = @_;

    my $old_key = $self->{key};
    $self->{key} = $key
        if (defined $key);

    return $old_key;

}

sub _put {

    my ($self, $path, $payload) = @_;

    my $url = join '/',
        $self->{url},
        $path;

    for (1.. $self->{retry}) {

        my $encoded = JSON->new->encode($payload);
        my $res = $self->{ua}->put( $url => {
            headers => {
                'content-type' => 'application/json',
                'x-api-key'    => $self->{key} // '',
            },
            content => $encoded,
        } );

        if (! $res->{success}) {
            warn "HTTP Error: $res->{status} ($res->{reason})\n$res->{content}\n";
        }

        else {
            return JSON->new->allow_nonref->decode( $res->{content} );
        }

    }

    return undef;

}

sub _post {

    my ($self, $path, $payload, $fn) = @_;

    my $url = join '/',
        $self->{url},
        $path;

    for (1.. $self->{retry}) {

        my $res;
        if (defined $fn) {

            my $boundary = 'xYzZY__xYzZY__sYzZY__xYzZY__xYzZY';

            my $base = $payload->{name} // basename($fn);

            my $size = 0;
            for (keys %$payload) {
                $size += 49 + length($_) + length($payload->{$_}) +
                    length($boundary);
            }
            $size += 62 + length('files_0|file_data') + (-s $fn) +
                + length($base) + length($boundary);
            $size += 6 + length $boundary;

            my $cb = _generator(
                $base,
                $boundary,
                $payload,
                $fn,
            );

            $res = $self->{ua}->post( $url => {
                headers => {
                    'content-type'   => "multipart/form-data; boundary=$boundary",
                    'content-length' => $size,
                    'x-api-key'      => $self->{key} // '',
                },
                content => $cb,
            } );

        }
        else {
            
            my $encoded = JSON->new->encode($payload);
            $res = $self->{ua}->post( $url => {
                headers => {
                    'content-type' => 'application/json',
                    'x-api-key'    => $self->{key} // '',
                },
                content => $encoded,
            } );

        }

        if (! $res->{success}) {
            warn "HTTP Error: $res->{status} ($res->{reason})\n$res->{content}\n";
        }

        else {
            return JSON->new->allow_nonref->decode( $res->{content} );
        }

    }

    return undef;

}

sub _download {

    my ($self, $path, $fn, @params) = @_;

    croak "file already exists, won't overwrite\n"
        if (-e $fn);

    my $url = join '/',
        $self->{url},
        $path;

    if (@params) {
        $url .= '?' . $self->{ua}->www_form_urlencode(\@params);
    }

    for (1.. $self->{retry}) {

        open my $out, '>', $fn;

        my $res = $self->{ua}->get($url => {
            headers => {
                'x-api-key' => $self->{key} // '',
            },
            data_callback => sub { print {$out} $_[0] },
        } );

        close $out;

        if (! $res->{success}) {
            warn "HTTP Error: $res->{status} ($res->{reason} $res->{content}) \n";
            unlink $fn;
        }

        return 1;

    }

    return undef;

}

sub _get {

    my ($self, $path, @params) = @_;

    my $url = join '/',
        $self->{url},
        $path;

    if (@params) {
        $url .= '?' . $self->{ua}->www_form_urlencode(\@params);
    }

    for (1.. $self->{retry}) {

        my $res = $self->{ua}->get($url => {
            headers => {
                'x-api-key' => $self->{key} // '',
            },
        } );

        if (! $res->{success}) {
            warn "HTTP Error: $res->{status} ($res->{reason})\n";
        }
        elsif (defined $res->{headers}->{'content-type'}
                && lc($res->{headers}->{'content-type'}) !~ /^application\/json\b/) {
            warn "Error: server did not return JSON payload as expected ($res->{headers}->{'content-type'})\n";
        }
        else {
            return JSON->new->allow_nonref->decode( $res->{content} );
        }

    }

    return undef;

}

sub _delete {

    my ($self, $path, @params) = @_;

    my $url = join '/',
        $self->{url},
        $path;

    if (@params) {
        $url .= '?' . $self->{ua}->www_form_urlencode(\@params);
    }

    for (1.. $self->{retry}) {

        my $res = $self->{ua}->delete($url => {
            headers => {
                'x-api-key' => $self->{key} // '',
            },
        } );

        if (! $res->{success}) {
            warn "HTTP Error: $res->{status} ($res->{reason})\n";
        }
        elsif (defined $res->{headers}->{'content-type'}
                && lc($res->{headers}->{'content-type'}) !~ /^application\/json\b/) {
            warn "Error: server did not return JSON payload as expected\n";
        }
        else {
            return JSON->new->allow_nonref->decode( $res->{content} );
        }

    }

    return undef;

}

sub _split_payload {

    my ($payload, $base) = @_;

    my $boundary = 'xYzZY__xYzZY__sYzZY__xYzZY__xYzZY';
    my $CRLF = "\015\012";

    my $chunk;

    for my $k (keys %$payload) {

        #47 + length key + length val + length boundary
        $chunk .= "--$boundary$CRLF";
        $chunk .= "Content-Disposition: form-data; name=\"$k\"$CRLF$CRLF";
        $chunk .= "$payload->{$k}$CRLF";

        #49 + length key + length val + length boundary
        #13 + length filename
        #6 + length boundary

    }
    $chunk .= "--$boundary$CRLF";
    $chunk .= "Content-Disposition: form-data; name=\"files_0|file_data\"; filename=\"$base\"$CRLF$CRLF";

    return $chunk;
            
}        

sub _generator {

    my ($base, $boundary, $payload, $fn) = @_;

    my $n_read = 4096;
    my $done = 0;

    open my $fh, '<', $fn or die "Error open: $!\n";
    my $CRLF = "\015\012";
    my @keys = keys %$payload;

    return sub {

        return undef if ($done);

        my $chunk;

        while (scalar @keys) {
            my $k = shift @keys; 
            $chunk .= "--$boundary$CRLF";
            $chunk .= "Content-Disposition: form-data; name=\"$k\"$CRLF$CRLF";
            $chunk .= "$payload->{$k}$CRLF";
            return $chunk if (scalar @keys);
            $chunk .= "--$boundary$CRLF";
            $chunk .= "Content-Disposition: form-data; name=\"files_0|file_data\"; filename=\"$base\"$CRLF$CRLF";
            return $chunk;
        }

        while (read($fh, my $buf, $n_read)) {
            return $buf;
        }

        $done = 1;
        return "$CRLF--$boundary--$CRLF";

    }
            
}        
            




__END__

=head1 NAME

Bio::Galaxy::API - interface to the Galaxy server API


=head1 SYNOPSIS

    use Bio::Galaxy::API;

    my $ua = Bio::Galaxy::API->new(
        url          => 'https://localhost:8080/api',
        api_key      => $secret_token,
        check_secure => 1,
        retry        => 3,
    );

=head1 DESCRIPTION

C<Bio::Galaxy::API> is an interface to the REST API of the Galaxy informatics
platform (L<https://galaxyproject.org>).

WARNING: This library is currently in early development. The API (of this
library, not of the Galaxy REST service) is not stable and will likely change.
Many endpoints of the REST API remain unimplemented. This warning will be
removed when the library reaches a more mature state.

=head1 CONSTRUCTORS

=head2 new

    my $ua = Bio::Galaxy::API->new(
        url          => 'https://localhost:8080/api',
        api_key      => $secret_token,
        check_secure => 1,
        retry        => 3,
    );

Returns a new C<Bio::Galaxy::API> client object. Specifying a URL to the REST
service is required; all other parameters are optional (although most use
cases will require that you provide an API key, either during construction or
later using the C<api_key> method). The following are accepted parameters:

=over 1

=item * url - the full URL of the Galaxy REST service

=item * api_key - the API key of a valid user on the Galaxy server

=item * check_secure - if true, will check that the URL provided
uses TLS/SSL encryption and fail otherwise. This is always a good idea if interacting with a
remote server, but can be turned off if you know what you're doing (e.g. for
testing or connecting over localhost on a secure machine). (Default: 1)

=item * retry - the number of times the client will attempt a connection with
the server before giving up. (Default: 3)

=back

=head1 METHODS

=head2 version

    my $v = $ua->version;

Returns the version of the Galaxy server pointed to (NOT the version of this
module).

=head2 users

    my @users = $ua->users;
    my @users = $ua->users( $username );

Returns an array of L<Bio::Galaxy::API::User> objects representing registered
Galaxy users. Optionally takes a string containing a username or email
address, in which case it will filter on that token.

=head2 groups

    my @groups = $ua->groups;

Returns an array of L<Bio::Galaxy::API::Group> objects representing existing
Galaxy groups.

=head2 roles

    my @roles = $ua->roles;

Returns an array of L<Bio::Galaxy::API::Role> objects representing existing
Galaxy roles.

=head2 libraries

    my @libs = $ua->libraries;

Returns an array of L<Bio::Galaxy::API::Library> objects representing data
libraries available to the current user.

=head2 workflows

    my @workflows = $ua->workflows;

Returns an array of L<Bio::Galaxy::API::Workflow> objects representing
workflows available to the current user.

=head2 jobs

    my @jobs = $ua->jobs;

Returns an array of L<Bio::Galaxy::API::Job> objects representing
jobs of the current user.

=head2 new_user

    my $user = $ua->new_user(
        user     => $username,
        email    => $email,
        password => $pw,
    );

Attempts to create a new user on the Galaxy server with the information given.
There are three parameters, all required:

=over 1

=item * user - the username to use. This must follow Galaxy's requirements,
which currently only allows lowercase alphanumeric, underscore, and dash, or
the server will return an error.

=item * email - a valid email address for the user

=item * password - the intitial password to set for the user

=back

=head2 new_group

    my $group = $ua->new_group(
        name => $groupname,
    );

Attempts to create a new group on the Galaxy server with the information given.
There is one required parameter and two optional parameters:

=over 1

=item * name - (required) the group name to use. An error will be thrown if the group
already exists.

=item * user_ids - (optional) (UNIMPLEMENTED) An array of user IDs to
associate with the group

=item * role_ids - (optional) (UNIMPLEMENTED) An array of role IDs to
associate with the group

=back

=head2 new_library

    my $library = $ua->new_library(
        name        => $name,
        description => $description,
        synopsis    => $synopsis,
    );

Attempts to create a new library on the Galaxy server with the information given.
There is one required parameter and two optional parameters:

=over 1

=item * name - (required) the library name to use.

=item * description - (optional) a short description to be displayed to the
user

=item * synopsis - (optional) a longer synopsis to be displayed to the user

=back

=head2 get_dataset

    my $ds = $ua->get_dataset($ds_id);

Takes a single required argument (dataset ID) and returns a
L<Bio::Galaxy::API::Dataset> object, or undefined if not found

=head2 get_job

    my $job = $ua->get_job($job_id);

Takes a single required argument (job ID) and returns a
L<Bio::Galaxy::API::Job> object, or undefined if not found

=head2 api_key

    my $key = $ua->api_key;
    my $key = $ua->api_key( $new_key );

Gets/sets the API key associated with the current session. This key is passed
along with each request in order to authenticate with the server and inform
the server which user account to interact with. Returns the value of the key
(or the previous value if a new key is specified).

=head1 AUTHOR

Jeremy Volkening, C<< <jdv@base2bio.com> >>

=head1 CAVEATS AND BUGS

Please report any bugs or feature requests to the issue tracker
at L<https://github.com/jvolkening/p5-Bio-Galaxy-API>.

=head1 COPYRIGHT AND LICENSE

Copyright 2017 Jeremy Volkening.

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
