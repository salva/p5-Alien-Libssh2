package Alien::Libssh2;

our $VERSION = '0.01';

use 5.8.4;
use strict;
use warnings;

1;

=head1 NAME

Alien::Libssh2 - Download, build and install libssh2 automagically!

=head1 SYNOPSIS

    use Module::Build;
    use Alien::Libssh2;

    my $aldd = Alien::Libssh2->dist_dir();
    ...

=head1 SEE ALSO

L<Net::SSH2>, L<Alien::Base>, L<http://libssh2.org>.

=head1 SUPPORT

For support go to the GitHub repository at
L<https://github.com/salva/p5-Alien-Libssh2>.

=head1 COPYRIGHT AND LICENSE

Copyright E<copy> 2016 by Salvador Fandiño
(sfandino@yahoo.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

