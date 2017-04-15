use 5.012;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'API::Galaxy',
    license             => 'GPL_3',
    dist_author         => q{Jeremy Volkening <jdv@base2bio.com>},
    dist_version_from   => 'lib/API/Galaxy.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    add_to_cleanup     => [ 'API-Galaxy-*' ],
);

$builder->create_build_script();
