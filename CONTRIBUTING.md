# Contributing

## Creating levels
If you want to submit a level, please put the code in `add_contrib_levels` in [contribution.lua](contribution.lua)

If you want to create a level, here's what to do:
### Creating the actual level
A level is an instance of the Level class. To create a new instance, simply call `Level(args)`.
`args` are the arguments of the level constructor.

There is two ways of creating a level.

The old \(obsolete) way of doing it is to call `Level(init_room, col_cnt, room_datas)`.
This way will be removed later.

The new way is by using a big array and passing it to the constructor.

To create a level, you need ~~three~~ five informations:
- The level configuration. \(You might not want to create a game configuration and use the `currentConfig:getLevelConfig()` level configuration.) Goes into ID `level_conf` \(optional).
- The starting room. This is where you start. Goes into ID `starting_room`.
- The column count. It determines how many rooms per line there is. Goes into ID `column_count`.
- The level datas. Goes into ID `rooms_datas`. It is an array made of:
  - A first line from `-[column count - 1]` to `0` made of empty arrays. These are internally rooms, but are (normally) never displayed nor accessible.
  - A multiple of column count arrays, which constitute the level itself. Each array can be empty, or contains the following:
    - the exit:
	    - `exit`: boolean (in that case true)
	    - `dir_exit`: string (`up`, `down`, `left`, `right`)
    - a door: (needs and destroy a `key`)
	    - `door`: boolean (in that case true)
	    - `dir_door`: string (`up`, `down`, `left`, `right`)
    - a red door: (needs and destroy a `redkey`)
	    - `reddoor`: boolean (in that case true)
	    - `dir_reddoor`: string (`up`, `down`, `left`, `right`)
    - `up`: boolean (can we go in that direction)
    - `down`: boolean (can we go in that direction)
    - `left`: boolean (can we go in that direction)
    - `right`: boolean (can we go in that direction)
    - `monster`: boolean (is there a monster in that room)
    - `sword`: boolean (is there a sword in that room)
    - `key`: boolean (is there a key in that room)
    - `redkey`: boolean (is there a ~~red~~ bloody key on that room)
    - `trap`: boolean (is this room a trap <=> instanteaneous death)
    - a grave: It is a special case. A "grave" is a room, called `graveorig` (set to true) that leads to the left room, which is a `grave` room.
	  - `graveorig`: boolean (is this the grave origin <=> right)
      - `grave`: boolean (this is the grave destination <=> left)
      - `deadlygrave`: boolean (is the grave a trap?)
	    - \(Optional) `keyneeded`: if `deadlygrave`is set, this string gives the needed key (`key` or `redkey`) to exit the grave
      - \(Optional) `exitdir`: if `deadlygrave`is set, this string gives the direction of the grave's exit
  - Then finally an empty line (of size of the number of columns) of empty arrays.
- Lores, texts that are at the beginning and the end of the level. It is an array of size 2, the first string is displayed at the beginning of the level, the second is an other array with 1=false and 2=true, and where that boolean is wether you died or not (false=you survived). You can set it to a string so it defaults to false and a default string for when you died.

### Testing the level
To test the level, you can either run it from the interactive mode (see [INTERACTING.md#misc](INTERACTING.md#misc)) or run it by putting the level as the last instruction of the `add_contrib_levels` in [contribution.lua](contribution.lua) using the level writing template wrote in the very beginning of that function.

## Implementing new things
This will be soon implemented.
