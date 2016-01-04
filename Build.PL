use 5.8.4;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Alien::Libssh2',
    license             => 'artistic_2',
    dist_author         => q{Salvador Fandiño <sfandino@yahoo.com>},
    dist_version_from   => 'lib/Alien/Libssh2.pm',
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
    add_to_cleanup     => [ 'Alien-Libssh2-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
