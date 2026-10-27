#!/bin/bash
#
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 SEN Labs e.U.
#
# Builds FileTypes in the tree of senryu (HAIKU_ROOT, default /Develop/SEN/senryu) and copies it to ../bin/FileTypes, where package.sh finds it.
# (The options of jam come before the target: "jam FileTypes -j4" takes -j4 for a target and ends with an error.)
HAIKU_ROOT=${HAIKU_ROOT:-/Develop/SEN/senryu}
SRC_DIR=$HAIKU_ROOT/src/preferences/filetypes
RESULT=$HAIKU_ROOT/generated/objects/haiku/x86_64/release/preferences/filetypes/FileTypes

cd "$(dirname "$0")"
FILETYPES_DIR="$PWD"

printf "Building FileTypes from $SRC_DIR...\n"

if (cd "$SRC_DIR" && jam -qj$(nproc) FileTypes); then
	printf "\nDONE.\n"
else
	printf "\nERROR, aborting.\n" >&2
	exit 1
fi

mkdir -p "$FILETYPES_DIR/../bin"
if cp "$RESULT" "$FILETYPES_DIR/../bin/FileTypes"; then
	echo "FileTypes copied to bin/FileTypes."
else
	echo "Error copying FileTypes ($RESULT)." >&2
	exit 1
fi
