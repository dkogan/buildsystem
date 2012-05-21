#!/usr/bin/perl
use strict;
use warnings;
use feature qw(say);
use IPC::Run qw(run);
use Carp qw(confess);

# The toy project is very simple: libA depends on libB depends on libC The
# libA/utila executable calls simple functions in each of the sub-libraries.
# This is set up this way to make sure that the implicit dependency of libA on
# libC is handled properly


# First, I make sure I can clean out the tree without leaving any known cruft
# behind
ensure( 'make clean' );
say '';
say '';

my $leftovers = ensure( "find . -name debian -prune -o \\( -name '*.so*' -o -name '*.dylib*' -o -name '*.a' -o -name '*.o' -o -name '*.d' \\) -print" );
confess "'make clean' didn't clean out everything. Leftovers:\n" . $leftovers if $leftovers;
say '';
say '';

# make sure shit can build
ensure( 'make' );
ensure( 'make clean' );
say '';
say '';

# make sure stuff fails if we're doing a package-less install
ensure( 'make install', 'shouldfail' );
say '';
say '';

# make sure stuff fails if we're doing a package-less install
ensure( 'DESTDIR=/tmp make install' );
ensure( 'make clean' );
say '';
say '';


# runs a command, prints and returns its output (stderr and stdout together).
# dies if the command fails.
# Always running with a shell; Command must be a string
sub ensure
{
  my $cmd     = shift;
  my $options = shift;
  my $shouldfail = $options && $options eq 'shouldfail';

  my $extramsg = $shouldfail ? ' It should fail.' : '';
  say "Running '$cmd'.$extramsg Says:";

  my $result;
  my $success   = run ['bash', '-c', $cmd], \undef, \$result, '2>&1';
  my $errorcode = $success || $?;

  say '====================================================';
  print $result;
  say '====================================================';

  if( !$shouldfail && !$success )
  {
    confess "Test failure: '$cmd' exited with error code $errorcode";
  }
  if( $shouldfail &&  $success )
  {
    confess "Test failure: '$cmd' should have failed, but it succeeded";
  }

  return $result;
}



__END__

- make sure header dependencies trigger rebuilds correctly
- make sure intra-repo library dependencies trigger rebuilds correctly
- make sure correct flags are used
  - user-specified
  - system
  - user -O should replace other -O
- the various -L and -I existence checks
- rpath
- per-target variables
- variables need to work from sub-builds as well. I have _chdir_customized_vars, for instance
- modified CCXXFLAGS should still work
- all the flags are now additive
- make sure that 'make clean' cleans out everything it needs to, including any
  EXTRACLEAN things, AND has correct paths for those

dima@fatty:~/buildsystem/tests$ objdump -p libA/libA.so | grep NEEDED
  NEEDED               libB.so.0
  NEEDED               libstdc++.so.6
  NEEDED               libm.so.6
  NEEDED               libgcc_s.so.1
  NEEDED               libc.so.6
dima@fatty:~/buildsystem/tests$ objdump -p libB/libB.so | grep NEEDED
  NEEDED               libC.so.0
  NEEDED               libstdc++.so.6
  NEEDED               libm.so.6
  NEEDED               libgcc_s.so.1
  NEEDED               libc.so.6
dima@fatty:~/buildsystem/tests$ objdump -p libC/libC.so | grep NEEDED
  NEEDED               libstdc++.so.6
  NEEDED               libm.so.6
  NEEDED               libgcc_s.so.1
  NEEDED               libc.so.6



DESTDIR=/tmp make  install









/usr/bin/find . -name debian -prune -o \( -name '*.so*' -o -name '*.dylib*' -o -name '*.a' -o -name '*.o' -o -name '*.d' \) -print
