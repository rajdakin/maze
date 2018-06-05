# Maze
My first Lua game, a short maze game.

Trapped in a maze, avoid being killed by monsters and traps and reach the exit with the good key!

# How to play
To play this game, you must
1. Fork this repo
2. Start a command line in the repo
3. Run `lua maze.lua`

Controls:
- u: move up (north)
- d: move down (south)
- l: move left (east)
- r: move right (west)
- w: take what's on your room and take attention to what's near
- m: print the map
- q: quit :(

# Notes
1. To play a real level, write a whole number > 0
2. To play a test level, write a whole number < 0
- Every build is tested on xterm, and should work on rxvt. To have the best render if you don't use these, test if your terminal accepts the following (Lua-style) escape codes:
  1. Bold: \27[01m
  2. Faint: \27[02m
  3. Reset faint/bold: \27[22m
  4. Reverse video (background <-> foreground colors) *(this is mostly used to render walls)*: \27[07m
  5. Crossed-out: \27[09m
  6. Foreground colors: \27[3cm -styled (where c is the color)
  7. Background colors: \27[4cm -styled (where c is the color)
  8. Cursor UDLR movements: \27[1A \27[1B \27[1C \27[1D
  9. Cursor absolute horizontal: \27[G
  10. Cursor save state: \27[s
  11. Cursor load state: \27[u
- If you want to change the size of the map, change the {width, height} values in [config.lua@line21](config.lua#L21)
- If you want to interact with the game after ending it, see [INTERACTING.md](INTERACTING.md)
- If you want to play an other level, change the number inside the brackets in the `get_active_level` function to a pre-set level in the `initialize_levels` function in [level.lua](level.lua)
- If you want to create a level, see [CONTRIBUTING.md#Creating levels](CONTRIBUTING.md#creating-levels)
- If you want to contribute, see [CONTRIBUTING.md](CONTRIBUTING.md)
