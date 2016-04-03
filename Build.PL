use 5.8.4;
use strict;
use warnings;
use Alien::Base::ModuleBuild;

my $class = Alien::Base::ModuleBuild->subclass( class => 'Alien::Libssh2::Builder',
                                                code => <<'EOC' );

use strict;
use warnings;
use Carp;

__PACKAGE__->add_property('crypto_backend');
__PACKAGE__->add_property('use_gcrypt');
__PACKAGE__->add_property('crypto_backend_check_command' => '%{pkg_config} --libs-only-l --static %n');


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

sub check_installed_crypto_backend {
  my $self = shift;
  my $cbe = $self->config_data('system_library_crypto_backend');
  unless (defined $cbe) {
    my %result = $self->do_system($self->crypto_backend_check_command, { verbose => 0 });
    if    ( $result{stdout} =~ /gcrypt/i ) { $cbe = 'gcrypt'  }
    elsif ( $result{stdout} =~ /ssl/i )    { $cbe = 'openssl' }
    elsif ( $^O eq 'MSWin32' )             { $cbe = 'wincng'  }
    else { croak "unable to detect crypto backend used by system library" }

    $self->config_data('system_library_crypto_backend', $cbe);
  }
  $cbe;
}

sub use_installed_version {
  my $self = shift;
  if (defined (my $type = $self->config_data('install_type'))) {
    return ($type eq 'system');
  }

  !$Alien::Base::ModuleBuild::Force and
    $self->alien_check_installed_version
}

sub alien_build_commands {
  my $self = shift;
  if ($self->{action} and $self->{action} eq 'Build_PL') {
    return ["echo '*** to be filled later ***'", "exit 1"]
  }

  my $config_cmd = "%pconfigure --prefix=%s --disable-examples-build";
  $config_cmd = "sh ./$config_cmd"
    if $^O eq 'MSWin32';

  my $cbe = $self->crypto_backend;

  $self->log_verbose("CBE: ".($cbe//'<undef>')."\n");

  unless (defined $cbe) {
    $cbe = (($^O eq 'MSWin32') ? 'wincng' : 'gcrypt');
    $self->crypto_backend($cbe)
  }

  my ($with_prefix_key, $module) =
    ( $cbe eq 'gcrypt'  ? qw(libgcrypt Libgcrypt) :
      $cbe eq 'openssl' ? qw(libssl    OpenSSL  ) :
      $cbe eq 'wincng'  ? ()                      :
      die "unkwnon crypto backend '$cbe'" );

  $config_cmd .= " --with-$cbe";

  if (defined $module) {
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
  }
  return [ $config_cmd, "make" ]
}

my %crypto_backend_module = ( wincng  => undef,
                             gcrypt  => 'Libgcrypt',
                             openssl => 'OpenSSL' );

sub auto_require {
  my $self = shift;
  $self->SUPER::auto_require(@_);
  my $cbe = $self->crypto_backend;
  if ($self->use_installed_version) {
    my $installed_cbe = $self->check_installed_crypto_backend;
    if (defined $cbe) {
      $installed_cbe eq $cbe or
        croak "user selected crypto backend ($cbe) doesn't match the one for the system installed libssh2 ($installed_cbe)";
    }
    else {
      $cbe = $installed_cbe;
    }
    $self->log_verbose("Crypto backend for the system libssh2 is $installed_cbe\n");
  }
  else {
    $cbe //= (($^O eq 'MSWin32') ? 'wincng' : 'gcrypt');
    $self->log_verbose("Crypto backend picked is $cbe\n");

    $cbe eq 'wincng' and $^O ne 'MSWin32'
      and croak "Crypto backend wincng only supported in MS Windows";

    my $cbe_module = $crypto_backend_module{$cbe};
    if (defined $cbe_module) {
      $self->_add_prereq(requires => "Alien::$cbe_module", 0);
      $self->alien_bin_requires({ "Alien::cbe_module" => 0 });
    }
    else {
      exists $crypto_backend_module{$cbe}
        or croak "unsupported crypto backend $cbe";
    }
  }

  $self->crypto_backend($cbe);
  $self->config_data(crypto_backend => $cbe);
  ()
}

EOC

my $builder = $class
  ->new( module_name        => 'Alien::Libssh2',
         license            => 'perl',
         dist_author        => q{Salvador Fandiño <sfandino@yahoo.com>},
         configure_requires => { 'Alien::Base' => '0.24' },
         alien_name         => 'libssh2',
         # alien_repository   => { protocol => 'http',
         #                         host => 'github.com',
         #                         location => '/libssh2/libssh2/releases/',
         #                         pattern => qr/\/libssh2-(1\.\d+\.\d+)\.tar\.gz$/ },
         alien_repository   => { protocol => 'https',
                                 host => 'libssh2.org',
                                 location => '/download/',
                                 pattern => qr/^libssh2-(1\.\d+\.\d+)\.tar\.gz$/ },
         alien_msys         => 1,
         meta_merge         => { resources => { homepage => 'https://github.com/salva/p5-Alien-Libssh2',
			                        bugtracker => 'https://github.com/salva/p5-Alien-Libssh2/issues',
                                                repository  => 'https://github.com/salva/p5-Alien-Libssh2.git' } }, );

$builder->create_build_script();
