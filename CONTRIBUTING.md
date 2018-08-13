# Contributing

## Adding support for an other lang
If you want to add an other lang, here is how to do it.

### 1. Adding the dictionary module
In [dictionary.lua@line250](dictionary.lua#L250), there is a line like `langs = {{`...

After the first opening curly bracket, insert this:
`{id = "[id]", name = "[name]", fallback = "[fallback]"}, `
where:
- `[id]` is the lang ID (usually two lowercase letters, then a `_`, then two uppercase letters). It will be reused internally and **must be unique**.
- `[name]` is the display name of the lang. It will only be used to display on the screen.
- `[fallback]` is the lang's fallback's ID. It defaults to `en_US` and is used when there is no available translation. If you don't need one, then remove `, fallback = "[fallback]"`. If yu don't want a fallback, replace `"[fallback]"` by `false`.

### 2. Setting the lang to be the default
**This should only be used on the tests**, undo this before creating a pull request

Two lines ahead, there is `self.__active_lang = langs[1].id`. Replace what is after the equals by the ID you put a few lines up, like so: `"en_US"` (if your lang has the ID `en_US`).

### 3. Creating the lang file
Finally, go in the `lang` directory and create a file named `[id].lgd` (where `[id]` is the ID). (`lgd` means LanG Dictionary.)

You may create this file by using the Notepad (Windows), Nano (command-line *nix), Mousepad (*nix), Notepad++ (Windows and MacOS?) or any other **RAW TEXT** file editor. (That means, OpenOffice won't work.)
Then save a new/empty file **and remove EVERYTHING from the save name, including the `.txt`**.

**Beware: if the file finishes by `.txt`, you created it wrong**. It won't work.

**Beware: if it is written anywhere that this file is a text file, you very likely created it wrong**. It won't work.

It is possible that you created it wrong even if it display `.lgd` at the end of the name: you simply hid the file extensions.

*If you created it wrong, delete it and start again. It won't work.*

### 4. Translating
After that, in that file, write the translations.

A few notes:
- Each string before the `.` is a state. If there is no translations found in the requested state, it will move one step up. If there is still no trnslation in the root state, it asks the fallback (if one).
- The `:` is an alternative marker. Before is the group name, after is the alternative name. The first time it sees a `:`, it set the group alternative to this alternative and set the default to this alternative.
- You can add some things:
  1. `%%`: replaced by `%` at translation time.
  2. `%b`: replaced by `X` or `O` at translation time.
  3. `%c[]m`: replaced by a color at reading time. The color is what replaces `[]` (see ASCII escape code `ESC[`). No check.
  4. `%j`: replaced by a ^J at translation time.
  5. `%l`: replaced by a new line at reading time.
  6. `%n`: replaced by a number or `?` at translation time.
  7. `%r`: replaced by the modifiers reset (color, bold...) at reading time.
  8. `%s`: replaced by a string at translation time.
  9. `%y`: replaced by `yes` or `no` at translation time.
- Inside the `lang` folder is a file named `lgd.nanorc`. It is a file coloration only supported by nano.
  - To enable it in *nix, edit the file `~/.nanorc` (the file `.nanorc` in your home folder) and append `include [maze_loc]/lang/lgd.nanorc` where `[maze_loc]` is where you put this maze = where is this file.
  - It will write the state + name(s) in yellow, the `=` sign in red, and the translation in green.
  - It will tell you where are the valid (bold green)/invalid (bold red or red if at end of line) `%.`, but also if the `%c` is valid: there must be no `%cm`, `%c0m`, `%c00m`, any invalid 3+ digit numbers, anything else than numbers or `;`, a finishing `m` letter.
  - It will tell you wether and how many extra spaces before and after there is

## Creating levels
If you want to submit a level, please put the code in `add_contrib_nontest_levels` in [contribution.lua@line1]( contribution.lua#L1) for a real level or in `add_contrib_nontest_levels` in [contribution.lua@line13]( contribution.lua#L13) for a test level

If you want to create a level, here's what to do:
### Creating the actual level
A level is an instance of the Level class. To create a new instance, simply call `Level(args)`.
`args` are the arguments of the level constructor.

There is two ways of creating a level.

The old \(obsolete) way of doing it is to call `Level(init_room, col_cnt, room_datas)`.
This way will be removed later.

The new way is by using a big array and passing it to the constructor.

To create a level, you need ~~three~~ five informations:
- The level configuration. \(You might not want to create a game configuration and use the `currentConfig:getLevelConfig()` level configuration.) Goes into ID `level_conf` *\(optional)*.
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
