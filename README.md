#TiledLayer

## Description
`TiledLayer` is a replacement for iOS `CATiledLayer`, with many extra features:

- different scaling factors for x and y directions
- choose your own scaling steps (instead of only x2)
- any layout of tiles possible
- non-square tiles, different size tiles in one layer
- match the scaling factor to the native resolution of your tiles
- set a margin to load tiles just outside of the visible ones
- you get notified when a tile is no longer needed
- allow 'crisp' tiles: create tiles that have the same resolution as the screen

## Usage

The tiles are actually objects: they must be, or derive from the `Tile` class,
which is itself a `CALayer`. You create a class implementing the
`TileProvider` interface and register that with the `TiledLayer`. This
`TileProvider` is called by the `TiledLayer` every time a new tile is needed.
The `TileProvider` has full control over how the tiling is done, how big
the tiles are, what their native scale is, etc. The `TiledLayer` simply says
"give me a tile that covers this point in the world".
And it will keep requesting tiles like that until the visible area is
filled.

There is also a `StandardTileProvider` that uses zoom scales with a factor two.

The header files have more documentation.

A small `ViewController` class is included that shows a basic way of using
the classes. In that one, the background of the tiles changes with
zoom scale, so it is easy to see when it swaps to new tiles.

## License
Copyright (c) 2012-2013 René Dekker, Renevision

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

__THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.__


