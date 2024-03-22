#!/bin/bash

# Download and compile the latest R stable or developmental version
#
# The script downloads the latest R from CRAN as well the Renviron.bioc file
# from bioconductor that is needed for running R check.
#
# Bioconductor alternates between  development or stable R version, because
# its release cycle is 6 month vs. 1 year for R,
#
# Usage: build-rbioc --stable | --devel
#
# the script uses the environmental variables:
#
#   RDEST       path to where R devel will be installed (def: /tmp/R). The path
#               is created automatically if needed.
#   RVERSION    the R version to compile: def: R-devel for --devel and R-latest
#               for --stable
#   RENVBIOC    the location of the Renviron.bioc file (def: ~/.Renviron.bioc)
#
# Note: Be aware that the script will remove the current R installation
#       in RDEST and build a fresh one.

RDEST="${RDEST:-/tmp/R}"
RENVBIOC="${RENVBIOC:-$HOME/.Renviron.bioc}"
RENVURL="http://bioconductor.org/checkResults/devel/bioc-LATEST/Renviron.bioc"

usage() {
    test -n "$2" && echo "$2"
    echo "Usage: $0 --stable | --devel"
    exit $1
}

if (( $# != 1 )); then
    usage 1 "Missing argument:"
fi

case $1 in
    --stable)
        RVERSION="${RVERSION:-R-latest}"
        CRANURL="https://cran.r-project.org/src/base/${RVERSION}.tar.gz"
        ;;
    --devel)
        RVERSION="${RVERSION:-R-devel}"
        CRANURL="https://cran.r-project.org/src/base-prerelease/${RVERSION}.tar.gz"
        ;;
    --help|-h)
        usage 0
        ;;
    *)
        usage 1 "Unknown argument"
        ;;
esac

# download or update Renvbioc
if [ -f "$RENVBIOC" ] ; then
    curl -L -o "$RENVBIOC" -R -z "$RENVBIOC" "$RENVURL"
else
    curl -L -o "$RENVBIOC" -R "$RENVURL"
fi

mkdir -p "$RDEST" || exit 1
cd "$RDEST" || exit 1

if [ -f "$RVERSION.tar.gz" ]; then
    curl -L -o "$RVERSION.tar.gz" -R -z "$RVERSION.tar.gz" "$CRANURL"
else
    curl -L -o "$RVERSION.tar.gz" -R "$CRANURL"
fi

RDIR=$(tar tf "$RVERSION.tar.gz" | head -1)
test -d "$RDIR" && rm -rf "$RDIR"

tar xf "$RVERSION.tar.gz"
cd "$RDIR" && ./configure && make -j $(nproc)

# install TargetSearch dependencies using BiocManager version 'devel'
bin/R --vanilla <<EOF
   # install BiocManager
   r <- getOption("repos")
   r["CRAN"] <- "http://cloud.r-project.org"
   op <- options(repos=r)
   install.packages('BiocManager')
   options(op)

   # install TargetSearch from bioconductor
   BiocManager::install(version='devel', ask=FALSE)
   BiocManager::install('TargetSearch', ask=FALSE)

   # install suggest packages
   BiocManager::install(c('TargetSearchData', 'BiocStyle', 'knitr', 'tinytest'), ask=FALSE)
EOF

echo "Please add '${RDEST}/${RDIR}bin' to your \$PATH"

# vim: set ts=4 sw=4 et:
