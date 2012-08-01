#!/usr/bin/perl
use strict;
use warnings;

my %h;
my $REPO_NAME_ABI_VERSIONED = shift() // die "$0 needs REPO_NAME_ABI_VERSIONED on the cmdline";

my ($REPO_NAME,$ABI_VERSION) = $REPO_NAME_ABI_VERSIONED =~ /(.*?)([0-9.]+)$/
  or die "Couldn't parse repo name, abi version";

open CONTROL, '<', 'debian/control' or die "Couldn't open debian/control";
while(<CONTROL>)
{
  my @F = split;

  if( my ($saw) = /^Source:\s*(.*?)[0-9\.]*$/ )
  {
    if( $REPO_NAME ne $saw )
    {
      die "Saw incorrect Source version in debian/control.\n" .
        "Wanted '$REPO_NAME', but saw '$saw'";
    }
  }

  next unless /^Package:/;

  my ($pkg, $type);
  if ( ($pkg, $type) = $F[1] =~ /^((?:lib).+?)$ABI_VERSION(?:-(dbg|dev))?$/ )
  {
    $type //= "";
    $h{$pkg} //= {};
    $h{$pkg}{$type} = 1;
  }
  elsif ( $F[1] =~ /^lib/ )
  {
    die "Library $F[1] does not follow convention of libxxxx${ABI_VERSION}{-dev,dbg,} in debian/control";
  }
  elsif ( ($pkg, $type) = $F[1] =~ /^(.+?)(?:-(dbg))?$/ )
  {
    $type //= "";
    $h{$pkg} //= {};
    $h{$pkg}{$type} = 1;
  }
  else
  {
    die "This should be unreachable. Please report this as a bug";
  }
}

foreach my $p (keys %h)
{
  if ( !defined $h{$p}{""} )
  {
    die "Package '$p' doesn't have a base defined in debian/control";
  }
  if ( $p =~ /^lib/ && !defined $h{$p}{"dev"} )
  {
    die "Package '$p' doesn't have a -dev defined in debian/control";
  }
}

exit 0;
