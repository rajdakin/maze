# Interacting with the game

## How to tell Lua to?
Simply add `-i` in the command line (`lua -i maze.lua` instead of `lua maze.lua`)

## Commands
There are some commands you might want to use.

The level object refer to eveything in the level. (By the way it is for now the unique main object.)
### Level commands
Set the room visibility to `status`:
```lua
level:setAllRoomsSeenStatusAs(status) -- where status is either true or false
```

Print the map:
```lua
--[[ arguments are: is_ended, objects
	 - is_ended is if the game is ended (in that case yes)
	 - objects is the object map (in that case, you can't have anything)
  ]]
level:printLevelMap(true, {})
```

Change room:
```lua
level:setRoom(room) -- where room is the new room number
```
Rooms are a single array, but printing the map divide them in `level:getColumnCount()` columns, and the one on top left is the room number 1.

Simulate a move:
```lua
level:setRoom(room) -- sets the new room
--[[ arguments are: is_ended, objects
	 - is_ended is if the game is ended (in that case yes, but you might want to say no)
	 - objects is the object map (in that case, you can't have anything)
	   objects is an array that contains arguments:
	   - sword: boolean; true if you "have" a sword
	   - key: boolean; true if you "have" a key
	   - redkey: boolean; true if you "have" a "red key...?"
  ]]
level:checkLevelEvents(is_ended, objects)
```

There are some other commands.
### Game commands
Restart the game with the current state
```lua
main()
```

Reset the `level` object
```lua
resetMaze()
```

## Misc
If you want to create a level, write:
```lua
level = [level]
level:setAllRoomsSeenStatusAs(false)
```
where `[level]` is your level (see [CONTRIBUTING.md#Creating levels](CONTRIBUTING.md#creating-levels))
Then write
```lua
main()
```
to start the level testing.
