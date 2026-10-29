#!/bin/bash
#
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 SEN Labs e.U.
#
# Does a program or library still find everything it needs in a Haiku?
#
# Akita is built from the sources of Tracker and uses private classes of Haiku (BPrivate::...), which a change of Haiku can make disappear (the nightly hrev60299_3
# changed the constructor of BPrivate::JobQueue: an Akita built before it does not load, and the desktop is without a file manager). This checks, without starting
# anything, that every undefined symbol of the given files is defined by a library of the Haiku that they are meant for:
#
#     ./abi-check.sh bin/Akita bin/lib/libtracker.so                        # against the Haiku that is running (its /boot/system/lib)
#     ./abi-check.sh -l /tmp/nightly/lib -l bin/lib bin/Akita ...           # against the libraries of other folders (a nightly that was unpacked, the libraries of the package)
#
# -l adds a folder with libraries (their *.so*); without -l the folder of the system is used. The files that are checked count as libraries of one another too.
# Exit status 0: nothing is missing; 1: names of symbols are missing (they are printed, demangled); 2: wrong use. Needs nm (binutils or llvm-nm) and c++filt.
#
# With the nightly in a folder it works on any machine: `package extract -C /tmp/nightly haiku-<version>.hpkg lib` unpacks its libraries (see .github/workflows/nightly.yml).

usage() {
	echo "usage: $0 [-l <folder with libraries>]... <file>..." >&2
	exit 2
}

NM=${NM:-nm}
command -v "$NM" >/dev/null 2>&1 || NM=llvm-nm
command -v "$NM" >/dev/null 2>&1 || { echo "abi-check: nm not found" >&2; exit 2; }
DEMANGLE=cat
command -v c++filt >/dev/null 2>&1 && DEMANGLE=c++filt

LIBDIRS=()
while getopts "l:" option; do
	case $option in
		l) LIBDIRS+=("$OPTARG") ;;
		*) usage ;;
	esac
done
shift $((OPTIND - 1))
[ $# -ge 1 ] || usage
[ ${#LIBDIRS[@]} -gt 0 ] || LIBDIRS=(/boot/system/lib)

WORK=$(mktemp -d "${TMPDIR:-/tmp}/abi-check.XXXXXX") || exit 2
trap 'rm -rf "$WORK"' EXIT

# the names (without the version after @) that the libraries define; a symbol that is weak or defined by a program counts too
list_defined() {
	"$NM" -D --defined-only "$1" 2>/dev/null | awk 'NF >= 3 { print $3 }' | sed 's/@.*//'
}

: > "$WORK/defined.raw"
for dir in "${LIBDIRS[@]}"; do
	for lib in "$dir"/*.so*; do
		[ -f "$lib" ] && list_defined "$lib" >> "$WORK/defined.raw"
	done
done
for file in "$@"; do
	[ -f "$file" ] || { echo "abi-check: no such file: $file" >&2; exit 2; }
	list_defined "$file" >> "$WORK/defined.raw"
done
sort -u "$WORK/defined.raw" > "$WORK/defined"
if [ ! -s "$WORK/defined" ]; then
	echo "abi-check: no libraries with symbols found in: ${LIBDIRS[*]}" >&2
	exit 2
fi

status=0
for file in "$@"; do
	# only the undefined ones that must be there (a weak reference, 'w', may stay open)
	"$NM" -D --undefined-only "$file" 2>/dev/null | awk '$1 == "U" { print $2 }' | sed 's/@.*//' | sort -u > "$WORK/needed"
	comm -23 "$WORK/needed" "$WORK/defined" > "$WORK/missing"
	if [ -s "$WORK/missing" ]; then
		status=1
		echo "$file: $(wc -l < "$WORK/missing" | tr -d ' ') symbol(s) not found:"
		$DEMANGLE < "$WORK/missing" | sed 's/^/    /'
	else
		echo "$file: ok ($(wc -l < "$WORK/needed" | tr -d ' ') symbols)"
	fi
done
exit $status
