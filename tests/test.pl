#!/usr/bin/perl
use strict;
use warnings;
use feature qw(say);
use IPC::Run qw(run);
use Carp qw(confess);

# The toy project is very simple: libA depends on libB depends on libC. The
# libA/utila executable calls simple functions in each of the sub-libraries.
# This is set up this way to make sure that the implicit dependency of libA on
# libC is handled properly

# First, I make sure I can clean out the tree without leaving any known cruft
# behind
ensure( 'make clean' );
nextTest();

my $leftovers = ensure( "find . -name debian -prune -o \\( -name '*.so*' -o -name '*.dylib*' -o -name '*.a' -o -name '*.o' -o -name '*.d' \\) -print" );
confess "'make clean' didn't clean out everything. Leftovers:\n" . $leftovers if $leftovers;
nextTest();

# make sure shit can build
ensure( 'make' );

# make sure the built application does the expected thing
my $utila_result = `libA/utila`;
my $utila_result_should = <<EOF;
a helper
A defined
a
B defined
b
C defined
c
EOF

if( $utila_result ne $utila_result_should )
{
  confess( "utila output is wrong. Should:\n" .
           $utila_result_should . "\n" .
           "instead got\n" .
           $utila_result . "\n" );
}


ensure( 'make clean' );
nextTest();

# make sure stuff fails if we're doing a package-less install
ensure( 'make install', 'shouldfail' );
nextTest();

# make sure install succeeds otherwise
# make sure correct things actually get installed here
ensure( 'DESTDIR=/tmp make install' );
ensure( 'make clean' );
nextTest();



##################### build dependency checks.#######################

# make sure a rebuild doesn't do anything
ensure( 'make' );
if( ensure( 'make' ) !~ /Nothing to be done/ )
{
  confess "Rebuild shouldn't do anything";
}
nextTest();


touch('libA/subdir/utila_helper.c');
ensure_rebuild( 'make',
                'libA/subdir/utila_helper.o',
                'libA/utila' );
nextTest();

touch('libC/c.h');
ensure_rebuild( 'make',
                'libB/b.o',
                'libB/libB.a',
                'libA/utila' );
nextTest();





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

# makes sure that the given targets are rebuilt in the order specified
sub ensure_rebuild
{
  my $cmd = shift;
  my @targets = @_;
  my $Ntargets = @targets;

  my $commands = ensure( $cmd );

  my @rebuilt = $commands =~ /(?:-o|rcvu) +(\S+)/g;
  my $Ntargets_did = @rebuilt;

  confess "Should have rebuilt $Ntargets targets, instead rebuilt $Ntargets_did targets" unless $Ntargets == $Ntargets_did;

  foreach (0..$#targets)
  {
    confess "Should have rebuilt $targets[$_]; instead rebuilt $rebuilt[$_]" if $rebuilt[$_] ne $targets[$_];
  }
}

sub nextTest
{
  say '';
  say '';
  sleep 1; # to work around timestamp resolution issues
}

sub touch
{
  my $fil = shift;
  run [ 'touch', $fil ] or confess "couldn't 'touch $fil'";
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
