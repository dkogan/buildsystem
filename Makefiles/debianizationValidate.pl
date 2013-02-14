#!/usr/bin/perl
use strict;
use warnings;
use feature qw(say);
use Debian::Control;

# This script checks the debian/control and debian/changelog files for
# self-consistency. It also makes sure that the packages defined in
# debian/control follow the guidelines mandated by the build system. This script
# returns a true/false exit value. On error, messages are printed to the console
# also

my $usage = "Usage: $0 repo_name_versioned [--uses-debsums packagename]";

# If executed with one argument, this is a Makefile-parsing-time check.
#
# If executed with three arguments, this runs at the end of the 'make install'
# for that package ONLY IF that package uses the upstart template

my ($sourcepkg, $pkgs) = parseControl();

if( @ARGV == 1)
{
  my $repo_name_versioned = shift
    or die "Must get versioned repo name on the commandline, such as 'gspeak3.2'";

  parsingTimeChecks( $repo_name_versioned );
}
elsif( @ARGV == 3 )
{
  if( $ARGV[1] ne '--uses-debsums' )
  {
    die "Unknown 2nd argument\n" . $usage;
  }

  my ($package_name) = $ARGV[2];
  installTimeChecks_usesdebsums($package_name);
}
else
{
  die $usage;
}

exit 0;






sub parsingTimeChecks
{
  my $repo_name_versioned = shift;

  my ($repo_name, $pkg_version, $abi_version) = getVersionFromChangelog()
    or die "Couldn't parse versions from debian/changelog";

  die <<EOF unless $repo_name_versioned eq "$repo_name$abi_version";
Makefiles think versioned repo name is '$repo_name_versioned'
but validation script thinks it's '$repo_name$abi_version'
EOF



  if ( $sourcepkg->Source ne $repo_name )
  {
    die "debian/control and debian/changelog disagree about the repo name:\n" .
      "'$sourcepkg->Source' vs '$repo_name'";
  }



  # go through all the debian/control stanzas, and make sure all the Package names
  # conform to our naming convention
  my %modules;
  for my $pkgname ($pkgs->Keys)
  {
    if ( $pkgname =~ /^lib/ )
    {
      my $errormsg_base =
        "Package '$pkgname' in debian/control doesn't conform to our naming convention of 'liboblong-\$NAME\$ABIVERSION(-dbg|-dev)?':\n";

      die $errormsg_base . "Library packages must be named 'liboblong-..."
        unless $pkgname =~ /^liboblong-(.*)/;

      my $libsuffix = $1;

      my ($name_ver, $type) = $libsuffix =~ /(.*?)(?:-(dbg|dev))?$/;
      $type ||= 'base';

      my ($name) = $name_ver =~ /(.*)$abi_version$/
        or die $errormsg_base .
        "Couldn't find abi_version. I think abi_version is '$abi_version'.\n" .
        "It should be the last piece of '$name_ver'";

      $name = "lib$name";

      die "Library '$name' of type '$type' defined multiple times in debian/control"
        if exists $modules{$name}{$type};

      $modules{$name}{$type} = 1;
    }
    else
    {
      my $errormsg_base =
        "Package '$pkgname' doesn't conform to our naming convention of 'oblong-\$NAME(-dbg)?':\n";

      die $errormsg_base . "Non-library packages must be named 'oblong-..."
        unless $pkgname =~ /^oblong-(.*)/;

      my $suffix = $1;

      my ($name, $type) = $suffix =~ /(.*?)(?:-(dbg))?$/;
      $type ||= 'base';

      die "Module '$name' of type '$type' defined multiple times in debian/control"
        if exists $modules{$name}{$type};

      $modules{$name}{$type} = 1;
    }
  }


  # Now make sure that each library has a base a -dev and a -dbg, and that each
  # non-library has a base and a -dbg. Generally all packages should provide a
  # -dbg, but I only require this for libraries, since non-libraries may not have
  # any compiled code in them (could be settings, for instance)
  foreach my $name (keys %modules)
  {
    die "Module $name is missing the base package" if !$modules{$name}{base};
    die "Module $name is missing the -dbg package" if !$modules{$name}{dbg} && $name =~ /^lib/;;
    die "Module $name is missing the -dev package" if !$modules{$name}{dev} && $name =~ /^lib/;
  }


  # Make sure each library Provides an unversioned package and that the sections are correct
  for my $pkg ($pkgs->Values)
  {
    my $name = $pkg->Package;
    if ( $name =~ /^lib/ )
    {
      if ( my ($unversioned, $type) =
           $name =~ /^(liboblong-.*?)$abi_version(?:-(dbg|dev))?$/ ) {
        if ( $type )
        {
          $unversioned .= "-$type";
        }

        die "Package $name: -dev packages must be in Section non-free/libdevel in debian/control"
          if $type && $type eq 'dev' && $pkg->Section ne 'non-free/libdevel';

        die "Package $name: -dbg packages must be in Section non-free/debug in debian/control"
          if $type && $type eq 'dbg' && $pkg->Section ne 'non-free/debug';


        # The Debian::Control module in ubuntu/lucid returns a comma-separated
        # list, while the one in debian/unstable (much more recent) returns
        # list-refs. I have some logic here to work with both
        my $provides = $pkg->Provides();
        if ( !defined $provides )
        {
          $provides = [];
        }
        elsif ( !ref $provides )
        {
          $provides = [split '\s*,\s*', $provides];
        }



        $provides = [$provides] unless ref $provides;
        my %provides = map {$_ => 1} @$provides;

        unless ( $provides{$unversioned} )
        {
          die
            "$name: Each versioned library must Provide the unversioned name.\n" .
            "debian/control stanza for Package '$name' MUST have a line that says\n" .
            "'Provides: $unversioned'";
        }
      }
      else
      {
        die "Error in $0. Please report this as a bug";
      }
    }
  }
}


sub installTimeChecks_usesdebsums
{
  my ($package_name) = @_;

  # We have an upstart configuration, so make sure there's a 'debsums'
  # dependency. This is used in the upstart script to make a useful log. Note
  # that this dependency must appear explicitly. It can NOT come in as a subst
  # variable, since this validation script runs before those are expanded
  my $pkg = $pkgs->FETCH($package_name);
  die "Unknown package $package_name" unless defined $pkg;

  if ( !hasDebsumsDependency( $pkg ) )
  {
    die <<EOF;
Package $package_name uses debsums in its upstart template, but does not have a debsums
dependency. Please add this dependency to debian/control. Note that this dependency
must be explicit, and cannot come from a substitution variable.
EOF
    }
}

sub getVersionFromChangelog
{
  open F, '<', 'debian/changelog' or die "Couldn't open debian/changelog";

  # First line should be something like
  #
  # buildsystem-unittests (5.6.7) unstable; urgency=low
  #
  # I grab the repo name and the version number;
  <F> =~ /^(\S+) \s* # repo name
          \((.*?)\)  # version
         /x or die "Couldn't parse debian/changelog";

  my $name        = $1;
  my $pkg_version = $2;

  # strip out any trailing non-numbers, non-periods. This allows versions such
  # as 3.2ubuntu1 or 3.2~ubuntu1 to be treated simply as '3.2'.
  $pkg_version =~ s/(^[0-9\.]+).*/$1/;

  # version number is some number of tokens separated by '.', for example:
  # a.b.c.d.e.f
  # All but the last token are treated as the ABI version, so in this case,
  # everything except the '.f' is the ABI version
  my ($abi_version) = $pkg_version =~ /(.*)\..*?$/;

  close F;
  return ($name, $pkg_version, $abi_version);
}

sub parseControl
{
  # Here I read and parse debian/control using Debian::Control (which uses
  # Parse::DebControl internally). Those CPAN modules have various bugs in
  # ubuntu/lucid, which requires workarounds. Here I manually strip away
  # comments and Breaks tags to make the older parsers happy
  open F, '<', 'debian/control' or die "Couldn't open debian/control";
  my @lines = <F>;
  close F;

  my $control = join('', grep !/^(?:#|Breaks)/, @lines);

  my $c = Debian::Control->new;;
  eval { $c->read( \$control ) };
  die "Error parsing debian/control: $@" if $@;

  return ($c->source, $c->binary);
}

sub hasDebsumsDependency
{
  my $pkg = shift;
  my @alldeps = split '\s*,\s*', $pkg->Depends;

  return grep {$_ eq 'debsums'} @alldeps;
}

