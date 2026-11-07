#!/bin/sh
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 SEN Labs e.U.
#
# The folders of relations in Akita, with the dynamic spatial relations (worked out by the spatial navigator when they are opened): the folder of one relation lists the places with their
# Kind, RCC-8 code and provenance, the files carry the thumbnail of their target, "all relations" does not ask for a remote relation, and a double click on the file of a relation or a click on
# a place in its menu opens the place in Shoji.
# Needs, in the Haiku VM: Akita (the running Tracker), sen_server, the ontology sen_ontology_spatial, the plugin spatial-navigator, Shoji, and the BFS indices of the volume of TEST_DIR
# (create-sen-indices.sh). No network (the places have no Wikidata link). Run it after the packages are installed: sh relation-folder.sh. Prints `ok` or `FAIL` for each check, and `FAILED` at the end.
HERE=$(cd "$(dirname "$0")" && pwd)
T=${TEST_DIR:-/Develop/test}/_akita-relation-folder
WITHIN=relation/x-vnd.sen-labs.relation.spatial.within
rm -rf "$T"; mkdir -p "$T"; cd "$T" || exit 1
failed=0

check() { # check <description> <command...>
	desc=$1; shift
	if "$@" >/dev/null 2>&1; then echo "ok   $desc"; else echo "FAIL $desc"; failed=1; fi
}
attr() { catattr -d "$1" "$2" 2>/dev/null | tr -d '\n'; }
is() { [ "$1" = "$2" ]; }

# the screen blanker blanks screenshots and a GUI test runs for a while
( while true; do kill -9 $(ps | grep "[s]creen_blanker" | awk '{print $(NF-3)}') 2>/dev/null; sleep 2; done ) &
blank=$!
trap 'kill $blank 2>/dev/null' EXIT

g++ -std=c++20 -Wno-multichar -I/boot/home/config/non-packaged/develop/headers -o openrel "$HERE/openrel.cpp" -lbe 2>&1 | grep error
[ -x ./openrel ] || { echo "FAIL openrel was not built"; exit 1; }

square() { # square <name> <x0> <y0> <x1> <y1>: a place with an outline, as SUESS keeps them
	name=$1; x0=$2; y0=$3; x1=$4; y1=$5
	touch "$name"
	addattr -t mime BEOS:TYPE entity/x-vnd.sen-labs.entity.place "$name"
	addattr -t string dc:title "$name" "$name"
	addattr -t string geo:asWKT "POLYGON(($x0 $y0,$x1 $y0,$x1 $y1,$x0 $y1,$x0 $y0))" "$name"
	addattr -t double SEN:boxSouth -- $y0 "$name"; addattr -t double SEN:boxNorth -- $y1 "$name"
	addattr -t double SEN:boxWest -- $x0 "$name"; addattr -t double SEN:boxEast -- $x1 "$name"
	addattr -t double schema:latitude -- $(echo "($y0+$y1)/2" | bc -l) "$name"
	addattr -t double schema:longitude -- $(echo "($x0+$x1)/2" | bc -l) "$name"
}
square Big 0 0 10 10
square Inner 2 2 4 4			# inside Big, away from its border
# Big has a thumbnail (made newer than the file, as Tracker wants it), which its relation file has to carry
printf 'thumbnail' > thumb.bin
addattr -t raw -f thumb.bin Media:Thumbnail Big
addattr -t time Media:Thumbnail:CreationTime $(( $(date +%s) + 3600 )) Big

newest() { ls -dt /tmp/sen/*/"$1" 2>/dev/null | head -1; }

# ---- the folder of one relation: the places that the place is within, from the answer of the navigator
before=$(newest relation/Within)
./openrel "$T/Inner" $WITHIN
sleep 3
view=$(newest relation/Within)
[ "$view" != "$before" ] || view=
check "the folder of the relation 'within' is made" test -n "$view" -a -d "$view"
check "it has Big" test -f "$view/Big"
check "Kind is the name in words" is "$(attr SEN:REL:Kind "$view/Big")" "non-tangential proper part"
check "the RCC-8 code is NTPP" is "$(attr SEN:REL:Rcc8 "$view/Big")" NTPP
check "the provenance is the navigator" is "$(attr prov:wasAttributedTo "$view/Big")" application/x-vnd.sen-plugin.sen-labs.spatial-navigator
check "the label is the direction" is "$(attr SEN:REL:Label "$view/Big")" within
check "the file knows its target" test -n "$(attr SEN:REL:TRG "$view/Big")"
check "the file of the relation carries the thumbnail of its target" test "$(attr Media:Thumbnail "$view/Big" | wc -c)" -gt 0

# ---- "all relations" does not ask for a remote relation
before=$(newest "all")
./openrel --all "$T/Inner"
sleep 5
all=$(ls -dt /tmp/sen/*/all/* 2>/dev/null | head -1)
check "the folder of all relations is made" test -n "$all" -a -d "$all"
check "it has no folder of the remote relation 'within'" test ! -e "$all/Within" -a ! -e "$all/within"
check "the navigator was not started for it" test "$(ps | grep -c '[S]enSpatialNavigator')" -eq 0

# ---- a double click on the file of a relation opens the place in Shoji
hey Shoji quit >/dev/null 2>&1
sleep 2
open "$view/Big" >/dev/null 2>&1 &
sleep 12
windows=$(hey Shoji COUNT Window 2>/dev/null | sed -n 's/.*: *\([0-9]*\) (0x.*/\1/p' | head -1)
check "Shoji shows the place" test "${windows:-0}" -ge 1
screenshot -s -f png "$T/double-click.png" >/dev/null 2>&1
hey Shoji quit >/dev/null 2>&1

# ---- a click on a place in the menu of the relation hands the place itself to the navigator of the relation type: it opens it in Shoji as well
g++ -std=c++20 -Wno-multichar -o launchrefs "$HERE/launchrefs.cpp" -lbe 2>&1 | grep error
./launchrefs application/x-vnd.sen-plugin.sen-labs.spatial-navigator "$T/Big" >/dev/null 2>&1
sleep 12
windows=$(hey Shoji COUNT Window 2>/dev/null | sed -n 's/.*: *\([0-9]*\) (0x.*/\1/p' | head -1)
check "a place chosen in the menu of the relation opens in Shoji" test "${windows:-0}" -ge 1
hey Shoji quit >/dev/null 2>&1

[ $failed = 0 ] && echo "all ok" || echo FAILED
exit $failed
