# What is this?
This is the documentation for the configuration.

It is contained in [config.lua](/config.lua).

# Quick summary
1. [What is in this configuration?](#what-is-in-this-configuration)
2. [Why can't I modify the configuration in-game?](#why-cant-i-modify-the-configuration-in-game)

# What is in this configuration?
There are several modules in the configuration, each of them having different options.

*The lines pointed by this documentation can be inexact. If that's the case, search around in the file to find the option.*

Every option listed below is modifiable by editing the value \(after the `=` if not specified).

## Level manager configuration
Inside the `levelManagerConfiguration` block.
- `loadTestFile` \(`false`): set to `true` if you want to use the test file. \(Unrecommanded for normal players, you must also change [the `+` sign in the `main` loop](/maze.lua#L182) to a `-`).

## Level configuration
Inside the `levelConfiguration` block.
- `minimapDisplay` \(`true`): set to `false` to remove the minimap.
- `minimapViewingSize` \(`{3, 3}`): change the `3`s by any positive odd number \(result not guaranteed otherwise) to change the minimap's size.
- `mapDisplayable` \(`true`): set to `false` if you think there shouldn't be any full map \(`m` command in game).
- `mapYoffset` \(`7`): see [README.md@line45](/README.md#L45).
- `difficulty` \(`3`): ranging from very easy \(`1`) to hard \(`4`), can be any whole number between.
  1. Very easy: no map reset, no object destroying
  2. Easy: map reset, no object destroying
  3. Normal: map reset, new object destroying
  4. Hard: map reset, both objects \(held and new) destroying

## Console configuration
Inside the `consoleConfiguration` block.
- `logLevel` \(`2`): the logging level. Ranges from 0 to 4.
  0. Fatal error
  1. Error
  2. Warning + developer warning \(see also `developerMode`)
  3. Info
  4. Log
- `developerMode` \(`false`): set to `true` to have the developer warnings.

# Why can't I modify the configuration in-game?
There are two reasons to this:
1. There are currently no other states than the in-game.
2. There is no file interface, so the game cannot save nor load any configuration.
