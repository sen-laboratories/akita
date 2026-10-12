#!/bin/sh
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 SEN Labs e.U.
#
# Run before the package is removed: the block in the UserBootscript goes (it would do nothing without Akita, but it should not stay).
here=$(cd "$(dirname "$0")" && pwd)
"$here/../../bin/akita" disable >/dev/null 2>&1
exit 0
