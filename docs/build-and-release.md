<!--
SPDX-License-Identifier: MIT
SPDX-FileCopyrightText: 2026 SEN Labs e.U.
-->

# Building and releasing Akita

Akita is Tracker built from the tree of **senryu** (our fork of Haiku) and packaged as an application of its own (`akita`, with its own `libtracker.so`, beside the stock Tracker): the `akita` repository is the separate project that does this, it holds no Tracker sources itself. The sources of Tracker and the SEN code in it are in `senryu/src/kits/tracker` (the application `src/apps/tracker`, the
private headers `headers/private/tracker`); this repository has the scripts, the package and the icon. Everything that needs Haiku is built in the Haiku VM; the editing is done on the Mac.

## Where things are

| | Mac | VM |
|---|---|---|
| Akita (scripts, package) | `~/Develop/SEN/akita` | `/Develop/SEN/akita` |
| senryu (Tracker sources, `jam` tree) | `~/Develop/SEN/senryu` (sparse clone) | `/Develop/SEN/senryu` (`HAIKU_ROOT` of `build.sh`) |
| SEN FileTypes (preference, in senryu: `src/preferences/filetypes`) | same tree | built by `akita/filetypes/build.sh` |

`akita/tracker-app` and `akita/tracker-lib` are symlinks to `/boot/home/Develop/senryu/...`: they exist only where such a path does. On the Mac the files to edit are the ones in `senryu`.
The tree of the VM is checked out already and has no changes of its own: its files are those of the Mac, copied over (its git `HEAD` is older than the files, so `git status` there lists files as modified that are only newer commits of the Mac). **Compare it with the Mac before building** and copy only the files that differ (after a change on the Mac that is only the file that was edited):

```sh
# Mac: md5 of the sources, VM: the same; the difference is what has to be copied
cd ~/Develop/SEN/senryu && for d in src/kits/tracker src/apps/tracker headers/private/tracker; do find $d -type f ! -name '.DS_Store' ! -name '._*' -print0 | xargs -0 md5 -r; done | sort -k2 > /tmp/mac.md5
ssh -p 2222 user@localhost 'cd /Develop/SEN/senryu; for d in src/kits/tracker src/apps/tracker headers/private/tracker; do find $d -type f -print0 | xargs -0 md5sum; done | sort -k2' </dev/null > /tmp/vm.md5
diff /tmp/mac.md5 /tmp/vm.md5          # (md5 -r prints "hash  path" with one blank after the hash; fix it with sed if the columns differ)
scp -P 2222 <file> user@localhost:/Develop/SEN/senryu/<file>        # copy what differs; touch it in the VM so that jam rebuilds it
```

## Build

`./build.sh` in the VM runs `jam -qj$(nproc) Tracker` in `senryu/src/kits/tracker` (the options of jam come before the target: `jam Tracker -j4` takes `-j4` for a target) and then `./install.sh`, which copies
the result to `bin/Akita` and `bin/lib/libtracker.so`. The first build takes about half an hour; the next ones only what changed.

Run it detached, with a log and a `done` file (an ssh session that runs for half an hour gets lost), and with this environment (**not** the profile of the VM: its `CC="ccache gcc"` breaks jam):

```sh
export LIBRARY_PATH=%A/lib:/boot/home/config/non-packaged/lib:/boot/home/config/lib:/boot/system/non-packaged/lib:/boot/system/lib   # jam adds to it: in a non-interactive ssh it is empty and replaces the defaults of the loader
export HAIKU_REVISION=$(uname -v | sed 's/.*hrev\([0-9]*\).*/hrev\1/')                                                              # the tree has no .git that tells the revision
cd /Develop/SEN/akita && ./build.sh > /tmp/akbuild.log 2>&1; echo "exit $?" >> /tmp/akbuild.log
```

## Package

```sh
cd /Develop/SEN/akita && SEN_VERSION_SUFFIX=beta8 REVISION=6 ./package.sh        # akita-1.0.0~beta8-6-x86_64.hpkg
./abi-check.sh bin/Akita bin/lib/libtracker.so                                   # the symbols that the Haiku that runs does not have: say so before anybody installs it
```

- The version is `1.0.0~<SEN_VERSION_SUFFIX>-<REVISION>` (`AKITA_VERSION` replaces the first part). The revision has to be higher than the one on Kiri (`ls kiri/x86_64/packages | grep akita`): a package that is not higher is never offered by `pkgman`.
- The package has `apps/Akita/Akita`, its own `lib/libtracker.so`, the command `akita` and the launch file that starts Akita in the place of Tracker at login (`data/user_launch/akita`, undone by *Use Akita instead of Tracker* in the settings of SEN or `akita disable`).
- It **requires `haiku >= r1~beta6_hrev60299_1`, with no upper bound** (it uses private classes of Haiku: see the README, *Haiku version*). Build on a nightly that is at least as new as the one that the users have.
- `sen_filetypes` (the FileTypes of SEN, signature `application/x-vnd.sen-labs.FileTypes`): `filetypes/package.sh` the same way.

## Publish

Like every package of SEN (Kiri, `x86_64/packages`, one version per package): check that the file is intact (`package list`) and that its checksum is the same in the VM and on the Mac, `git rm` the old
version, copy the new one, commit, push, wait until `repo.sha256` of the served repository changes and matches the repository file, then `pkgman refresh && pkgman search -D akita` in the VM. Details: the skill *haiku-packaging-release*.
