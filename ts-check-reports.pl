#!/usr/bin/env perl

# depends: curl

use feature ":5.24";
use strict;
use warnings;
use Getopt::Std;
use Env;

$main::VERSION = "0.1";
$Getopt::Std::STANDARD_HELP_VERSION = 1;

my %opts = qw(d 0 e 0 h 0 f 0);

if(!getopts('dehf', \%opts)) {
    say STDERR "Invalid arguments, aborting...";
    exit 1;
}

if($opts{h}) {
    usage();
    exit 0;
}

my $release = $opts{d} ? "devel" : "release";
my $repository = $opts{e} ? "data-experiment" : "bioc";
my $package = scalar(@ARGV) == 0 ? 'TargetSearch' : $ARGV[0];
my $url = "https://bioconductor.org/checkResults/$release/$repository-LATEST/";
my $output = "/tmp/ts-$USER-$release-$repository.html";

if($opts{f} || ! -e $output) {
    system("curl", "-sL", "-o", $output, $url) == 0 or die $!;
}

open(IN, "<", $output) or die $!;

while(<IN>) {
    chomp;
    if(/>${package}</) {
        s/&nbsp;/ /g; s/></>#</g; s/<[^>]*>//g;
        s/ *\(landing page\) *//;
        my @fields = split /#+/;
        shift @fields;
        my ($rank, $pkg, $author, @status) = @fields;
        print "$pkg | ", pkg_status(@status), "\n";
    }
}

close IN;

sub trim {
    my $s = shift;
    $s =~ s/^\s+|\s+$//g;
    return $s;
}

sub pkg_status {
    my $warn = 0;
    my $na = 0;
    foreach (@_) {
        $_ = trim($_);
        if($_ eq "ERROR" || $_ eq "TIMEOUT") { return $_; }
        elsif($_ eq "WARNINGS") { $warn = 1; }
        elsif($_ eq "NA") { $na = 1; }
    }
    return $warn ? "WARNINGS" : ($na ? "NA" : "OK");
}

sub usage {
    print <<EOF;
$0 - check for bioconductor build status

DESCRIPTION
  Checks the build status of a bioconductor package by downloading and parsing
  the checkResults page from Bioconductor. The HTML page is stored in /tmp
  and can be re-used if needed.

USAGE
  ts-check-results [-d] [-f] [-e] <PACKAGE>
  ts-check-results -h

OPTIONS
  <PACKAGE>    The package to check, by default is TargetSearch.
  -d           Download the "devel" page instead of "release".
  -e           The package is an experiment package.
  -f           Force download of the report page.
  -h           Show this help.
EOF
}

# vim: set ts=4 sw=4 et:
