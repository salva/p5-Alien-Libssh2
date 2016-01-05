use 5.8.4;
use strict;
use warnings;
use Alien::Base::ModuleBuild;

my $builder = Alien::Base::ModuleBuild
  ->new( module_name        => 'Alien::Libssh2',
         license            => 'perl',
         dist_author        => q{Salvador Fandiño <sfandino@yahoo.com>},
         configure_requires => { 'Module::Build' => 0,
                                 'Alien::OpenSSL' => '0.07' },
         alien_name         => 'libssh2',
         alien_repository   => { protocol => 'http',
                                 host => 'github.com',
                                 location => '/libssh2/libssh2/releases/',
                                 pattern => qr/\/libssh2-(1\.\d+\.\d+)\.tar\.gz$/ },
         alien_msys         => 1,
       );

$builder->create_build_script();
