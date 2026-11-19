# Akita icon work

`akita-logo_simplified.svg` is the logo as the owner traced it (low complexity, high fidelity). The icon has two drawings in one HVIF, chosen by the size (the level of detail is size / 64):

* **under about 36 px (16, 24, 32): a pixel icon**, `akita-pixel-16.svg` (a 16x16 grid in `pixel.py`: the cream Shiba face in its box; edit the grid and run `python3 pixel.py`).
* **from about 36 px: the logo**, `akita-flat.svg`: `python3 flat.py akita-logo_simplified.svg akita-flat.svg <tolerance> <minarea>` (needs `shapely`) flattens the SVG (strokes to outlines, clip paths cut,
  gradients to their middle colour, neighbours of one colour merged) into plain filled paths: 30 shapes, 63 paths.

`lodtool akita.hvif akita-pixel-16.svg 99 0 0.56 0  akita-flat.svg 0 0.56 4 0.56` (`lodtool.cpp`, built against hvif-tools; for each file: the number of base shapes, the minimum level of the base, the maximum of all
its shapes, the minimum of the detail) puts them in one icon (an `.iom` name makes the file for Icon-O-Matic, where the levels are the "min/max visibility" of the shapes). `akita.hvif` is 15 KB; its hex is the
`vector_icon` of `senryu/src/apps/tracker/Tracker.rdef`. `hvifrender.cpp` renders an HVIF with the renderer of Haiku at 16, 32, 48, 64 and 128 px (it honours the level of detail); `akita-renders-haiku.png` shows them.
