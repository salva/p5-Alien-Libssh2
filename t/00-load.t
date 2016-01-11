#!perl
use 5.8.4;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Alien::Libssh2' ) || print "Bail out!\n";
}

diag( "Testing Alien::Libssh2 $Alien::Libssh2::VERSION, Perl $], $^X" );
