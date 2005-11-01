# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DBI-Simple.t'

#########################

# change 'tests => 3' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('DBI::Simple') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $sice;

$sice	= DBI::Simple->new;
isa_ok( $sice, 'DBI::Simple' );
ok(defined($sice) eq 1,"instantiated");
#
# note:  These tests are overly simplistic.  They will be augmented over
# time
