#!/bin/sh
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 SEN Labs e.U.
#
# Run when the package is installed: the block that the old versions put in the UserBootscript goes (the launch daemon starts Akita now).
# Nothing is switched now: "akita start" does it at once, else it happens at the next login.
here=$(cd "$(dirname "$0")" && pwd)
"$here/../../bin/akita" cleanup >/dev/null 2>&1
exit 0
