# Interacting with the game

## How to tell Lua to

Simply add `-i` in the command line (`lua -i maze.lua` instead of `lua maze.lua`)

## Commands

There are some commands you might want to use.

The `currentConfig` object is the active configuration. (You need to reset every objects you modify the configuration in order to apply modifications.)

### Configuration commands

Get/set the level manager configuration:

```lua
currentConfig:getLevelManagerConfig() -- If you want to get - set - reset: levelManager
levelManager:getConfig()              -- Same, but recommanded
```

Get/set whether the level manager loads the test levels:

```lua
levelManager:getConfig():doLoadTestLevels()           -- Get
levelManager:getConfig().__loadTestLevels = [boolean] -- Set - reset: levelManager
```

Get/set the level configuration:

```lua
levelManager:getConfig():getLevelConfig()            -- If you want to get - set - reset: levelManager
levelManager:getLevel(level):getLevelConfiguration() -- Almost the same
-- If a level has a non-default config, you must use the second variant
```

Get/set the various minimap configuration:

```lua
levelManager:getConfig():getLevelConfig():doesDisplayMinimap()         -- Get
levelManager:getConfig():getLevelConfig().__displayMinimap = [boolean] -- Set

levelManager:getConfig():getLevelConfig():getMapSize()         -- If you want to get
levelManager:getConfig():getLevelConfig().__mapSize = {[w, h]} -- If you want to set - reset: levelManager
-- w is the width, the number of tiles per line
-- h is the height, the number of tiles per column
```

Get/set the map configuration:

```lua
levelManager:getConfig():getLevelConfig():doesDisplayMinimap()     -- Get
levelManager:getConfig():getLevelConfig().__displayMap = [boolean] -- Set
```

Get/set the `reverseMap` configuration (meaning, how much does it goes up after each command):

```lua
levelManager:getConfig():getLevelConfig():getYoffset()         -- If you want to get
levelManager:getConfig():getLevelConfig().__mapOffset[2] = off -- If you want to set - reset: levelManager
-- off is the vertical offset, the number of lines
```

Get/set the difficulty configuration:

```lua
levelManager:getConfig():getLevelConfig():getDifficulty()         -- Get
levelManager:getConfig():getLevelConfig().__difficulty = [1 to 4] -- Set
```

Get/set the log level:

```lua
currentConfig:getConsoleConfig():getLogLevel()          -- Get
currentConfig:getConsoleConfig().__logLevel = [boolean] -- Set
```

### Level manager commands

The `levelManager` object refers to everything in the levels.

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
     - objects is the Objects instance (in this case the default empty one)
     - whether to display the whole map or just the minimap
  ]]
level:printLevelMap(true, Objects(1), true)
```

Change room:

```lua
level:setRoom(room) -- where room is the new room number
```

Rooms are a single array, but printing the map divide them in `level:getColumnCount()` columns, and the one on top left is the room number 1 and the room number 2 is in the second column.
It is possible to get a room from its (x, y) coordinates using the `level:getRoomFromCoordinates(x, y)` method (where (1, 1) is the top left corner). The general formula to

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

### Game commands

There are some other commands.

Restart the game with the current state

```lua
main()
```

Reset the active level

```lua
gameState:onLevelInitialize()
```

## Misc

If you want to create a level, write:

```lua
level = [level]
level:setAllRoomsSeenStatusAs(false)
levelManager.__levels[levelManager:getLevelNumber()] = level
```

where `[level]` is your level \(see [docs/level.md#Creating levels](/docs/level.md#creating-levels)).

Then write

```lua
main()
```

to start the level testing. (This method is not recommanded.)
