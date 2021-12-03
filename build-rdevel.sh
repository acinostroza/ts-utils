#!/bin/bash

# Download and compile the latest R developmental version
#
# The script downloads the latest R from CRAN as well the Renviron.bioc file
# from bioconductor that is needed for running R check.
#
# Usage: build-rdevel
#
# the script uses the environmental variables:
#
#   RDEST       path to where R devel will be installed (def: /tmp/R). The path
#               is created automatically if needed.
#   RVERSION    the R version to compile (def: R-devel)
#
# Note: Be aware that the script will remove the current R installation
#       in RDEST and build a fresh one.

RDEST="${RDEST:-/tmp/R}"
RVERSION="${RVERSION:-R-devel}"

mkdir -p "$RDEST" || exit 1
cd "$RDEST" || exit 1

test -f Renviron.bioc || wget http://bioconductor.org/checkResults/devel/bioc-LATEST/Renviron.bioc
test -f "$RVERSION.tar.gz" && rm -r "$RVERSION.tar.gz"
test -d "$RVERSION.tar.gz" && rm -rf "$RVERSION"

wget "https://cran.r-project.org/src/base-prerelease/${RVERSION}.tar.gz" || exit 1

tar xf "$RVERSION.tar.gz"
cd "$RVERSION" && ./configure && make -j9

# install TargetSearch dependencies
bin/R --vanilla <<EOF
   r <- getOption("repos")
   r["CRAN"] <- "http://cloud.r-project.org"
   options(repos=r)
   install.packages(c("ncdf4", "tinytest", "assertthat", "knitr", "BiocManager"))
   BiocManager::install(c("BiocStyle", "TargetSearchData"))
EOF
