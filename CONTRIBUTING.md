# Contributing

## Creating levels
If you want to create a level, here's what to do:

If you want to submit a level, please put the code in `add_contrib_levels` in [contribution.lua](contribution.lua)

### Creating the actual level
A level is an instance of the Level class. To create a new instance, simply call `Level(args)`.
`args` are the arguments of the level constructor.
To create a level, you need three informations:
- The starting room. This is where you start.
- The column count. It determines how many rooms per line there is.
- The level datas. It is an array made of:
  - A first line from `-[column count - 1]` to `0` made of empty arrays. These are internally rooms, but are (normally) never displayed nor accessible.
  - A multiple of column count arrays, which constitute the level itself. Each array can be empty, or contains the following:
    - the exit:
	  - `exit`: boolean (in that case true)
	  - `dir_exit`: string (`up`, `down`, `left`, `right`)
    - `up`: boolean (can we go in that direction)
    - `down`: boolean (can we go in that direction)
    - `left`: boolean (can we go in that direction)
    - `right`: boolean (can we go in that direction)
    - `monster`: boolean (is there a monster in that room)
    - `sword`: boolean (is there a sword in that room)
    - `key`: boolean (is there a key on that room)
    - a door:
	  - `door`: boolean (in that case true)
	  - `dir_door`: string (`up`, `down`, `left`, `right`)
    - `redkey`: boolean (is there a ~~red~~ bloody key on that room)
    - a red door:
	  - `reddoor`: boolean (in that case true)
	  - `dir_reddoor`: string (`up`, `down`, `left`, `right`)
    - `trap`: boolean (is this room a trap <=> instanteaneous death)
    - a grave: It is a special case. A "grave" is a room, called `graveorig` (set to true) that leads to the left room, which is a `grave` room.
	  - `graveorig`: boolean (is this the grave origin <=> right)
      - `grave`: boolean (this is the grave destination <=> left)
      - `deadlygrave`: boolean (is the grave a trap?)
	  - \(Optional) `keyneeded`: if `deadlygrave`is set, this string gives the needed key (`key` or `redkey`) to exit the grave
      - \(Optional) `exitdir`: if `deadlygrave`is set, this string gives the direction of the grave's exit
  - Then finally an empty line (of size of the number of columns) of empty arrays.

### Testing the level
To test the level, you can either run it from the interactive mode (see [INTERACTING.md#misc](INTERACTING.md#misc)) or run it by putting as the last instruction of the `add_contrib_levels` in [contribution.lua](contribution.lua)

## Implementing new things
This will be soon implemented.
