#!/bin/bash

set -ex
FILE=$1

echo updating "$FILE"
VERSION=`cat "$FILE" | sed -nE 's/ *version = "(.*)"/\1/p' | head -n 1`
NEXT_VERSION=`echo "$VERSION" | awk -F. -v OFS=. '{$NF += 1 ; print}'`
echo updating from "$VERSION" to "$NEXT_VERSION"
# NOTE: this only works with GNU sed, macOS sed needs: sed -i '' 's/version ....
sed -i 's/version = "'$VERSION'"/version = "'$NEXT_VERSION'"/' "$FILE"
echo DONE
