use 5.8.4;
use strict;
use warnings;
use Alien::Base::ModuleBuild;

my $class = Alien::Base::ModuleBuild->subclass( class => 'Alien::Libssh2::Builder',
                                                code => <<'EOC' );

sub alien_check_installed_version {
  my $self = shift;
  my $version = $self->config_data('installed_libssh2_version');
  unless (defined $version) {
    $self->alien_helper->{pkg_config} ||= 'Alien::Base::PkgConfig->pkg_config_command';
    $version = $self->SUPER::alien_check_installed_version(@_);
    chomp $version;
    $self->config_data('installed_libssh2_version', $version);
  }
  $version;
}

sub requires {
  my $self = shift;
  if (!$Alien::Base::ModuleBuild::Force and
      $self->alien_check_installed_version) {
        return {};
  }
  return { 'Alien::OpenSSL' => '0.07' }
}

sub alien_build_commands {
  my $self = shift;
  if ($self->{action} and $self->{action} eq 'Build_PL') {
    return ["echo '*** to be filled later ***'", "exit 1"]
  }

  my $config_cmd = "%pconfigure --prefix=%s --with-openssl";

  if ($^O eq 'MSWin32') {
    $config_cmd = "sh $config_cmd";
  }

  require Alien::OpenSSL;
  my $ao = Alien::OpenSSL->new;
  if (defined (my $ao_dist_dir = $ao->dist_dir)) {
    if ($^O eq 'MSWin32') {
      $ao_dist_dir =~ s{\\}{/}g;
      $ao_dist_dir =~ s{^([a-z]):/}{/$1/}i;
    }

    $config_cmd .= " --with-libssl-prefix=$ao_dist_dir"
  }

  return [ $config_cmd, "make" ]
}

EOC

my $builder = $class
  ->new( module_name        => 'Alien::Libssh2',
         license            => 'perl',
         dist_author        => q{Salvador Fandiño <sfandino@yahoo.com>},
         configure_requires => { 'Alien::Base' => '0.23_01' },
         alien_name         => 'libssh2',
         alien_repository   => { protocol => 'http',
                                 host => 'github.com',
                                 location => '/libssh2/libssh2/releases/',
                                 pattern => qr/\/libssh2-(1\.\d+\.\d+)\.tar\.gz$/ },
         alien_msys         => 1,
         meta_merge         => { resources => { homepage => 'https://github.com/salva/p5-Alien-Libssh2',
			                        bugtracker => 'https://github.com/salva/p5-Alien-Libssh2/issues',
                                                repository  => 'https://github.com/salva/p5-Alien-Libssh2.git' } }, );

$builder->create_build_script();
