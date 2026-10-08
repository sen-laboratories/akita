<p align="center">
  <img src="images/akita-logo.jpg" width=320 />
</p>

<h1 align="center">Akita</h1>
<h2 align="center">
  <strong>A</strong>ugmented 
  <strong>K</strong>nowledge
  <strong>I</strong>nterface for
  <strong>T</strong>racker
  <strong>A</strong>dvanced
</h2>

<p align="center">
  A semantic take on Tracker, the Haiku file manager. Keeps changes to a sane level and tries to "just" blend in but offer some semantic sprinkle dust.
</p>

# About

This repository contains the changes to Haiku Tracker for integrating with SEN and providing support for linked semantic navigation and file manipulation.

# Build

Tracker is part of Haiku, so as to not complicate things, SEN specific adaptations are currently kept within a fork of the Haiku source.
For building, you need to check out (for trying out) or fork (for development) haiku first.
This will soon be packaged as a proper Haiku package (HPKG) and included out of the box in the 
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
