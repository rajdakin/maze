# Maze
My first Lua game, a short maze game.

Trapped in a maze, avoid being killed by monsters and traps and reach the exit with the good key!

# How to play
To play this game, you must
1. Fork this repo
2. Start a command line in the repo
3. Run `lua maze.lua`

Controls:
- u or up arrow: move up \(north)
- d or down arrow: move down \(south)
- l or left arrow: move left \(east)
- r or right arrow: move right \(west)
- w: take what's on your room and take attention to what's near
- m: print the map
- q: quit :\(
Follow every instruction by a hit to the enter key.

# Settings
*The line pointed by this documentation can be inexact.*

It is planned to add a main menu (or even an in-game menu), but for now you'll need to edit the source code.

Every option listed below is modifiable by editing the value (after the `=` if not specified).

## Level manager configuration
Inside the `levelManagerConfiguration` block.
- `loadTestFile` (`false`): set to `true` if you want to use the test file. (Unrecommanded, you must also change [the `+` sign in the `main` loop](maze.lua#L182) by a `-`).

## Level configuration
Inside the `levelConfiguration` block.
- `minimapDisplay` (`true`): set to `false` to remove the minimap.
- `minimapViewingSize` (`{3, 3}`): change the `3`s by any positive odd number (result not guaranteed otherwise) to change the minimap's size.
- `mapDisplayable` (`true`): set to `false` if you think there shouldn't be any full map (`m` command in game).
- `mapYoffset` (`7`): see [README.md@line71](README.md#L71].
- `difficulty` (`3`): ranging from very easy (`1`) to hard (`4`), can be any whole number between.
  1. Very easy: no map reset, no object destroying
  2. Easy: map reset, no object destroying
  3. Normal: map reset, new object destroying
  4. Hard: map reset, both objects (held and new) destroying

## Console configuration
In the `consoleConfiguration` block.
- `logLevel` (`2`): logging level.
  0. Fatal error
  1. Error
  2. Warning + developer warning (see also `developerMode`)
  3. Info
  4. Log
- `developerMode` (`false`): set to `true` to have the developer warnings.

# Notes
*The line pointed by this documentation can be inexact.*

- Every build is tested on xterm, and should work on rxvt. To have the best render if you don't use these, test if your terminal accepts the following \(Lua-style) escape codes:
  1. Bold: \27[01m
  2. Faint: \27[02m *not working on RXVT*
  3. Reset faint/bold: \27[22m
  4. Reverse video \(background <-> foreground colors) *\(this is mostly used to render walls)*: \27[07m
  5. Crossed-out: \27[09m *not working on RXVT*
  6. Foreground colors: \27[3cm -styled \(where c is the color, a whole number between 0 and 7)
  7. Background colors: \27[4cm -styled \(where c is the color, a whole number between 0 and 7)
  8. Cursor UDLR movements: \27[1A \27[1B \27[1D \27[1C
  9. Cursor absolute horizontal: \27[G
  10. Cursor save state: \27[s
  11. Cursor load state: \27[u
  12. You may want italic \(used for lores): \27[3m
- If you want to change the starting level:
  1. To play a real level, write a whole number > 0 instead of 1 in [level.lua@line234](level.lua#L234)
  2. To play a test level, write a whole number < 0 instead of -1 in [level.lua@line232](level.lua#L232) **and** set `loadTestLevels` to `true` in [config.lua@line38](config.lua#L38)
- If you want to change the size of the map, change the `{width, height}` values in [config.lua@line39](config.lua#L39)
- If you have a taller or smaller screen than me, and that the instructions you give doesn't print on the following line of the last instruction, leaving one white space, change the `mapYoffset` value in [config.lua@line40](config.lua#L40)
- If you want to interact with the game after ending it, see [INTERACTING.md](INTERACTING.md)
- If you want to start elsewhere than the first level, change the number inside the equals sign in the `Level:initialize()` function to a pre-set level number in [level.lua@line341](level.lua#L341)
- If you want to create a level, see [CONTRIBUTING.md#Creating levels](CONTRIBUTING.md#creating-levels)
- If you want to contribute, see [CONTRIBUTING.md](CONTRIBUTING.md)
