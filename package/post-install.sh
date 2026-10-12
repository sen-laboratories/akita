#!/bin/sh
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 SEN Labs e.U.
#
# Run when the package is installed: Akita replaces Tracker at the next login (a block in the UserBootscript). Tracker is not touched now: "akita start"
# switches at once. If the script cannot do it (the package is installed for somebody else), "akita enable" does it later.
here=$(cd "$(dirname "$0")" && pwd)
"$here/../../bin/akita" enable >/dev/null 2>&1
exit 0
