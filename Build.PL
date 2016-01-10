use 5.8.4;
use strict;
use warnings;
use Alien::Base::ModuleBuild;

my $class = Alien::Base::ModuleBuild->subclass( class => 'Alien::Libssh2::Builder',
                                                code => <<'EOC' );

use strict;
use warnings;
use Carp;

__PACKAGE__->add_property('use_gcrypt');
__PACKAGE__->add_property('gcrypt_check_command' => '%{pkg_config} --libs-only-l --static %n');


sub alien_check_installed_version {
  my $self = shift;
  my $version = $self->config_data('system_library_version');
  unless (defined $version) {
    $self->alien_helper->{pkg_config} ||= 'Alien::Base::PkgConfig->pkg_config_command';
    $version = $self->SUPER::alien_check_installed_version(@_);
    chomp $version;
    $self->config_data('system_library_version', $version);
  }
  $version;
}

sub check_installed_use_gcrypt {
  my $self = shift;
  my $gcrypt = $self->config_data('system_library_use_gcrypt');
  unless (defined $gcrypt) {
    my %result = $self->do_system($self->gcrypt_check_command, { verbose => 0 });
    $gcrypt = ( $result{stdout} =~ /gcrypt/ );
    $self->config_data('system_library_use_gcrypt', $gcrypt);
  }
  $gcrypt;
}

sub use_installed_version {
  my $self = shift;
  if (defined (my $type = $self->config_data('install_type'))) {
    return ($type eq 'system');
  }

  !$Alien::Base::ModuleBuild::Force and
    $self->alien_check_installed_version
}

sub requires {
  my $self = shift;
  my %r;
  unless ($self->use_installed_version) {
    if ($self->use_gcrypt) {
      $r{'Alien::Libgcrypt'} = '0';
    }
    else {
      $r{'Alien::OpenSSL'} = '0.07';
    }
  }
  \%r;
}

*build_requires = \&requires;

sub alien_build_commands {
  my $self = shift;
  if ($self->{action} and $self->{action} eq 'Build_PL') {
    return ["echo '*** to be filled later ***'", "exit 1"]
  }

  my $config_cmd = "%pconfigure --prefix=%s";

  if ($^O eq 'MSWin32') {
    $config_cmd = "sh $config_cmd";
  }

  my ($with_key, $with_prefix_key, $module) =
    ( $self->use_gcrypt
      ? qw(gcrypt  libgcrypt OpenSSL)
      : qw(openssl libssl    Libgcrypt) );

  $config_cmd .= " --with-${with_key}";

  my $ac = "Alien::$module";
  eval "require $ac; 1" or die;
  my $ao = $ac->new;
  if ($ao->config('install_type') ne 'system') {
    if (defined (my $ao_dist_dir = $ao->dist_dir)) {
      if ($^O eq 'MSWin32') {
        $ao_dist_dir =~ s{\\}{/}g;
        $ao_dist_dir =~ s{^([a-z]):/}{/$1/}i;
      }
      $config_cmd .= " --with-${with_prefix_key}-prefix=$ao_dist_dir";
    }
  }

  return [ $config_cmd, "make" ]
}

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  if ($self->use_installed_version) {
    my $system_use_gcrypt = $self->check_installed_use_gcrypt;
    if (defined (my $use_gcrypt = $self->use_gcrypt)) {
      if ($system_use_gcrypt != $use_gcrypt) {
        croak "use_gcrypt=$use_gcrypt doesn't match the system library configuration found";
      }
    }
    else {
      $self->config_data('use_gcrypt', $system_use_gcrypt);
    }
  }
  $self;
}

EOC

my $builder = $class
  ->new( module_name        => 'Alien::Libssh2',
         license            => 'perl',
         dist_author        => q{Salvador Fandiño <sfandino@yahoo.com>},
         configure_requires => { 'Alien::Base' => '0.24' },
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
