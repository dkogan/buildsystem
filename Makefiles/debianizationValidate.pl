#!/usr/bin/perl
use strict;
use warnings;
use feature qw(say);
use Debian::Control;

# This script checks the debian/control and debian/changelog files for
# self-consistency. It also makes sure that the packages defined in
# debian/control follow the guidelines mandated by the build system. The ONLY
# output of this script is the true/false exit value


my $repo_name_versioned = shift
  or die "Must get versioned repo name on the commandline, such as 'gspeak3.2'";

my ($repo_name, $pkg_version, $abi_version) = getVersionFromChangelog()
  or die "Couldn't parse versions from debian/changelog";

die <<EOF unless $repo_name_versioned eq "$repo_name$abi_version";
Makefiles think versioned repo name is '$repo_name_versioned'
but validation script thinks it's '$repo_name$abi_version'
EOF



my ($sourcepkg, $pkgs) = parseControl();

if( $sourcepkg->Source ne $repo_name )
{
  die "debian/control and debian/changelog disagree about the repo name:\n" .
    "'$sourcepkg->Source' vs '$repo_name'";
}



# go through all the debian/control stanzas, and make sure all the Package names
# conform to our naming convention
my %modules;
for my $pkgname($pkgs->Keys)
{
  if( $pkgname =~ /^lib/ )
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
for my $pkg($pkgs->Values)
{
  my $name = $pkg->Package;
  if( $name =~ /^lib/ )
  {
    if( my ($unversioned, $type) =
        $name =~ /^(liboblong-.*?)$abi_version(?:-(dbg|dev))?$/ )
    {
      if( $type )
      {
        $unversioned .= "-$type";
      }

      die "Package $name: -dev packages must be in Section non-free/libdevel in debian/control"
        if $type && $type eq 'dev' && $pkg->Section ne 'non-free/libdevel';

      die "Package $name: -dbg packages must be in Section non-free/debug in debian/control"
        if $type && $type eq 'dbg' && $pkg->Section ne 'non-free/debug';

      # $pkg->Provides() is a list-ref or a single element. If it's a lone
      # element, I convert it to a list-ref (this is consistent in
      # Debian/unstable, but has the dual behavior in Ubuntu/lucid)
      my $provides = $pkg->Provides() // [];
      $provides = [$provides] unless ref $provides;
      my %provides = map {$_ => 1} @$provides;

      unless( $provides{$unversioned} )
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
exit 0;








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
  # There's an issue with Debian::Control where comments in debian/control
  # confuse it. I thus read the file myself, strip the comments, and pass that
  # data on to Debian::Control
  open F, '<', 'debian/control' or die "Couldn't open debian/control";
  my @lines = <F>;
  close F;

  my $control = join('', grep !/^#/, @lines);

  my $c = Debian::Control->new;;
  eval { $c->read( \$control ) };
  die "Error parsing debian/control: $@" if $@;

  return ($c->source, $c->binary);
}
