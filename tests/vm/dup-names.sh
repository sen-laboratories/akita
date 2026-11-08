#!/bin/sh
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 SEN Labs e.U.
#
# Two targets of a relation with the same name (two schools called alike) are told apart in the folder of the relation by the name of their files, not by a number of their place in the
# list: "Twin Place" and "Twin Place (Elsewhere)", not "Twin Place #2". Uses the relation "within" of the spatial navigator (no network).
# Needs, in the Haiku VM: Akita (the running Tracker), sen_server, sen_ontology_spatial, the plugin spatial-navigator, the BFS indices of the volume of TEST_DIR.
HERE=$(cd "$(dirname "$0")" && pwd)
T=${TEST_DIR:-/Develop/test}/_akita-dup-names
WITHIN=relation/x-vnd.sen-labs.relation.spatial.within
rm -rf "$T"; mkdir -p "$T"; cd "$T" || exit 1
failed=0
check() { desc=$1; shift; if "$@" >/dev/null 2>&1; then echo "ok   $desc"; else echo "FAIL $desc"; failed=1; fi; }

g++ -std=c++20 -Wno-multichar -I/boot/home/config/non-packaged/develop/headers -o openrel "$HERE/openrel.cpp" -lbe 2>&1 | grep error
[ -x ./openrel ] || { echo "FAIL openrel was not built"; exit 1; }

square() { # square <file> <title> <x0> <y0> <x1> <y1>
	file=$1; title=$2; x0=$3; y0=$4; x1=$5; y1=$6
	touch "$file"
	addattr -t mime BEOS:TYPE entity/x-vnd.sen-labs.entity.place "$file"
	addattr -t string dc:title "$title" "$file"
	addattr -t string geo:asWKT "POLYGON(($x0 $y0,$x1 $y0,$x1 $y1,$x0 $y1,$x0 $y0))" "$file"
	addattr -t double SEN:boxSouth -- $y0 "$file"; addattr -t double SEN:boxNorth -- $y1 "$file"
	addattr -t double SEN:boxWest -- $x0 "$file"; addattr -t double SEN:boxEast -- $x1 "$file"
	addattr -t double schema:latitude -- $(echo "($y0+$y1)/2" | bc -l) "$file"
	addattr -t double schema:longitude -- $(echo "($x0+$x1)/2" | bc -l) "$file"
}
square "Twin Place" "Twin Place" 0 0 10 10
square "Twin Place (Elsewhere)" "Twin Place" 0 0 12 12
square Core "Core" 2 2 4 4

before=$(ls -dt /tmp/sen/*/relation/Within 2>/dev/null | head -1)
./openrel "$T/Core" $WITHIN
sleep 4
view=$(ls -dt /tmp/sen/*/relation/Within 2>/dev/null | head -1)
[ "$view" != "$before" ] || view=
check "the folder of the relation is made" test -n "$view" -a -d "$view"
check "the first place has its name" test -e "$view/Twin Place"
check "the second is named like its file" test -e "$view/Twin Place (Elsewhere)"
check "no number of the list is added" test -z "$(ls "$view" | grep ' #[0-9]')"
rm -rf "$T"
[ $failed = 0 ] && echo "all ok" || echo FAILED
exit $failed
