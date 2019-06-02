# Interacting with the game

## How to tell Lua to?
Simply add `-i` in the command line (`lua -i maze.lua` instead of `lua maze.lua`)

## Commands
There are some commands you might want to use.

The `currentConfig` object is the active configuration. (You need to reset every objects you modify the configuration in order to apply modifications.)
### Configuration commands
Get/set the level manager configuration:
```lua
currentConfig:getLevelManagerConfig() -- If you want to get
currentConfig.__levelManagerConfig    -- If you want to set - reset: levelManager
```

Get/set whether the level manager loads the test levels:
```lua
currentConfig:getLevelManagerConfig():doLoadTestLevels()        -- Get
currentConfig.__levelManagerConfig.__loadTestLevels = [boolean] -- Set - reset: levelManager
```

Get/set the level configuration:
```lua
currentConfig:getLevelManagerConfig():getLevelConfig() -- If you want to get
currentConfig.__levelManagerConfig.__levelConfig       -- If you want to set - reset: levelManager
```

Get/set the minimap configuration:
```lua
currentConfig:getLevelManagerConfig():getLevelConfig():getMapSize()   -- If you want to get
currentConfig.__levelManagerConfig.__levelConfig.__mapSize = {[w, h]} -- If you want to set - reset: levelManager
-- w is the width, the number of tiles per line
-- h is the height, the number of tiles per column
```

Get/set the `reverseMap` configuration (meaning, when it goes up after each commands):
```lua
currentConfig:getLevelManagerConfig():getLevelConfig():getYoffset()   -- If you want to get
currentConfig.__levelManagerConfig.__levelConfig.__mapOffset[2] = off -- If you want to set - reset: levelManager
-- off is the vertical offset, the number of lines
```


The `levelManager` object refer to eveything in the levels.
### Level manager commands
Reset the level manager:
```lua
levelManager:initialize()
```

Get the active level:
```lua
levelManager:getActiveLevel()
```

Get all loaded levels:
```lua
levelManager:getLevels()
```

Get the active level ID:
```lua
levelManager:getLevelNumber()
```

Set the active level ID:
```lua
levelManager:setLevelNumber([level ID])
```

### Level commands
`level` is a level.

Set the room visibility to `status`:
```lua
level:setAllRoomsSeenStatusAs(status) -- where status is either true or false
```

Print the map:
```lua
--[[ arguments are: is_ended, objects, doesDisplayAllMap
	 - is_ended is if the game is ended (in that case yes)
	 - objects is the object map (in that case, you can't have anything)
	 - whether to display the whole map or just the little square
  ]]
level:printLevelMap(true, {}, true)
```

Change room:
```lua
level:setRoom(room) -- where room is the new room number
```
Rooms are a single array, but printing the map divide them in `level:getColumnCount()` columns, and the one on top left is the room number 1 and the room number 2 is in the second column.

Simulate a move:
```lua
level:setRoom(room) -- sets the new room
--[[ arguments are: is_ended, objects
	 - is_ended is if the game is ended (in that case yes, but you might want to say no)
	 - objects is the object map (in that case, you can't have anything)
	   objects is an Objects instance (prefab 1)
	 returns an EventParsingReturn
  ]]
level:checkLevelEvents([is_ended], [objects])
```


There are some other commands.
### Game commands
Restart the game with the current state
```lua
main()
```

Reset the active level
```lua
resetMaze()
```

## Misc
***Obsolete!***

If you want to create a level, write:
```lua
level = [level]
level:setAllRoomsSeenStatusAs(false)
```
where `[level]` is your level \(see [docs/level.md#Creating levels](/docs/level.md#creating-levels)).

Then write
```lua
main()
```
to start the level testing.
