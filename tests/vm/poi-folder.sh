#!/bin/sh
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 SEN Labs e.U.
#
# The relation "point of interest" through the whole chain, against the public Overpass API (needs the network, the first answer can take half a minute): Akita asks the SEN server for the
# relation at a Location, the server asks the spatial navigator, which asks Overpass and makes a place in the Library for each named thing; the folder of the relation lists them with the
# provenance, and "all relations" does not ask for it (it is remote). The places that were made are removed at the end.
# Needs, in the Haiku VM: Akita (the running Tracker), sen_server, sen_ontology_spatial (with point-of-interest), the plugin spatial-navigator, the BFS indices of the volume of TEST_DIR.
HERE=$(cd "$(dirname "$0")" && pwd)
T=${TEST_DIR:-/Develop/test}/_akita-poi-folder
POI=relation/x-vnd.sen-labs.relation.spatial.point-of-interest
rm -rf "$T"; mkdir -p "$T"; cd "$T" || exit 1
failed=0
check() { desc=$1; shift; if "$@" >/dev/null 2>&1; then echo "ok   $desc"; else echo "FAIL $desc"; failed=1; fi; }
attr() { catattr -d "$1" "$2" 2>/dev/null | tr -d '\n'; }
is() { [ "$1" = "$2" ]; }

g++ -std=c++20 -Wno-multichar -I/boot/home/config/non-packaged/develop/headers -o openrel "$HERE/openrel.cpp" -lbe 2>&1 | grep error
[ -x ./openrel ] || { echo "FAIL openrel was not built"; exit 1; }

touch stamp; sleep 2
touch Here
addattr -t mime BEOS:TYPE entity/x-vnd.sen-labs.entity.location Here
addattr -t string dc:title Here Here
addattr -t double schema:latitude -- 48.1985 Here; addattr -t double schema:longitude -- 16.3010 Here

./openrel "$T/Here" $POI
# (the first answer of Overpass can take half a minute)
view=
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18; do
	sleep 5
	view=$(ls -dt /tmp/sen/*/relation/Point* 2>/dev/null | head -1)
	[ -n "$view" ] && [ "$(ls "$view" 2>/dev/null | wc -l)" -ge 10 ] && break
done
check "the folder of the relation is made" test -n "$view" -a -d "$view"
count=$(ls "$view" 2>/dev/null | wc -l | tr -d ' ')
check "it lists points of interest ($count)" test "$count" -ge 10
first=$(ls "$view" | head -n1)
check "the provenance is the Overpass API" is "$(attr prov:wasAttributedTo "$view/$first")" https://wiki.openstreetmap.org/wiki/Overpass_API
check "the label is point of interest" is "$(attr SEN:REL:Label "$view/$first")" "point of interest"
check "the file knows its target" test -n "$(attr SEN:REL:TRG "$view/$first")"

# "all relations" does not ask for a remote relation
./openrel --all "$T/Here"
sleep 6
all=$(ls -dt /tmp/sen/*/all/* 2>/dev/null | head -1)
check "the folder of all relations has no point of interest" test -n "$all" -a ! -e "$all/PointOfInterest" -a ! -e "$all/Point of Interest"

# clean up: the places that were made (a link to OpenStreetMap, made since the start)
IFS='
'
for f in $(find "$HOME/Library" -type f -newer "$T/stamp" 2>/dev/null); do
	catattr -d schema:sameAs "$f" 2>/dev/null | grep -q 'openstreetmap.org/\(node\|way\|relation\)/[0-9]' && rm -f "$f"
done
rm -rf "$T"
[ $failed = 0 ] && echo "all ok" || echo FAILED
exit $failed
