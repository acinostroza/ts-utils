#!/bin/bash

# Quick install of TargetSearch into a directory
#
# Script to quickly install TargetSearch in a directory for fast testing. A
# temporary directory is created to store the tarball. This is cleaned at the
# end. The vignettes are not built.
#
# The destination is optional. If not provided, then the script will try
# to detected it automatically.
#
# Usage: ts-quick-install <repo> [destination]
#
# Args:
#   repo         path to the git repository
#   destination  path to the package destination (created if needed)
#

if (( $# < 1 )) ; then
    echo "Usage: $0 <repo> [destination]"
    exit
fi

path=$(realpath "$1")

if (( $# >= 2 )) ; then
    dest=$(realpath "$2")
else
    dest=$(Rscript -e 'cat(.libPaths()[1])')
fi

if [ ! -f "$path"/DESCRIPTION ] ; then
    echo "Is '$path' a R package?"
    exit 1
else
    version=$(grep "^Version:" "$path"/DESCRIPTION | sed "s/Version: //")
    package=$(grep "^Package:" "$path"/DESCRIPTION | sed "s/Package: //")
fi

if [ ! -d "$dest" ] ; then
    mkdir -p "$dest" || exit 1
elif [ ! -w "$dest" ] ; then
    echo "Cannot write in \`$dest\`"
    exit 1
fi

tmpdir=$(mktemp -d)
trap 'rm -rf $tmpdir' INT TERM EXIT

cd "$tmpdir" || exit 1

R CMD build --no-build-vignettes "$path" && \
    R CMD INSTALL --library="$dest" "${package}_${version}.tar.gz"

# vim: set ts=4 sw=4 et:
