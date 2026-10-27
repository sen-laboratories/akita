#!/bin/bash
#
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025-2026 SEN Labs e.U.
#
# Copies the Tracker that was built in the tree of senryu to bin/ (bin/Akita and bin/lib/libtracker.so, what run.sh and package.sh use).
# build.sh does that after the build. HAIKU_ROOT is the tree of senryu (default /Develop/SEN/senryu).
HAIKU_ROOT=${HAIKU_ROOT:-/Develop/SEN/senryu}
HAIKU_OUT_DIR=$HAIKU_ROOT/generated/objects/haiku/x86_64/release

cd "$(dirname "$0")"
mkdir -p bin/lib

if cp "$HAIKU_OUT_DIR/kits/tracker/libtracker.so" bin/lib/ && cp "$HAIKU_OUT_DIR/apps/tracker/Tracker" bin/Akita; then
	echo "Akita updated and ready to roll."
else
	echo "Error updating Akita (is Tracker built in $HAIKU_ROOT?)." >&2
	exit 1
fi
