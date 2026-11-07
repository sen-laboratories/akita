#!/bin/sh
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 SEN Labs e.U.
#
# Builds and runs the test of the spinner item (spinner.cpp) in the Haiku VM: a menu with "Fetching relations..." and its spinner, three screenshots in /tmp. SRC is the folder of this
# script, TRACKER the folder of the sources of the Tracker (SpinnerMenuItem). Look at the screenshots.
SRC=${SRC:-$(dirname "$0")}
TRACKER=${TRACKER:-/Develop/SEN/senryu/src/kits/tracker}
export LIBRARY_PATH=%A/lib:/boot/home/config/non-packaged/lib:/boot/home/config/lib:/boot/system/non-packaged/lib:/boot/system/lib
( while true; do kill -9 $(ps | grep "[s]creen_blanker" | awk '{print $(NF-3)}') 2>/dev/null; sleep 2; done ) &
blank=$!
g++ -std=c++20 -Wno-multichar -I$TRACKER -o /tmp/spinner-test $SRC/spinner.cpp $TRACKER/SpinnerMenuItem.cpp -lbe 2>&1 | grep -E "error" | head
rm -f /tmp/spinner-?.png
/tmp/spinner-test
kill $blank
ls /tmp/spinner-?.png
