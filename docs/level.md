# What is this?
This is the levels documentation.

# Quick summary
1. [How to play a level?](#how-to-play-a-level)
   1. [How to play the next level?](#how-to-play-the-next-level)
   2. [How to play a particular level?](#how-to-play-a-particular-level)
2. [How can I contribute?](#how-can-i-contribute)
   1. [Creating the actual level](#creating-the-actual-level)
      1. [Testing the level](#testing-the-level)

# How to play a level?

## How to play the next level?
Just win the current level.

If you can't because you've destroyed a key/red key/sword that you needed, then do a `suicide` \(there is for now no live count nor an other way to win in that condition).

If you can't win the current level because it is too hard, see [How to play a particular level?](#how-to-play-a-particular-level) and restart the game.

## How to play a particular level?
To do that, you'll need the level number. It is simply the number of level there is before plus one \(the first level is the level `1`). *Warning: this is **NOT** the level ID.*

Then, in [level.lua@line357](/level.lua#L357), there should be this line:
```lua
		self.__level_number = 1
```
*If it is not this exact line, starting with two tabs, search around in the file.*
Replace the `1` by the level number, then start the game.

# How can I contribute?

## Creating levels
If you want to submit a level, please put the code in `add_contrib_nontest_levels` in [contribution.lua@line1](/contribution.lua#L1) for a real level or in `add_contrib_test_levels` in [contribution.lua@line13](/contribution.lua#L13) for a test level.

Please note that you can also call the `addTestLevelInstance` or `addLevelInstance`.
It takes in a level instance. It is designed to allow to add instances of subclasses of the Level class \(created by [instanciating](class.md#instanciate-a-class) a [newly created subclass](class.md#creating-a-subclass))

If you want to create a level, here's what to do:
### Creating the actual level
*It is planned to do a level editor, but there are none for now, sorry.*

The current way to add a level is by using a level name and a big table and passing it to the `level_manager:addLevel` function.

To create a level, you need eight informations:
- The level table version. Currently, there are two. The last one is described here.
- The level configuration. \(You might not want to create a game configuration and use the `currentConfig:getLevelConfig()` level configuration.) Goes into ID `level_conf` *\(optional)*.
- The starting room. This is where you start. Goes into ID `starting_room`.
- The column count. It determines how many rooms per line there is. Goes into ID `column_count`.
- The level datas. Goes into ID `rooms_datas`. It is a table made of:
  - A first line from `-[column count - 1]` to `0` made of empty tables. These are internally rooms, but are \(normally) never displayed nor accessible.
  - A multiple of column count tables, which constitute the level itself. Each table can be empty, or contains the following:
    - the exit:
      - `exit`: boolean \(in that case `true`)
      - `dir_exit`: string \(`up`, `down`, `left`, `right`)
    - a door: \(needs and destroy a `key`)
      - `door`: boolean \(in that case `true`)
      - `dir_door`: string \(`up`, `down`, `left`, `right`)
    - a red door: \(needs and destroy a `redkey`)
        - `reddoor`: boolean \(in that case `true`)
        - `dir_reddoor`: string \(`up`, `down`, `left`, `right`)
    - `up`: boolean \(can we go in that direction?)
    - `down`: boolean \(can we go in that direction?)
    - `left`: boolean \(can we go in that direction?)
    - `right`: boolean \(can we go in that direction?)
    - `monster`: boolean \(is there a monster in that room?)
    - `sword`: boolean \(is there a sword in that room?)
    - `key`: boolean \(is there a key in that room?)
    - `redkey`: boolean \(is there a ~~red~~ bloody key on that room?)
    - `trap`: boolean \(is this room a trap <=> instanteaneous death) \(note that it is planned to have other types of traps)
    - a grave: It is a special case. A "grave" is a room, called `graveorig` \(set to `true`) that leads to the left room, which is a `grave` room.
      - `graveorig`: boolean \(is this the grave origin <=> right)
      - `grave`: boolean \(this is the grave destination <=> left)
      - `deadlygrave`: boolean \(is the grave a trap?)
        - \(Optional) `keyneeded`: if `deadlygrave` is set, this string gives the needed key \(`key` or `redkey`) to exit the grave
        - \(Optional) `exitdir`: if `deadlygrave` is set, this string gives the direction of the grave's exit
  - Then finally an empty line \(of size of the number of columns) of empty tables.
- The map availability when you've finished the level. It is a function that takes in whether you're dead and what objects do you have and must return a boolean value \(`true` means you unlocked the full map). Goes into ID `map_reveal`.
- The level winning when you finish the level alive. It is a function that takes in what objects do you have and must return a boolean value \(note that if you're dead, you cannot win) \(`true` means you win). Goes into ID `win_level`.
- Lores, texts that are at the beginning and the end of the level. It is a function that inputs whether you're dead and what objects you have and outputs a table with the `state` ID is the key and the `alt` ID is the alternative of the ending lore. Goes into ID `alternative_lore`. Lores are loaded from the level langs dictionaries `.lld`.

### Testing the level
To test the level, you can either run it from the interactive mode \(see [INTERACTING.md#misc](/INTERACTING.md#misc)) or run it by putting the level as the last instruction of the `add_contrib_levels` in [contribution.lua](/contribution.lua) using the level registering template wrote in the very beginning of that function.
