#!/bin/bash

# quick test using tinytest R package
#
# Script to quickly test a package that has enabled 'tinytest' test framework.
# No other framework are supported (e.g. testthat) as it is intended for TargetSearch.
#
# Usage: ts-quick-test <repo>
#
# Args:
#   repo         path to the git repository
#
# the script uses the environmental variable:
#
#   RENVBIOC    the location of the Renviron.bioc file (def: ~/.Renviron.bioc)
#               if the file does not exist, then it will attempt to download it

if (( $# == 0 )) ; then
    echo "Usage: $0 <repo>"
    exit
fi

RENVBIOC="${RENVBIOC:-$HOME/.Renviron.bioc}"
RENVURL="http://bioconductor.org/checkResults/devel/bioc-LATEST/Renviron.bioc"

path=$(realpath "$1")

if [ ! -f "$path"/DESCRIPTION ] ; then
    echo "Is '$path' a R package?"
    exit 1
fi

if [ ! -f "$RENVBIOC" ] ; then
    curl -L -o "$RENVBIOC" -R -z "$RENVBIOC" "$RENVURL"
fi

export R_ENVIRON_USER="$RENVBIOC"
echo 'tinytest::build_install_test("'$path'")' | R --no-save

# vim: set ts=4 sw=4 et:
