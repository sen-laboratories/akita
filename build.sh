#!/bin/bash
#
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025-2026 SEN Labs e.U.
#
# Builds Tracker in the tree of senryu (HAIKU_ROOT, default /Develop/SEN/senryu) and copies it to bin/ as Akita (install.sh).
# (The options of jam come before the target: "jam Tracker -j4" takes -j4 for a target and ends with an error.)
HAIKU_ROOT=${HAIKU_ROOT:-/Develop/SEN/senryu}
TRACKER_SRC_DIR=$HAIKU_ROOT/src/kits/tracker

cd "$(dirname "$0")"
AKITA_DIR="$PWD"

printf "Building Tracker from $TRACKER_SRC_DIR...\n"

# The headers of sento (<sen/...>) are installed outside the tree: jam does not see them change. A class that is all in a header (the lists of values, FilterPopUpMenu) must have one layout in
# every object that uses it, or the program crashes when the linker picks the inline code of another object: what includes them is compiled again.
grep -rl '<sen/' "$TRACKER_SRC_DIR" --include='*.cpp' | xargs touch

if (cd "$TRACKER_SRC_DIR" && jam -qj$(nproc) Tracker); then
	printf "\nDONE.\n"
else
	printf "\nERROR, aborting.\n" >&2
	exit 1
fi

printf "copying over as Akita and SEN libs...\n"
HAIKU_ROOT="$HAIKU_ROOT" "$AKITA_DIR/install.sh"
