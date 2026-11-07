#!/bin/sh
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 SEN Labs e.U.
#
# The relation "nearby" through the whole chain, against the public Overpass API (needs the network, the first answer can take half a minute): Akita asks the SEN server for the
# relation at a Location, the server asks the spatial navigator, which asks Overpass and makes a place in the Library for each named thing; the folder of the relation lists them with the
# provenance, and "all relations" has an empty folder for it that is filled when it is entered (it is remote). The places that were made are removed at the end.
# Needs, in the Haiku VM: Akita (the running Tracker), sen_server, sen_ontology_spatial (with nearby), the plugin spatial-navigator, the BFS indices of the volume of TEST_DIR.
HERE=$(cd "$(dirname "$0")" && pwd)
T=${TEST_DIR:-/Develop/test}/_akita-poi-folder
POI=relation/x-vnd.sen-labs.relation.spatial.nearby
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

start=$(date +%s)
./openrel "$T/Here" $POI
took=$(( $(date +%s) - start ))
# (the folder opens at once and is filled when the answer comes: the request is not held up by the navigator)
check "Akita answers at once, not after the navigator (${took} s)" test "$took" -le 8
# (the first answer of Overpass can take half a minute)
view=
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18; do
	sleep 5
	view=$(ls -dt /tmp/sen/*/relation/Nearby* 2>/dev/null | head -1)
	[ -n "$view" ] && [ "$(ls "$view" 2>/dev/null | wc -l)" -ge 10 ] && break
done
check "the folder of the relation is made" test -n "$view" -a -d "$view"
count=$(ls "$view" 2>/dev/null | wc -l | tr -d ' ')
check "it lists things nearby ($count)" test "$count" -ge 10
first=$(ls "$view" | grep -v 'Fetching relations' | head -n1)
check "the placeholder of the fetch is gone" test ! -e "$view/Fetching relations…"
check "the provenance is the Overpass API" is "$(attr prov:wasAttributedTo "$view/$first")" https://wiki.openstreetmap.org/wiki/Overpass_API
# (the label says what it is: the kind of the thing, else its name; the distance is a number in metres)
check "the label says what it is, not the name of the relation" test -n "$(attr SEN:REL:Label "$view/$first")" -a "$(attr SEN:REL:Label "$view/$first")" != nearby
check "the distance is a number of metres" test "$(attr SEN:REL:Distance "$view/$first")" -ge 0
check "the file knows its target" test -n "$(attr SEN:REL:TRG "$view/$first")"

# "all relations": the folder of the remote relation is there, empty, and asks for the relation when it is entered (and not again within the cache time)
g++ -std=c++20 -Wno-multichar -I/boot/home/config/non-packaged/develop/headers -o launchrefs "$HERE/launchrefs.cpp" -lbe 2>&1 | grep error
rm -rf /tmp/sen/*/all
./openrel --all "$T/Here"
for i in 1 2 3 4 5 6 7 8 9 10; do
	sleep 2
	all=$(ls -dt /tmp/sen/*/all/* 2>/dev/null | head -1)
	[ -n "$all" ] && ls -d "$all"/*earby* >/dev/null 2>&1 && break
done
nearby=$(ls -d "$all"/*earby* 2>/dev/null | head -n1)
check "the folder of all relations has a folder for nearby" test -n "$nearby" -a -d "$nearby"
check "the folder is of the type of the relation" is "$(attr BEOS:TYPE "$nearby")" $POI
check "it is empty until it is entered" test "$(ls "$nearby" | wc -l | tr -d ' ')" -eq 0
./launchrefs application/x-vnd.Be-TRAK "$nearby" >/dev/null
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18; do
	sleep 5
	[ "$(ls "$nearby" 2>/dev/null | grep -vc 'Fetching relations')" -ge 10 ] && break
done
count=$(ls "$nearby" 2>/dev/null | grep -vc 'Fetching relations')
check "entering the folder fetches the relations ($count)" test "$count" -ge 10
# (entered again within the cache time: not fetched again - what was taken away stays away)
gone=$(ls "$nearby" | head -n1); rm -f "$nearby/$gone"
./launchrefs application/x-vnd.Be-TRAK "$nearby" >/dev/null; sleep 8
check "within the cache time it is not fetched again" test ! -e "$nearby/$gone" -a ! -e "$nearby/Fetching relations…"

# the folder of a group ("Open related..." > Spatial): the relations of the group as empty folders
rm -rf /tmp/sen/*/all
./openrel --group Spatial "$T/Here"
for i in 1 2 3 4 5 6 7 8 9 10; do
	sleep 2
	grp=$(ls -dt /tmp/sen/*/all/Spatial* 2>/dev/null | head -1)
	[ -n "$grp" ] && ls -d "$grp"/*earby* >/dev/null 2>&1 && break
done
check "the folder of the group is made" test -n "$grp" -a -d "$grp"
gnearby=$(ls -d "$grp"/*earby* 2>/dev/null | head -n1)
check "it has a folder for nearby, empty" test -n "$gnearby" -a "$(ls "$gnearby" | wc -l | tr -d ' ')" -eq 0
check "it has no relation of another group" test "$(ls "$grp" | wc -l | tr -d ' ')" -ge 1

# a kept folder: copied (with its attributes) to a place that stays, it is not registered, and it fetches from its attributes when it is opened
check "the folder knows where its relations come from" test -n "$(attr SEN:REL:SRC "$gnearby")"
rm -rf "$T/kept"; mkdir "$T/kept"
cp -a "$gnearby" "$T/kept/"
kept="$T/kept/$(basename "$gnearby")"
rm -f "$kept"/*
check "the copy is empty" test "$(ls "$kept" | wc -l | tr -d ' ')" -eq 0
./launchrefs application/x-vnd.Be-TRAK "$kept" >/dev/null
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18; do
	sleep 5
	[ "$(ls "$kept" 2>/dev/null | grep -vc 'Fetching relations')" -ge 10 ] && break
done
check "the copy fetches the relations when it is opened ($(ls "$kept" | wc -l | tr -d ' '))" test "$(ls "$kept" 2>/dev/null | grep -vc 'Fetching relations')" -ge 10

# clean up: the places that were made (a link to OpenStreetMap, made since the start)
IFS='
'
for f in $(find "$HOME/Library" -type f -newer "$T/stamp" 2>/dev/null); do
	catattr -d schema:sameAs "$f" 2>/dev/null | grep -q 'openstreetmap.org/\(node\|way\|relation\)/[0-9]' && rm -f "$f"
done
rm -rf "$T"
[ $failed = 0 ] && echo "all ok" || echo FAILED
exit $failed
