#!/usr/bin/env perl

use feature ":5.24";
use strict;
use warnings;
use Getopt::Std;
use Env;

$main::VERSION = "0.2";
$Getopt::Std::STANDARD_HELP_VERSION = 1;

# remove all tags from a line
sub untag {
    my $str = shift;
    while($str =~ s/<.*?>//) {
        next;
    }
    return $str;
}

# remove extra spaces and fix stuff
sub fixline {
    my $line = shift;
    $line =~ s/&nbsp;/ /g;
    $line =~ s/^ +//;
    $line =~ s/ +$//;
    return $line;
}

# parse the server portion of the page
sub parse_server {
    my $str = shift;
    my @fields = ();
    while(length($str) > 0) {
        if(($str =~ m|<td[^>]*>(.*?)</td>|ip)) {
            my $x = untag($1);
            push(@fields, $x);
            $str = ${^POSTMATCH};
        }
        else {
            last;
        }
    }
    return @fields;
}

# underline string
sub ul {
    my $str = shift;
    return "\033[4m". $str . "\033[0m";
}

# add style to package's git information
sub style {
    my $str = shift;
    my ($it, $nc, $cl) = ("\033[3m", "\033[0m", "\033[38;5;104m");
    $str =~ s/([^:]+):/$cl$it$1$nc:/;
    return $str;
}

# parse type string
sub gettype {
    my %types = qw(bioc bioc exp data-experiment ann data-annotation gpu bioc-gpu);
    my $arg = shift;
    if(!exists($types{$arg})) {
        say STDERR "\033[31;1mError:\033[0m Invalid argument `$arg`";
        exit 1;
    }
    return $types{$arg};
}

#####################################################################

# parse options
my %opts =  qw(r 0 h 0 f 0 t bioc);

if(!getopts('rhft:', \%opts)) {
    say STDERR "\033[31;1mError:\033[0m Invalid arguments";
    exit 1;
}

if($opts{h}) {
    usage();
    exit 0;
}

# process arguments
my $release =  $opts{r} ? "release" : "devel";
my $type = gettype($opts{t});
my $package = scalar(@ARGV) > 0 ? $ARGV[0] : "TargetSearch";
my $url = "https://bioconductor.org/checkResults/$release/$type-LATEST/$package/";
my $output = "/tmp/ts-$USER-$release-$type-$package.html";

say "$url";
# download file
if(! -e $output || $opts{f} ) {
    system("curl", "-sL", "-o", $output, $url) == 0 or die $!;
}

# https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
my %codes = (
    'OK'       => "\033[32;1mOK       \033[0m",
    'ERROR'    => "\033[31;1mERROR    \033[0m",
    'WARNINGS' => "\033[33;1mWARNINGS \033[0m",
    'NA'       => "\033[2mNA       \033[0m",
    'skipped'  => "\033[1mskipped  \033[0m",
    'TIMEOUT'  => "\033[34;1mTIMEOUT  \033[0m"
);

my ($flag, $hasbin) = (0, 0);
my %nfo = ( 'git' => [] );
my @stats;

open(IN, "<", $output) or die $!;

while (<IN>) {
    chomp;
    if(/Page Not Found/) {
        say STDERR "\033[31;1mError:\033[0;1m Package not found\033[0m";
        exit 1;
    }
    elsif(/svn_info/) { # contains important info
        $flag = 1;
        my $line = fixline(untag($_));
        if($line =~ /^(.+).landing page.(.+)$/) {
            $nfo{'package'} = fixline($1);
            $nfo{'author'} = fixline($2);
        } else {
            push(@{$nfo{'git'}}, $line);
        }
        next;
    }
    elsif(/class="footer"/) { # last line
        last;
    }
    elsif(/BUILD BIN/) {
        $hasbin = 1;
    }
    elsif($flag == 1) {
        my @x = parse_server($_);
        my @st = ();
        foreach (@x) {
            my $line = fixline($_);
            if($line ne "") {
                push(@st, $line);
            }
        }
        if(scalar(@st) > 0) {
            push(@stats, \@st);
        }
    }
}

close IN;

print "\n \033[0;1m$nfo{'package'}\033[0m - \033[3m$nfo{'author'}\033[0m\n\n";

foreach (@{$nfo{'git'}}) {
    print " ", style($_), "\n";
}

print sprintf("\n %-19s %-46s %s    %s      %s",
    ul('Hostname'), ul('OS / Arch'), ul('INSTALL'), ul('BUILD'), ul('CHECK'));
if($hasbin) {
    print sprintf("      %s", ul('BUILD BIN'));
}
print "\n";

foreach my $st (@stats) {
    print sprintf(" \033[1m%-10s\033[0m  %-39s", $$st[0], $$st[1]);
    foreach my $code (@$st[2..$#$st]) {
        my $str = exists($codes{$code}) ? $codes{$code} : $code;
        print "$str  ";
    }
    print("\n");
}

print("\n");

sub usage {
    print <<EOF;
$0 - check for bioconductor build status

DESCRIPTION
  Checks the build status of a Bioconductor package by downloading and parsing
  the package's status web page. The HTML page is stored in /tmp so it can be
  reused if needed.

USAGE
  ts-check-results [-r] [-f] [-t <TYPE>] <PACKAGE>
  ts-check-results -h

OPTIONS
  <PACKAGE>  The package to check. Defaults to `TargetSearch` (case senstive).
  -r         Check for the `release` page (default is to check for devel).
  -f         Force download of the report page.
  -t <TYPE>  Type of package. Accepted values are 'bioc', 'exp', 'ann', 'gpu'.
  -h         Show this help.

EOF

}

# vim: set ts=4 sw=4 et:
