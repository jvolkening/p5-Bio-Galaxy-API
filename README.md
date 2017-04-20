# NAME

Bio::Galaxy::API - interface to the Galaxy server API

# SYNOPSIS

    use Bio::Galaxy::API;

    my $ua = Bio::Galaxy::API->new(
        url          => 'https://localhost:8080/api',
        api_key      => $secret_token,
        check_secure => 1,
        retry        => 3,
    );

# DESCRIPTION

# CONSTRUCTORS

## new

    my $ua = Bio::Galaxy::API->new(
        url          => 'https://localhost:8080/api',
        api_key      => $secret_token,
        check_secure => 1,
        retry        => 3,
    );

Returns a new `Bio::Galaxy::API` client object. Specifying a URL to the REST
service is required; all other parameters are optional (although most use
cases will require that you provide an API key, either during construction or
later using the `api_key` method). The following are accepted parameters:

- url - the full URL of the Galaxy REST service
- api\_key - the API key of a valid user on the Galaxy server
- check\_secure - if true, will check that the URL provided
uses TLS/SSL encryption and fail otherwise. This is always a good idea if interacting with a
remote server, but can be turned off if you know what you're doing (e.g. for
testing or connecting over localhost on a secure machine). (Default: 1)
- retry - the number of times the client will attempt a connection with
the server before giving up. (Default: 3)

# METHODS

## version

    my $v = $ua->version;

Returns the version of the Galaxy server pointed to (NOT the version of this
module).

## users

    my @users = $ua->users;
    my @users = $ua->users( $username );

Returns an array of [Bio::Galaxy::API::User](https://metacpan.org/pod/Bio::Galaxy::API::User) objects representing registered
Galaxy users. Optionally takes a string containing a username or email
address, in which case it will filter on that token.

## libraries

    my @libs = $ua->libraries;

Returns an array of [Bio::Galaxy::API::Library](https://metacpan.org/pod/Bio::Galaxy::API::Library) objects representing data
libraries available to the current user.

## workflows

    my @workflows = $ua->workflows;

Returns an array of [Bio::Galaxy::API::Workflow](https://metacpan.org/pod/Bio::Galaxy::API::Workflow) objects representing
workflows available to the current user.

## api\_key

    my $key = $ua->api_key;
    my $key = $ua->api_key( $new_key );

Gets/sets the API key associated with the current session. This key is passed
along with each request in order to authenticate with the server and inform
the server which user account to interact with. Returns the value of the key
(or the previous value if a new key is specified).

# AUTHOR

Jeremy Volkening, `<jdv@base2bio.com>`

# CAVEATS AND BUGS

Please report any bugs or feature requests to the issue tracker
at [https://github.com/jvolkening/p5-Bio-Galaxy-API](https://github.com/jvolkening/p5-Bio-Galaxy-API).

# COPYRIGHT AND LICENSE

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
along with this program.  If not, see [http://www.gnu.org/licenses/](http://www.gnu.org/licenses/).
