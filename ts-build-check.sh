#!/bin/bash

# Build and run R check
#
# script to build a R package and to run R CMD check on it. The check and build takes place in
# a temporary directory that's removed automatically afterwards, or in a given path which will
# not be cleaned.
#
# Usage: ts-build-check <repo> [ destination ]
#
# Args:
#   repo         path to the git repository
#   destination  path to the package destination (created if needed). If not given, a temp dir
#                is used instead (and automatically removed)
#
# the script uses the environmental variable:
#   RENVBIOC    the location of the Renviron.bioc file (def: ~/.Renviron.bioc)

if (( $# == 0 )) ; then
    echo "Usage: $0 <repo> [ destination ]"
    exit
fi

RENVBIOC="${RENVBIOC:-$HOME/.Renviron.bioc}"
RENVURL="http://bioconductor.org/checkResults/devel/bioc-LATEST/Renviron.bioc"

path=$(realpath "$1")

if [ ! -f "$path"/DESCRIPTION ] ; then
    echo "Is '$path' a R package?"
    exit 1
else
    version=$(grep "^Version:" "$path"/DESCRIPTION | sed "s/Version: //")
    package=$(grep "^Package:" "$path"/DESCRIPTION | sed "s/Package: //")
fi

if [ -f "$RENVBIOC" ] ; then
    curl -L -o "$RENVBIOC" -R -z "$RENVBIOC" "$RENVURL"
else
    curl -L -o "$RENVBIOC" -R "$RENVURL"
fi

if (( $# == 2 )) ; then
    tmpdir=$(realpath "$2")
    if [ ! -d "$tmpdir" ] ; then
        mkdir -p "$tmpdir" || exit 1
    fi
else
    tmpdir=$(mktemp -d)
    trap 'rm -rf $tmpdir' INT TERM EXIT
fi

cd "$tmpdir" || exit 1

export R_ENVIRON_USER="$RENVBIOC"
R CMD build "$path" && R CMD check --no-vignettes "${package}_${version}.tar.gz"

# vim: set ts=4 sw=4 et:
