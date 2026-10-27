#!/bin/sh
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 SEN Labs e.U.
#
# Builds the HPKG of the FileTypes of SEN from the build of senryu (FILETYPES, default ../bin/FileTypes: build it with
# sento/tools/tracker-vm-build.sh and BUILD_DIR=src/preferences/filetypes BUILD_TARGET=FileTypes). The package is written to the repository root;
# REVISION overrides the revision (default 1), FILETYPES_VERSION the version.
#
# It is a preference of its own, "SEN FileTypes", next to the FileTypes of Haiku (it has another signature, so both can run).
set -e
cd "$(dirname "$0")"

BINARY=${FILETYPES:-../bin/FileTypes}
[ -f "$BINARY" ] || { echo "$BINARY not found, build FileTypes in the tree of senryu first" >&2; exit 1; }

VERSION="${FILETYPES_VERSION:-1.0.0~${SEN_VERSION_SUFFIX:-dev}}-${REVISION:-1}"
ARCH=$(getarch)
STAGE=package-build
rm -rf $STAGE
mkdir -p $STAGE/preferences $STAGE/documentation/packages/sen_filetypes

cp -a "$BINARY" "$STAGE/preferences/SEN FileTypes"
cp ../LICENSE $STAGE/documentation/packages/sen_filetypes/
cp README.md $STAGE/documentation/packages/sen_filetypes/

# Akita links against private classes of Haiku (libbe) and is built from the tree of senryu (a base before hrev60299, see 2.0.0 for the nightlies): the
# package requires the Haiku revisions it was built for (see the requires in filetypes/PackageInfo.in), otherwise it fails to load.
sed -e "s|@VERSION@|$VERSION|g" -e "s|@ARCH@|$ARCH|g" PackageInfo.in > $STAGE/.PackageInfo

PACKAGE=../sen_filetypes-$VERSION-$ARCH.hpkg
rm -f ../sen_filetypes-*.hpkg
package create -C $STAGE $PACKAGE
rm -rf $STAGE
echo "created $PACKAGE"
