# Akita icon work

`akita-logo_simplified.svg` is the Akita drawing of the owner: a Shiba in a wooden box with a bone, flat colours and brown outlines, made for the icon (64 x 64). The whole icon comes from this one drawing, at every size.

`python3 flat.py akita-logo_simplified.svg akita-flat.svg 0.05 0` (needs `shapely`) flattens it (strokes to outlines, shapes merged by colour) into plain filled paths: 20 shapes. `lodtool akita.hvif akita-flat.svg 99 0 4 0`
(`lodtool.cpp`, built against hvif-tools) makes the HVIF (10 KB; an `.iom` name makes the file for Icon-O-Matic). The hex of `akita.hvif` is the `vector_icon` of `senryu/src/apps/tracker/Tracker.rdef`.
`hvifrender.cpp` renders an HVIF with the renderer of Haiku at 16, 32, 48, 64 and 128 px; `akita-renders-haiku.png` shows them.

(Earlier versions had a pixel icon for small sizes and the traced logo for large ones: one drawing replaces both.)
