#!/bin/sh
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 SEN Labs e.U.
#
# Builds the HPKG of Akita from the build in bin/ (bin/Akita and bin/lib/libtracker.so: ./build.sh builds Tracker in the tree of senryu, ./install.sh
# copies the result here). The package is written to the repository root; REVISION overrides the revision (default 1), AKITA_VERSION the version.
#
# The package has the app, its own libtracker.so (the app finds it in its lib folder: it is not the one of the system), the command akita and the file
# for the launch daemon that starts Akita in the place of Tracker at login (data/user_launch/akita), with a script that cleans up after the old versions.
set -e
cd "$(dirname "$0")"

[ -f bin/Akita ] && [ -f bin/lib/libtracker.so ] || { echo "bin/Akita and bin/lib/libtracker.so not found, run build.sh and install.sh first" >&2; exit 1; }

VERSION="${AKITA_VERSION:-1.0.0~${SEN_VERSION_SUFFIX:-dev}}-${REVISION:-1}"
ARCH=$(getarch)
STAGE=package-build
rm -rf $STAGE
mkdir -p $STAGE/apps/Akita/lib $STAGE/bin $STAGE/data/akita $STAGE/data/user_launch $STAGE/data/deskbar/menu/Applications $STAGE/documentation/packages/akita

cp -a bin/Akita $STAGE/apps/Akita/
cp -a bin/lib/libtracker.so $STAGE/apps/Akita/lib/
cp package/akita $STAGE/bin/akita
cp package/post-install.sh $STAGE/data/akita/
cp package/user_launch $STAGE/data/user_launch/akita
chmod 755 $STAGE/bin/akita $STAGE/data/akita/*.sh
ln -s ../../../../apps/Akita/Akita $STAGE/data/deskbar/menu/Applications/Akita
cp README.md LICENSE $STAGE/documentation/packages/akita/

sed -e "s|@VERSION@|$VERSION|g" -e "s|@ARCH@|$ARCH|g" package/PackageInfo.in > $STAGE/.PackageInfo

PACKAGE=akita-$VERSION-$ARCH.hpkg
rm -f akita-*.hpkg
package create -C $STAGE $PACKAGE
rm -rf $STAGE
echo "created $PACKAGE"
