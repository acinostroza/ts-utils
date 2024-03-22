#!/bin/bash

# Recursively download raw compilation results from Bioconductor
# Set the env variables BIOC (Bioc release) and PACKAGE (Bioc package)
# to change the results page
#
# Requires: wget

biocver=${BIOC:-3.19}
package=${PACKAGE:-TargetSearch}

url="https://bioconductor.org/checkResults/$biocver/bioc-LATEST/$package/raw-results"

wget -O raw.index "$url/" || exit 1
machines=$( grep -F '[DIR]' raw.index | sed -r 's|<[^<>]+>||g;s|/.*$||' )

for mach in $machines ; do
    echo "Downloading folder: $mach"
    wget "$url/$mach" || exit 1
    files=$( grep -F '[TXT]' "$mach" | sed -r 's/^.*href="([^"]+)".*$/\1/' )
    for file in $files ; do
        wget -O "$mach-$file" "$url/$mach/$file" || exit 1
    done
    rm -f "$mach"
done

rm -f raw.index
