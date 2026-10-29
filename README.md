<p align="center">
  <img src="images/akita-logo.jpg" width=320 />
</p>

<h1 align="center">Akita</h1>
<h2 align="center">
  <strong>A</strong>ugmented 
  <strong>K</strong>nowledge
  <strong>I</strong>nterface for
  <strong>T</strong>racker
  <strong>A</strong>ssociations
</h2>

<p align="center">
  A semantic take on Tracker, the Haiku file manager. Keeps changes to a sane level and tries to "just" blend in but offer some semantic sprinkle dust.
</p>

# About

This repository contains the changes to Haiku Tracker for integrating with SEN and providing support for linked semantic navigation and file manipulation.

# Install

Akita is a package in the SEN Labs repository, [Kiri](https://kiri.sen-labs.org):

```sh
pkgman add-repo https://kiri.sen-labs.org/x86_64      # once
pkgman install akita
```

The package puts Akita in `apps/Akita` (with its own `libtracker.so`, which the app finds in its `lib` folder) and a file for the launch daemon
(`data/user_launch/akita`) that disables the service of the stock Tracker and starts Akita in its place at the next login. (A file that only changes the
`launch` line of the Tracker service does not work, the one of the system wins: so Tracker is disabled and Akita is a service of its own.) The command `akita`
switches at once and undoes it:

```sh
akita start        # switch now: stops the stock Tracker (a service of the launch daemon) and starts Akita
akita stop         # back to the stock Tracker now
akita restart      # quits the Tracker that runs and starts it again
akita enable       # Akita instead of Tracker at every login (the default of the package)
akita disable      # the stock Tracker at every login: a file ~/config/settings/launch/akita (read after the files of packages), "akita enable" removes it
akita status
```

The same switch is the setting *Use Akita instead of Tracker* in the Settings of the SEN item in the Deskbar. The old versions of the package started Akita from
a block in the UserBootscript: installing this one removes that block.

Akita has the signature of Tracker, so only one of them runs at a time.

# Package

`./package.sh` makes the package from `bin/Akita` and `bin/lib/libtracker.so` (`./build.sh` builds Tracker in the tree of senryu, `./install.sh` copies the result to `bin/`);
`REVISION=2 ./package.sh` for a new revision. The file for the launch daemon and the scripts that the package installs are in `package/`. `./build.sh` stops with an error when the build fails (a command of jam is
`jam -qj4 Tracker`: the options come before the target).

**Haiku version.** Akita links against private classes of Haiku (`libbe`), so a package works with the Haiku that it was built with. SEN follows the nightlies: the packages are built on a recent nightly and require `haiku >= r1~beta6_hrev60299_1` (the nightly hrev60299_3 gave `BPrivate::JobQueue` a constructor with a parameter, and a `libtracker.so` built before it does not load); there is no upper limit, so `pkgman` does not hold your Haiku back. Haiku compares the pre-release part of a version as text (`_11` is *less* than `_3`), which is why the bound is the `_1`. When a nightly breaks Akita, `abi-check.sh` says so before anybody installs it (see below), and a new build follows.

**ABI check.** `./abi-check.sh [-l <folder with libraries>]... <file>...` lists the symbols that a program or library needs and the libraries of a Haiku do not have, without starting anything (`bin/Akita`, `bin/lib/libtracker.so` against the Haiku that runs, or against the libraries of a nightly that was unpacked with `package extract`). `.github/workflows/nightly.yml` runs it every day against the newest nightly and the packages of Kiri.

# What SEN adds

- *Open related...* and the relation windows (see the [user guide](https://github.com/sen-laboratories/sento/blob/main/docs/user-guide.md)), Command+drag to relate files.
- An **ontology** (in `~/config/settings/sen/ontologies`) opens as the folder of its Dependency relations.
- Command+double click on a file opens the [graph](https://github.com/sen-laboratories/sento/blob/main/docs/user-guide.md#the-graph) of the objects and relations, centred on the file; the server asks Akita for the
  selected file of its active window (`kGetSelection`) when the graph is opened from the Deskbar.

# SEN FileTypes

`filetypes/` has the package `sen_filetypes`: the FileTypes preference of senryu (searchable attributes, opens a type or attribute when SEN asks) as *SEN FileTypes* beside the one of Haiku. See `filetypes/README.md`.

# Build

Tracker is part of Haiku, so as to not complicate things, SEN specific adaptations are currently kept within a fork of the Haiku source.
For building, you need to check out (for trying out) or fork (for development) haiku first.
It is packaged as a Haiku package (HPKG), see below, and is to be included out of the box in the
[SENryu distro](https://codeberg.org/senlabs/senryu).

Adapt the variable(s) at the start of the scripts according to your setup.
Then run:
* `./build.sh` -- builds Tracker in the tree of senryu (`HAIKU_ROOT`, default `/Develop/SEN/senryu`) and copies the result to `bin/` (`bin/Akita`, `bin/lib/libtracker.so`) with `./install.sh`
* `./start.sh` -- stops system Tracker and launches the custom Akita fork in all its semantic glory!

The `build` script uses `jam`'s `-j` option to build with all available cores by default, feel free to adapt to your needs.

The `start` script takes care of really quitting Tracker for good, as it is set on auto-restart, since it's an important system application.
This restart-logic can be circumvented via the command in the script:
``` 
launch_roster stop x-vnd.be-trak
``` 

# Details

If something goes wrong, it often helps to have some understanding of what is going on behind the scenes:

Tracker src in haiku is located at
```
haiku/src/kits/tracker
```

after build, generated `libtracker.so` can be found in
```
haiku/generated/objects/haiku/x86_64/release/apps/tracker/Tracker
```

Tracker itself is just a shell application using libtracker and located in
```
haiku/src/apps/tracker/
```
needs also to be rebuilt.
