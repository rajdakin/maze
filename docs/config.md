# What is this

This is the documentation for the configuration.

It is implemented in [config.lua](/config.lua) and the actual configuration is in `settings.cfg`.

## Quick summary

1. [How to change the configuration](#how-to-change-the-configuration)
1. [What is in this configuration](#what-is-in-this-configuration)

## How to change the configuration

There is an in-game settings menu. The settings are also saved using the game's custom file format, in `settings.cfg`.

## What is in this configuration

There are several modules in the configuration, each of them having different options.

Every option listed below is modifiable by editing the value. The default value is put in parenthesis and is automatically generated when absent from the configuration file.

### Level manager configuration

Inside the `levelManager` object.

- `loadTestLevels` \(`false`): set to `true` if you want to use the test file. \(Unrecommanded for normal players, also read the [README.md@line52](/README.md#L52)).
- `levelConfig`: levels configuration.

### Level configuration

Inside the `levelManager` object, `levelConfig` subobject.

- `minimapDisplay` \(`true`): set to `false` to remove the minimap.
- `minimapViewingSize` \(array with `3` and `3`): change the `3`s by any positive odd number \(result not guaranteed otherwise) to change the minimap's size.
- `mapDisplayable` \(`true`): set to `false` if you think there shouldn't be any full map \(`m` command in game).
- `mapOffset` \(array with `0` and `6`): the size taken when drawing the minimap.
- `difficulty` \(`3`): ranging from very easy \(`1`) to hard \(`4`), can be any whole number between.
  1. Very easy: no map reset, no object destroyed when trying to pick two objects of the same kind at once
  2. Easy: map reset, no object destroyed when trying to pick two objects of the same kind at once
  3. Normal: map reset, new object destroyed when picking two objects of the same kind at once
  4. Hard: map reset, both objects \(held and new) destroyed when picking two objects of the same kind at once

### Keyboard configuration

Inside the `keyboard` object.

- `directions` (objects which Lua equivalent is `{up = 'u', down = 'd', left = 'l', right = 'r'}`): the directions quickkeys (up, down, left, right). Changing this configuration may break other keys as movement has predecence on about everything else.

### Console configuration

Inside the `console` object.

- `logLevel` \(`2`): the logging level. Ranges from 0 to 4. Also includes messages with lower log level.
  0. Fatal error
  1. Error
  2. Warning + developer warning \(see also `developerMode`)
  3. Info
  4. Log
- `developerMode` \(`false`): set to `true` to have the allowed \(see also `logLevel`) developer messages.

### Miscellaneous options

Inside the `options` object.

- `eqc` \(1): Number between 1 and 5, the "Exit"/"Quit"/"Close"/... debate.
