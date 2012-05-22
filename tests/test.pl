#!/usr/bin/perl
use strict;
use warnings;
use feature qw(say);
use IPC::Run qw(run);
use Carp qw(confess);
use Data::Dumper;
use List::Compare;
use Cwd qw(abs_path);

# The toy project is very simple: libA depends on libB depends on libC. The
# libA/utila executable calls simple functions in each of the sub-libraries.
# This is set up this way to make sure that the implicit dependency of libA on
# libC is handled properly

say '##################### clean tests #######################';
{
  my $leftovers;

  # First, I make sure I can clean out the tree without leaving any known cruft
  # behind
  ensure( 'make clean' );
  nextTest();

  $leftovers = ensure( "find . -name debian -prune -o \\( -name '*.so*' -o -name '*.dylib*' -o -name '*.a' -o -name '*.o' -o -name '*.d' \\) -print" );
  confess "'make clean' didn't clean out everything. Leftovers:\n" . $leftovers if $leftovers;
  nextTest();

  testCleanWithCmd( 'make -C libA clean' );
  nextTest();

  testCleanWithCmd( 'make libA/clean' );
  nextTest();




  sub testCleanWithCmd
  {
    my $cleancmd = shift;

    ensure( 'make' );
    my $shouldHaveA = ensure( "find libA -name '*.so*' -o -name '*.dylib*' -o -name '*.a' -o -name '*.o' -o -name '*.d' | sort" );
    my $shouldHaveB = ensure( "find libB -name '*.so*' -o -name '*.dylib*' -o -name '*.a' -o -name '*.o' -o -name '*.d' | sort" );
    my $shouldHaveC = ensure( "find libC -name '*.so*' -o -name '*.dylib*' -o -name '*.a' -o -name '*.o' -o -name '*.d' | sort" );

    ensure( $cleancmd );
    $leftovers = ensure( "find libA -name '*.so*' -o -name '*.dylib*' -o -name '*.a' -o -name '*.o' -o -name '*.d'" );
    confess "'$cleancmd' didn't clean out everything in libA. Leftovers:\n" . $leftovers if $leftovers;

    ensure( "find libB -name '*.so*' -o -name '*.dylib*' -o -name '*.a' -o -name '*.o' -o -name '*.d' | sort" ) eq $shouldHaveB or
      confess "'$cleancmd' cleaned out some stuff in libB!";

    ensure( "find libC -name '*.so*' -o -name '*.dylib*' -o -name '*.a' -o -name '*.o' -o -name '*.d' | sort" ) eq $shouldHaveC or
      confess "'$cleancmd' cleaned out some stuff in libC!";
  }
}

say '##################### basic building tests #######################';
{
  my @targets_should_base = qw(libA/a.o
                               libB/b.o
                               libB/b2.o
                               libC/c.o
                               libC/libC.a
                               libB/libB.a
                               libA/libA.a
                               libA/utila.o
                               libA/subdir/utila_helper.o
                               libA/utila);

  testBuildWithTarget('make', [@targets_should_base, 'libB/utilb', 'libB/utilb.o'] );
  nextTest();

  testBuildWithTarget('make libA', \@targets_should_base );
  nextTest();

  testBuildWithTarget('make -C libA', \@targets_should_base);
  nextTest();

  testBuildWithTarget('make libA/utila', \@targets_should_base);
  nextTest();






  sub testBuildWithTarget
  {
    my $makecmd        = shift;
    my $targets_should = shift;

    ensure( 'make clean' );
    my $commands = ensure( $makecmd );
    my @targets = getRebuiltTargets($commands);

    ensureUnorderedCompare(\@targets, $targets_should );


    # make sure the built application does the expected thing
    my $utila_result = `libA/utila`;
    my $utila_result_should = <<EOF;
a helper
A defined
a
B defined
b
B2 defined
C defined
c
EOF
    if ( $utila_result ne $utila_result_should )
    {
      confess( "utila output is wrong. Should:\n" .
               $utila_result_should . "\n" .
               "instead got\n" .
               $utila_result . "\n" );
    }
  }
}

say '##################### build dependency checks.#######################';
{
  # make sure a rebuild doesn't do anything
  ensure( 'make' );
  if ( ensure( 'make' ) !~ /Nothing to be done/ )
  {
    confess "Rebuild shouldn't do anything";
  }
  nextTest();

  touch('libA/subdir/utila_helper.c');
  ensureRebuild( 'make libA/utila',
                 'libA/subdir/utila_helper.o',
                 'libA/utila' );
  nextTest();

  touch('libC/c.h');
  ensureRebuild( 'make libA/utila',
                 'libB/b.o',
                 'libB/libB.a',
                 'libA/utila' );
  nextTest();







  # makes sure that the given targets are rebuilt in the order specified
  sub ensureRebuild
  {
    my $cmd = shift;
    my @targets = @_;
    my $Ntargets = @targets;

    my $commands = ensure( $cmd );

    my @rebuilt = getRebuiltTargets($commands);
    my $Ntargets_did = @rebuilt;

    confess "Should have rebuilt $Ntargets targets, instead rebuilt $Ntargets_did targets" unless $Ntargets == $Ntargets_did;

    foreach (0..$#targets)
    {
      confess "Should have rebuilt $targets[$_]; instead rebuilt $rebuilt[$_]" if $rebuilt[$_] ne $targets[$_];
    }
  }


}

say '##################### build flag checks #######################';
{
  ensureCommandlineOptions('make');
  nextTest();

  ensureCommandlineOptions("CCXXFLAGS='-DGLOBALFLAG -O3' make");
  nextTest();

  ensureCommandlineOptions("CCXXFLAGS='-I.. -IlibC' LDFLAGS='-L.. -LlibC' make");
  nextTest();

  ensureCommandlineOptions("CCXXFLAGS='-I../.. -I../libC' LDFLAGS='-L../.. -L../libC' make -C libA");
  nextTest();

  # I now made sure that all the variables are used correctly, changing paths as
  # necessary, etc, etc.
  ensure( 'make clean' );
  ensure( "CCXXFLAGS='-Iasdf' make -n", 'shouldfail' );
  ensure( "CCXXFLAGS='-I../bogus_bogus_bogus' make -n", 'shouldfail' );
  ensure( "CCXXFLAGS='-I/bogus_bogus_bogus' make -n", 'shouldfail' );
  ensure( "LDFLAGS='-Lasdf' make -n", 'shouldfail' );
  ensure( "LDFLAGS='-L../bogus_bogus_bogus' make -n", 'shouldfail' );
  ensure( "LDFLAGS='-L/bogus_bogus_bogus' make -n", 'shouldfail' );

  # Now make sure that non-existant paths get picked up and flagged
  ensure( "CCXXFLAGS='-I../asdf' make -n libA", 'shouldfail' );
  ensure( "LDFLAGS='-L../asdf' make -n libA", 'shouldfail' );

  ensure( "CCXXFLAGS='-I../asdf' make -n -C libA", 'shouldfail' );
  ensure( "LDFLAGS='-L../asdf' make -n -C libA", 'shouldfail' );




  sub ensureCommandlineOptions
  {
    my $makecmd = shift;
    my ($CCXXFLAGS) = $makecmd =~ /CCXXFLAGS='(.*?)'/;
    my ($LDFLAGS)   = $makecmd =~ /LDFLAGS='(.*?)'/;
    $CCXXFLAGS //= '';
    $LDFLAGS   //= '';

    my $optimizationOverride;
    $optimizationOverride = ($CCXXFLAGS) =~ /(-O[0-9])/ if $CCXXFLAGS;


    ensure( 'make clean' );
    my $commands = ensure( $makecmd );

    foreach my $cmd (split "\n", $commands)
    {
      if ( $cmd =~ /^ *(?:gcc|g\+\+)/ )
      {
        # compiling or linking
        my @rebuilt = getRebuiltTargets($cmd);
        confess "getRebuiltTargets() thinks that '$cmd' rebuilt " . scalar(@rebuilt) . " targets: @rebuilt" unless @rebuilt == 1;
        my ($target) = @rebuilt;

        # extract the options, leaving out the '-o'
        my @options = grep !/^-o$/, $cmd =~ /-\S+/g;

        if ( $cmd =~ /\s-c/ )
        {
          # compiling

          my @options_should = qw(-DGLOBAL_EXTRA -Werror -Wall -I. -MMD -MP -g -c);

          push @options_should, '-IlibA' if $target =~ m{^libA/};
          push @options_should, "-D$1" if $target =~ m{^lib([ABC])/};
          if ( $target eq 'libB/b2.o' )
          {
            push @options_should, '-DB2';
            push @options_should, '-pedantic';

            # want to add 'unless $optimizationOverride' here, but I don't yet
            # have logic to resolve conflicting -Ox options
            push @options_should, '-O0';
          }
          else
          {
            push @options_should, '-O2' unless $optimizationOverride;
          }

          # add all the non- -I flags
          if ( $CCXXFLAGS )
          {
            push @options_should, grep !/^-I/, split '\s+', $CCXXFLAGS;
          }

          foreach my $Idir ($CCXXFLAGS =~ /-I\s*(\S+)/g)
          {
            if( my ($subdir) = $makecmd =~ /make -C (\S+)/ )
            {
              push @options_should, '-I' . abs_path("$subdir/$Idir")
            }
            else
            {
              push @options_should, '-I' . $Idir;
            }
          }

          ensureUnorderedCompare(\@options, \@options_should)
        }
        else
        {
          # linking
          my @options_should = ();

          # add all the non- -L flags
          if ( $LDFLAGS )
          {
            push @options_should, grep !/^-L/, split '\s+', $LDFLAGS;
          }

          foreach my $Ldir ($LDFLAGS =~ /-L\s*(\S+)/g)
          {
            if( my ($subdir) = $makecmd =~ /make -C (\S+)/ )
            {
              push @options_should, '-L'          . abs_path("$subdir/$Ldir");
              push @options_should, '-Wl,-rpath,' . abs_path("$subdir/$Ldir");
            }
            else
            {
              push @options_should, '-L'          . $Ldir;
              push @options_should, '-Wl,-rpath,' . abs_path($Ldir);
            }
          }

          ensureUnorderedCompare(\@options, \@options_should);
        }
      }
    }
  }
}

say '##################### installation checks #######################';
{
  # make sure stuff fails if we're doing a package-less install
  ensure( 'make install', 'shouldfail' );
  nextTest();


  # make sure install succeeds otherwise
  # make sure correct things actually get installed here
  ensure( 'DESTDIR=/tmp make install' );
  nextTest();
}





say 'ALL TESTS PASS!';
exit;



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

# makes sure the passed-in lists are identical, containing the same elements in ANY order
sub ensureUnorderedCompare
{
  my ($list1, $list2) = @_;

  my $lc = List::Compare->new($list1, $list2);
  if(! $lc->is_LequivalentR() )
  {
    my @Lonly = $lc->get_Lonly;
    my @Ronly = $lc->get_Ronly;
    confess "Mismatched lists!!! List1 has an extra '@Lonly'; List2 has an extra '@Ronly'";
  }

  # List::Compare thinks the lists are equivalent, but since it doesn't look at
  # element multiplicities, they could still be a bit mismatched. I thus run my
  # own comparison here to make sure
  confess "Lists have the same elements, but mismatched multiplicities: '@$list1' and '@$list2'" unless @$list1 == @$list2;

  my (%h1);
  foreach (@$list1)
  {
    $h1{$_} //= 0;
    $h1{$_}++;
  }

  foreach (@$list2)
  {
    unless( $h1{$_} )
    {
      confess "Lists have the same elements, but multiplicity of element '$_' is wrong: '@$list1' and '@$list2'";
    }
    $h1{$_}--;
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

sub getRebuiltTargets
{
  my $commands = shift;

  return ( $commands =~ /(?:-o|rcvu) +(\S+)/g );
}

__END__

- make sure correct flags are used
  - user -O should replace other -O
- rpath
- modified CCXXFLAGS should still work
- all the flags are now additive
- look at the .so building. -fPIC flags



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




should test qt things
