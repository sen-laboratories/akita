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

The package puts Akita in `apps/Akita` (with its own `libtracker.so`, which the app finds in its `lib` folder) and adds a block to your `UserBootscript` that starts Akita
instead of the stock Tracker at the next login (it does nothing if Akita is not installed). The command `akita` does this and more:

```sh
akita start        # switch now: stops the stock Tracker (a service of the launch daemon) and starts Akita
akita stop         # back to the stock Tracker now
akita enable       # Akita instead of Tracker at every login (what the package does when it is installed)
akita disable      # the stock Tracker at the next login (what the package does when it is removed)
akita status
```

Akita has the signature of Tracker, so only one of them runs at a time.

# Package

`./package.sh` makes the package from `bin/Akita` and `bin/lib/libtracker.so` (`./build.sh` builds Tracker in the tree of senryu, `./install.sh` copies the result to `bin/`);
`REVISION=2 ./package.sh` for a new revision. The scripts that the package installs are in `package/`.

# Build

Tracker is part of Haiku, so as to not complicate things, SEN specific adaptations are currently kept within a fork of the Haiku source.
For building, you need to check out (for trying out) or fork (for development) haiku first.
It is packaged as a Haiku package (HPKG), see below, and is to be included out of the box in the
[SENryu distro](https://codeberg.org/senlabs/senryu).

Adapt the variable(s) at the start of the scripts according to your setup.
Then run:
* `./build.sh` -- builds Tracker in the original haiku sourcetree and copies over relevant artifacts to `./generated`
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
