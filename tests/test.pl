#!/usr/bin/perl
use strict;
use warnings;
use feature qw(say state);
use IPC::Run qw(run);
use Carp qw(confess);
use Data::Dumper;
use List::Compare;
use Cwd qw(abs_path);

# debhelper likes to turn on some Make flags when building packages, but these
# confuse the tests, so I turn these off here
for my $k(keys %ENV)
{
  delete $ENV{$k} if $k =~ /FLAGS/;
}


my $utila_result_should = <<EOF;
a helper
A defined
a
B defined
b
B2 defined
C defined
GLOBAL_EXTRA: 7
GLOBAL_EXTRA_OTHER: 55
c
gen: 5
B defined
b
B2 defined
C defined
GLOBAL_EXTRA: 7
GLOBAL_EXTRA_OTHER: 55
c
gen: 5
EOF

my $utila2_result_should = <<EOF;
utila 2
UTILA2 defined
A defined
a
B defined
b
B2 defined
C defined
GLOBAL_EXTRA: 7
GLOBAL_EXTRA_OTHER: 55
c
gen: 5
EOF

my $utilb_result_should = <<EOF;
B defined
b
B2 defined
C defined
GLOBAL_EXTRA: 7
GLOBAL_EXTRA_OTHER: 55
c
gen: 5
EOF

my $main_result_should = <<EOF;
A defined
a
B defined
b
B2 defined
C defined
GLOBAL_EXTRA: 7
GLOBAL_EXTRA_OTHER: 55
c
gen: 5
EOF



# The toy project is very simple: libA depends on libB depends on libC. The
# libA/utila executable calls simple functions in each of the sub-libraries.
# This is set up this way to make sure that the implicit dependency of libA on
# libC is handled properly

say '##################### clean tests #######################';
{
  say '------ make sure I can clean out the tree without leaving any known cruft behind ------';
  ensure( 'make' );
  ensure( 'make clean' );
  cleanDebianDir();
  system( 'rm -rf localinstall' );
  nextTest();

  my $leftovers = leftoverIn();
  confess "'make clean' didn't clean out everything. Leftovers:\n" . $leftovers if $leftovers;
  nextTest();

  testCleanWithCmd( 'make -C libA clean' );
  nextTest();

  testCleanWithCmd( 'make libA/clean' );
  nextTest();






  sub testCleanWithCmd
  {
    my $cleancmd = shift;

    say "------- Making sure '$cleancmd' cleans out just what it should";
    ensure( 'make' );
    my $shouldHaveA    = leftoverIn('libA');
    my $shouldHaveB    = leftoverIn('libB');
    my $shouldHaveC    = leftoverIn('libC');
    my $shouldHaveUtil = leftoverIn('util');

    ensure( $cleancmd );
    my $leftovers = leftoverIn('libA');
    confess "'$cleancmd' didn't clean out everything in libA. Leftovers:\n" . $leftovers if $leftovers;

    leftoverIn('libB') eq $shouldHaveB or
      confess "'$cleancmd' cleaned out some stuff in libB!";

    leftoverIn('libC') eq $shouldHaveC or
      confess "'$cleancmd' cleaned out some stuff in libC!";

    leftoverIn('util') eq $shouldHaveUtil or
      confess "'$cleancmd' cleaned out some stuff in util!";
  }

  sub leftoverIn
  {
    my $dir = shift;

    # libC/c.*.h is for generated headers
    my $files = '**/*.(so*|dylib|a|o|d) libC/c.*.h util/ma?n';

    my @all = split '\s+', ensure( "echo $files" );
    if( !defined $dir )
    {
      return join(' ', @all);
    }

    return join(' ', grep m{^$dir/}, @all);
  }
}

say '##################### basic building/execution tests #######################';
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

  testBuildWithTarget('make libA', [@targets_should_base, qw(libA/utila2.o libA/utila2)] );
  nextTest();

  testBuildWithTarget('make -C libA', [@targets_should_base, qw(libA/utila2.o libA/utila2)] );
  nextTest();

  testBuildWithTarget('make libA/utila', \@targets_should_base);
  nextTest();

  testBuildWithTarget('make', [@targets_should_base, qw(libA/utila2.o libA/utila2 libB/utilb libB/utilb.o util/main util/main.o) ] );
  nextTest();




  say '------ making sure the built applications do the expected thing -------';
  foreach ( ['libA/utila', $utila_result_should],
            ['libA/utila2',$utila2_result_should],
            ['libB/utilb', $utilb_result_should],
            ['util/main',  $main_result_should] )
  {
    my ($cmd, $should) = @$_;

    my $result  = ensure( $cmd );

    if ( $result ne $should )
    {
      confess( "$cmd output is wrong. Should:\n" .
               $should . "\n" .
               "instead got\n" .
               $result . "\n" );
    }
  }




  sub testBuildWithTarget
  {
    my $makecmd        = shift;
    my $targets_should = shift;
    say "------ Making sure '$makecmd' succeeds and builds the right things";

    ensure( 'make clean' );
    my $commands = ensure( $makecmd );
    my @targets = getRebuiltTargets($commands);

    ensureUnorderedCompare(\@targets, $targets_should );
  }
}

say '##################### build dependency checks.#######################';
{
  say '------ making sure a rebuild does not do anything ------';
  ensure( 'make' );
  if ( ensure( 'make' ) !~ /Nothing to be done/ )
  {
    confess "Rebuild shouldn't do anything";
  }
  nextTest();

  say '------ making sure build dependecies trigger rebuilds correctly ------';
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

  say '----- Making sure the build flags change their paths as needed --------';

  # I now made sure that all the variables are used correctly, changing paths as
  # necessary, etc, etc.
  ensureCommandlineOptions("CCXXFLAGS='-I.. -IlibC' LDFLAGS='-L.. -LlibC' make");
  nextTest();

  ensureCommandlineOptions("CCXXFLAGS='-I../.. -I../libC' LDFLAGS='-L../.. -L../libC' make -C libA");
  nextTest();

  cleanDebianDir();
  ensureCommandlineOptions("DESTDIR=asdf make install");
  nextTest();

  say '------ making sure that non-existent paths get picked up and flagged ------';
  ensure( 'make clean' );
  ensure( "CCXXFLAGS='-Iasdf' make -n",                 'shouldfail' );
  ensure( "CCXXFLAGS='-I../bogus_bogus_bogus' make -n", 'shouldfail' );
  ensure( "CCXXFLAGS='-I/bogus_bogus_bogus' make -n",   'shouldfail' );
  ensure( "LDFLAGS='-Lasdf' make -n",                   'shouldfail' );
  ensure( "LDFLAGS='-L../bogus_bogus_bogus' make -n",   'shouldfail' );
  ensure( "LDFLAGS='-L/bogus_bogus_bogus' make -n",     'shouldfail' );
  ensure( "CCXXFLAGS='-I../asdf' make -n libA",         'shouldfail' );
  ensure( "LDFLAGS='-L../asdf' make -n libA",           'shouldfail' );
  ensure( "CCXXFLAGS='-I../asdf' make -n -C libA",      'shouldfail' );
  ensure( "LDFLAGS='-L../asdf' make -n -C libA",        'shouldfail' );


  say '------ making sure that the variable override is working ------';
  ensure( "BLOCK_OVERRIDE=1 make -n -C libC",            'shouldfail' );




  sub ensureCommandlineOptions
  {
    my $makecmd = shift;
    say "------ Making sure '$makecmd' uses the correct build flags";

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
        say "Checking build flags for $target";

        # extract the options, leaving out the '-o'
        my @options_did = grep !/^-o$/, $cmd =~ /-\S+/g;


        if ( $cmd =~ /\s-c/ )
        {
          # compiling

          my @options_should = qw(-Werror -Wall -I. -MMD -MP -g -c);

          if( $target =~ m{^libC/} )
          {
            push @options_should, '-DGLOBAL_EXTRA=7';
            push @options_should, '-DGLOBAL_EXTRA_OTHER=55';
          }
          else
          {
            push @options_should, '-DGLOBAL_EXTRA=3';
            push @options_should, '-DGLOBAL_EXTRA_OTHER=33';
          }
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

          if( $target =~ /utila2.o/ )
          {
            push @options_should, '-DUTILA2';
          }

          # shared library objects get -fPIC
          if( $target =~ m{/[abc]2?\.o} )
          {
            push @options_should, '-fPIC';
          }

          ensureUnorderedCompare(\@options_did, \@options_should)
        }
        else
        {
          # linking
          my @options_should = ();

          # First, figure out if the linker has --copy-dt-needed-entries, to
          # know if I should look for it in the flags
          state $haveCopyDtNeeded;
          $haveCopyDtNeeded = `ld --copy-dt-needed-entries 2>&1` !~ /unrecognized|unknown/ unless defined $haveCopyDtNeeded;
          push @options_should, '-Wl,--copy-dt-needed-entries' if $haveCopyDtNeeded;

          my $installing = $makecmd =~ / install$/;

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

          my $LDLIBS_SYSTEM_libA = '-lm';
          my $LDLIBS_SYSTEM_libC = '-lstdc++';
          if( (!$installing && $target =~ /util[ab]|main/) || $target =~ m{libC/} )
          {
            # utils in libA and libB need to depend on libC's LDLIBS
            push @options_should, $LDLIBS_SYSTEM_libC;
          }
          if( (!$installing && $target =~ /utila|main/)  || $target =~ m{libA/} )
          {
            # utils in libA also need to depend on libA's LDLIBS
            push @options_should, $LDLIBS_SYSTEM_libA;
          }
          if( $target =~ /utila2/ )
          {
            # utila2 also has it's own custom extra options
            push @options_should, '-Wl,--stats';
            push @options_should, '-lc';
          }

          if( $target =~ m{/(.*?\.so\.5\.6)\.7} )
          {
            my $soname = $1;
            push @options_should, "-Wl,-soname,$soname";
            push @options_should, "-Wl,--default-symver";
            push @options_should, '-fPIC';
            push @options_should, '-shared';
          }
          elsif( $installing )
          {
            my $rplink_libA = '-Wl,-rpath-link,' . abs_path('./libA');
            my $rplink_libB = '-Wl,-rpath-link,' . abs_path('./libB');
            my $rplink_libC = '-Wl,-rpath-link,' . abs_path('./libC');
            push @options_should, $rplink_libC;
            push @options_should, $rplink_libB if $target =~ /libA|main/;
            push @options_should, $rplink_libA if $target =~ /main/;
          }


          ensureUnorderedCompare(\@options_did, \@options_should);
        }
      }
    }
  }
}

say '##################### installation checks #######################';
{
  say '------ make sure stuff fails if we attempt a package-less install ------';
  ensure( 'make install', 'shouldfail' );
  nextTest();

  say '------ make sure an install succeeds otherwise -------';
  ensure( "DESTDIR=asdf make install" );
  {
    say '------- make sure the right files got installed ------';
    my $files = ensure( "echo debian/**/*~debian/changelog~debian/control(.) | xargs -n1 | sort" );
    my $links = ensure( "echo debian/**/*(@) | xargs -n1 | sort" );

    my $files_should = <<EOF;
debian/liboblong-a5.6-dev/usr/lib/buildsystem-unittests5.6/libA.a
debian/liboblong-a5.6/usr/bin/utila
debian/liboblong-a5.6/usr/bin/utila2
debian/liboblong-a5.6/usr/lib/libA.so.5.6.7
debian/liboblong-b5.6-dev/usr/lib/buildsystem-unittests5.6/libB.a
debian/liboblong-b5.6/usr/bin/utilb
debian/liboblong-b5.6/usr/lib/libB.so.5.6.7
debian/liboblong-c5.6-dev/usr/include/buildsystem-unittests5.6/libC/c.generated.h
debian/liboblong-c5.6-dev/usr/include/buildsystem-unittests5.6/libC/c.h
debian/liboblong-c5.6-dev/usr/lib/buildsystem-unittests5.6/libC.a
debian/liboblong-c5.6/usr/lib/libC.so.5.6.7
debian/oblong-test-utility/usr/bin/main
EOF

    my $links_should = <<EOF;
debian/liboblong-a5.6-dev/usr/lib/buildsystem-unittests5.6/libA.so
debian/liboblong-a5.6/usr/lib/libA.so.5.6
debian/liboblong-b5.6-dev/usr/lib/buildsystem-unittests5.6/libB.so
debian/liboblong-b5.6/usr/lib/libB.so.5.6
debian/liboblong-c5.6-dev/usr/lib/buildsystem-unittests5.6/libC.so
debian/liboblong-c5.6/usr/lib/libC.so.5.6
EOF

    if ( $files ne $files_should )
    {
      confess "Installed files mismatch. Should have had\n" . $files_should . "\n" .
        "but instead got\n" . $files . "\n";
    }
    if ( $links ne $links_should )
    {
      confess "Installed links mismatch. Should have had\n" . $links_should . "\n" .
        "but instead got\n" . $links . "\n";
    }

    # we just build dynamically-linked executables, so they should have been
    # removed by make so that the user can't accidentally run them
    foreach (qw(libA/utila util/main libA/utila2 libB/utilb))
    {
      confess "Intermediate target $_ wasn't cleaned up" if -e $_;
    }

    say '------ Making sure the installed executables run correctly -------';


  }
  nextTest();
  checkDtNeeded( 'debian', undef );

  say '------ make sure the built exes break without LD_LIBRARY_PATH -------';
  ensure( 'debian/liboblong-a5.6/usr/bin/utila',      'shouldfail' );
  ensure( 'debian/liboblong-a5.6/usr/bin/utila2',     'shouldfail' );
  ensure( 'debian/liboblong-b5.6/usr/bin/utilb',      'shouldfail' );
  ensure( 'debian/oblong-test-utility/usr/bin/main','shouldfail' );

  say '------ make sure the built exes run with LD_LIBRARY_PATH -------';
  foreach ( ['LD_LIBRARY_PATH=$PWD/debian/liboblong-a5.6/usr/lib:$PWD/debian/liboblong-b5.6/usr/lib:$PWD/debian/liboblong-c5.6/usr/lib debian/liboblong-a5.6/usr/bin/utila',      $utila_result_should],
            ['LD_LIBRARY_PATH=$PWD/debian/liboblong-a5.6/usr/lib:$PWD/debian/liboblong-b5.6/usr/lib:$PWD/debian/liboblong-c5.6/usr/lib debian/liboblong-a5.6/usr/bin/utila2',     $utila2_result_should],
            ['LD_LIBRARY_PATH=$PWD/debian/liboblong-a5.6/usr/lib:$PWD/debian/liboblong-b5.6/usr/lib:$PWD/debian/liboblong-c5.6/usr/lib debian/liboblong-b5.6/usr/bin/utilb',      $utilb_result_should],
            ['LD_LIBRARY_PATH=$PWD/debian/liboblong-a5.6/usr/lib:$PWD/debian/liboblong-b5.6/usr/lib:$PWD/debian/liboblong-c5.6/usr/lib debian/oblong-test-utility/usr/bin/main',$main_result_should] )
  {
    my ($cmd, $should) = @$_;

    my $result  = ensure( $cmd );

    if ( $result ne $should )
    {
      confess( "$cmd output is wrong. Should:\n" .
               $should . "\n" .
               "instead got\n" .
               $result . "\n" );
    }
  }
  say "\n";



  system( "rm -rf localinstall" );
  ensure( "make localinstall" );
  {
    say '------- localinstall: make sure the right files got installed ------';
    my $files = ensure( "echo localinstall/**/*(.) | xargs -n1 | sort" );
    my $links = ensure( "echo localinstall/**/*(@) | xargs -n1 | sort" );

    my $files_should = <<EOF;
localinstall/usr/bin/main
localinstall/usr/bin/utila
localinstall/usr/bin/utila2
localinstall/usr/bin/utilb
localinstall/usr/include/buildsystem-unittests5.6/libC/c.generated.h
localinstall/usr/include/buildsystem-unittests5.6/libC/c.h
localinstall/usr/lib/buildsystem-unittests5.6/libA.a
localinstall/usr/lib/buildsystem-unittests5.6/libB.a
localinstall/usr/lib/buildsystem-unittests5.6/libC.a
localinstall/usr/lib/libA.so.5.6.7
localinstall/usr/lib/libB.so.5.6.7
localinstall/usr/lib/libC.so.5.6.7
EOF

    my $links_should = <<EOF;
localinstall/usr/lib/buildsystem-unittests5.6/libA.so
localinstall/usr/lib/buildsystem-unittests5.6/libB.so
localinstall/usr/lib/buildsystem-unittests5.6/libC.so
localinstall/usr/lib/libA.so.5.6
localinstall/usr/lib/libB.so.5.6
localinstall/usr/lib/libC.so.5.6
EOF

    if ( $files ne $files_should )
    {
      confess "Local-installed files mismatch. Should have had\n" . $files_should . "\n" .
        "but instead got\n" . $files . "\n";
    }
    if ( $links ne $links_should )
    {
      confess "Local-installed links mismatch. Should have had\n" . $links_should . "\n" .
        "but instead got\n" . $links . "\n";
    }

    # localinstall-ed executables have static linking, so they aren't automatically deleted by make
  }
  nextTest();
  # localinstall-ed executables have static linking, so ask for it here
  checkDtNeeded( 'localinstall', 1 );

  say '------ make sure the localinstall exes run without LD_LIBRARY_PATH -------';
  foreach ( ['localinstall/usr/bin/utila', $utila_result_should],
            ['localinstall/usr/bin/utila2',$utila2_result_should],
            ['localinstall/usr/bin/utilb', $utilb_result_should],
            ['localinstall/usr/bin/main',  $main_result_should] )
  {
    my ($cmd, $should) = @$_;

    my $result  = ensure( $cmd );

    if ( $result ne $should )
    {
      confess( "$cmd output is wrong. Should:\n" .
               $should . "\n" .
               "instead got\n" .
               $result . "\n" );
    }
  }







  # makes sure all the dynamically-linked executables under $dir have the correct
  # DT_NEEDED tags
  sub checkDtNeeded
  {
    my $dir        = shift;
    my $static_exe = shift;

    say "------- Making sure that the libraries, executables in '$dir' have correct DT_NEEDED flags ------";

    check($dir, 'libA.so.5.6.7');
    check($dir, 'libB.so.5.6.7');
    check($dir, 'libC.so.5.6.7');
    check($dir, 'main',  $static_exe );
    check($dir, 'utila', $static_exe );
    check($dir, 'utila2',$static_exe );
    check($dir, 'utilb', $static_exe );



    sub check
    {
      my ($dir, $fil, $static_exe) = @_;
      my @paths = split '\s+', ensure( "echo $dir/**/$fil" );
      if ( @paths > 1 )
      {
        confess "was looking for a single $dir/**/$fil, but found multiple";
      }
      if ( @paths < 1)
      {
        confess "was looking for a single $dir/**/$fil, but found none";
      }

      say "------- Making sure that $paths[0] has correct DT_NEEDED flags ------";


      my @needed = split "\n", ensure( "objdump -p $paths[0] | awk '/NEEDED/ {print \$2}'" );
      my $lc1 = List::Compare->new(\@needed, [qw(libA.so.5.6 libB.so.5.6 libC.so.5.6)]);
      my @intersection = $lc1->get_intersection;

      # libA should depend only on libB
      # libB should depend only on libC
      # libC should depend on none
      if( $fil =~ /libA/ )
      {
        confess "Incorrect DT_NEEDED tag. libA should depend on libB" unless
          @intersection == 1 && $intersection[0] eq 'libB.so.5.6';
      }
      if( $fil =~ /libB/ )
      {
        confess "Incorrect DT_NEEDED tag. libB should depend on libC" unless
          @intersection == 1 && $intersection[0] eq 'libC.so.5.6';
      }
      if( $fil =~ /libC/ )
      {
        confess "Incorrect DT_NEEDED tag. libC should depend on no local libs" unless
          @intersection == 0;
      }

      # executables should depend on their local library, unless they're linked
      # statically. Static linking says they depend on nothing, since the
      # library is INSIDE the executable
      if( $fil =~ /util[ab]/ )
      {
        if( $static_exe )
        {
          confess "$fil should have been linked statically, but instead it depends on '@intersection'" unless
            @intersection == 0;
        }
        else
        {
          my $libthis = $fil;
          $libthis =~ s/util([ab]).*/'lib' . uc($1) . '.so.5.6'/e;

          my @depends_should = ($libthis);
          push @depends_should, 'libB.so.5.6' if $fil eq 'utila';

          my $lc2 = List::Compare->new(\@intersection, \@depends_should);
          confess "Locally, $fil MUST depend EXACTLY on '@depends_should', but instead it depends on '@intersection'" unless $lc2->is_LequivalentR();
        }
      }
    }
  }

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
  my $success   = run ['zsh', '--extendedglob', '--nullglob', '-c', $cmd], \undef, \$result, '2>&1';
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

sub cleanDebianDir
{
  ensure( 'rm -rf debian/*~debian/changelog~debian/control' );
}

__END__

- make sure correct flags are used
  - user -O should replace other -O
- modified CCXXFLAGS should still work
- all the flags are now additive
- make sure checkPackageNames.pl does the right thing; make some wrongly-versioned package names

should test qt things
