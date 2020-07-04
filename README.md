# Maze

My first Lua game, a short maze game.

Trapped in a maze, avoid being killed by monsters and traps and reach the exit with the good key!

## How to play

To play this game, you must

1. Fork this repo *only the first time*
2. Start a command line in the repo
3. Run `lua maze.lua`

### Controls

- u or up arrow: move up \(north)
- d or down arrow: move down \(south)
- l or left arrow: move left \(east)
- r or right arrow: move right \(west)
- w: take what's on your room and take attention to what's near (aka, skip a turn)
- m: print the map
- h: help
- suicide: suicide (also reset the map)
- q: quit :\(

Follow every instruction by a hit to the enter key. Multiple commands are not supported as of yet.

## How can I contribute/change the configuration/see the documentations for the different classes/etc

See [the `docs` folder](/docs)

## Notes

*The line pointed by this documentation can be inexact.*

- Every build is tested on xterm, and should work on rxvt. To have the best render if you don't use these, test if your terminal accepts the following \(Lua-style) escape codes:
  1. Bold: \\27\[01m
  2. Faint: \\27\[02m *not working on RXVT*
  3. Reset faint/bold: \27\[22m
  4. Reverse video \(background <-> foreground colors) *\(this is mostly used to render walls)*: \\27\[07m
  5. Crossed-out: \\27\[09m *not working on RXVT*
  6. Foreground colors: \\27\[3cm -styled \(where c is the color, a whole number between 0 and 7)
  7. Background colors: \\27\[4cm -styled \(where c is the color, a whole number between 0 and 7)
  8. Cursor UDLR movements: \\27\[1A \\27\[1B \\27\[1D \\27\[1C
  9. Cursor absolute horizontal: \\27\[G
  10. Cursor save state: \\27\[s
  11. Cursor load state: \\27\[u
  12. You may want italic \(used for lores): \\27\[3m
- If you want to change the starting level:
  1. To play a real level, write a whole number > 0 instead of 1 in [level.lua@line376](level.lua#L376)
  2. To play a test level, write a whole number < 0 instead of -1 in [level.lua@line374](level.lua#L374) **and** set `loadTestLevels` to `true` in the advanced settings (option `levelManager/loadTestLevels`)
- If you want to interact with the game after ending it, see [INTERACTING.md](INTERACTING.md)
- If you want to create a level, see [docs/level.md#Creating levels](docs/level.md#creating-levels)
- If you want to contribute, see [docs/lang.md](docs/lang.md), [docs/level.md](docs/level.md) and [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)
