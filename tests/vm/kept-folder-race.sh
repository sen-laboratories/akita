#!/bin/sh
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 SEN Labs e.U.
#
# A kept folder of a relation (copied to a place that stays) that is opened again and again while the answer of the navigator is kept: the fetch is done at once and replaces the files
# (the placeholder "Fetching relations...", what an earlier fetch left) while the window reads the folder. A file that went between the listing of the folder and the opening of its node
# used to stop Akita (ASSERT(model->IsNodeOpen()) in BPoseView::CreatePoses). Akita must stay the same program and no crash report (*.report) must appear on the Desktop.
# Needs, in the Haiku VM: Akita (the running Tracker), sen_server, sen_ontology_spatial, the plugin spatial-navigator, a network connection for the first answer (kept for a day after).
HERE=$(cd "$(dirname "$0")" && pwd)
T=${TEST_DIR:-/Develop/test}/_akita-kept-race
rm -rf "$T"; mkdir -p "$T"; cd "$T" || exit 1
failed=0
check() { desc=$1; shift; if "$@" >/dev/null 2>&1; then echo "ok   $desc"; else echo "FAIL $desc"; failed=1; fi; }
akita_team() { ps | grep "[A]kita/Akita" | awk '{print $(NF-3)}' | head -1; }

g++ -std=c++20 -Wno-multichar -I/boot/home/config/non-packaged/develop/headers -o openrel "$HERE/openrel.cpp" -lbe 2>&1 | grep error
g++ -std=c++20 -Wno-multichar -I/boot/home/config/non-packaged/develop/headers -o launchrefs "$HERE/launchrefs.cpp" -lbe 2>&1 | grep error
[ -x ./openrel -a -x ./launchrefs ] || { echo "FAIL the helpers were not built"; exit 1; }

touch Here
addattr -t mime BEOS:TYPE entity/x-vnd.sen-labs.entity.location Here
addattr -t string dc:title Here Here
addattr -t double schema:latitude -- 48.1985 Here; addattr -t double schema:longitude -- 16.3010 Here
touch stamp

# the first answer (from the network), kept for the next ones
./openrel Here relation/x-vnd.sen-labs.relation.spatial.nearby >/dev/null
view=
for i in $(seq 1 24); do
	sleep 5
	view=$(ls -dt /tmp/sen/*/relation/Nearby* 2>/dev/null | head -1)
	[ -n "$view" ] && [ "$(ls "$view" 2>/dev/null | grep -vc 'Fetching relations')" -ge 10 ] && break
done
check "the first answer is there" test "$(ls "$view" 2>/dev/null | grep -vc 'Fetching relations')" -ge 10

# a copy that holds the placeholder and a few old files, as one made while a fetch was going on
mkdir kept
cp -a "$view" kept/Nearby
touch "kept/Nearby/Fetching relations…"
before=$(ls "$HOME/Desktop" | grep -c '\.report$')
team=$(akita_team)
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
	./launchrefs application/x-vnd.Be-TRAK "$T/kept/Nearby" >/dev/null
	sleep 1
done
sleep 10
check "Akita is the same program" test "$(akita_team)" = "$team"
check "no crash report was made" test "$(ls "$HOME/Desktop" | grep -c '\.report$')" -eq "$before"
check "the copy has its relations" test "$(ls kept/Nearby | grep -vc 'Fetching relations')" -ge 10

# the same race without a plugin: files that are made and removed at once in a folder that windows are opened on (the file that is listed is gone when its node is opened)
mkdir churn
for i in $(seq 1 60); do touch churn/stay$i; done
before=$(ls "$HOME/Desktop" | grep -c '\.report$')
team=$(akita_team)
( n=0; while [ $n -lt 400 ]; do n=$((n + 1)); touch churn/gone$n; rm -f churn/gone$n; done; echo done > churn.done ) &
for i in 1 2 3 4 5 6 7 8; do
	./launchrefs application/x-vnd.Be-TRAK "$T/churn" >/dev/null
	sleep 1
done
while [ ! -e churn.done ]; do sleep 1; done
sleep 5
check "Akita is the same program after the churn" test "$(akita_team)" = "$team"
check "no crash report was made by the churn" test "$(ls "$HOME/Desktop" | grep -c '\.report$')" -eq "$before"

# clean up: the places that were made (a link to OpenStreetMap, made since the start)
IFS='
'
for f in $(find "$HOME/Library" -type f -newer "$T/stamp" 2>/dev/null); do
	catattr -d schema:sameAs "$f" 2>/dev/null | grep -q 'openstreetmap.org/\(node\|way\|relation\)/[0-9]' && rm -f "$f"
done
[ $failed = 0 ] && echo "all ok" || echo FAILED
exit $failed
