# What is this?
This is the documentation of the lang dictionaries \(LGDs) inside the `lang` folder.

# Quick summary
1. [What does that folder contains?](#what-does-that-folder-contains)
2. [How can I contribute?](#how-can-i-contribute)
   1. [How can I upgrade a translation?](#how-can-i-upgrade-a-translation)
   2. [There is not my lang, how can I start?](#there-is-not-my-lang-how-can-i-start)
   3. [Adding the translations](#adding-the-translations)
   4. [Escaped characters](#escaped-characters)
   5. [What about the level lang dictionaries?](#what-about-the-level-lang-dictionaries)
3. [What about that nanorc file?](#what-about-that-nanorc-file)
   1. [How can I use it?](#how-can-i-use-it)
   2. [What will it do?](#what-will-it-do)

# What does that folder contains?
It contains some `.lgd` files \(for LanG Dictionary).
Each of these files contains translations to integrate a language.

The only exception is the `blank.lgd` file that is only an empty file translation, containing all registered translations: if you integrate it and use it, every text will be replaced by nothing.

It contains some `.lld` files \(for Level Lang Dictionary).
Each of there files contains lores for a specific level.

It also contains a `lgd.nanorc` and `lld.nanorc` file, which is used with Nano \(see [What about that nanorc file?](#what-about-that-nanorc-file)).

# How can I contribute?
You can contribute by adding or upgrading an other langage's integration.

## How can I upgrade a translation?
You can upgrade a translation by adding not-yet-supported strings, then creating a pull request so I can see it.

To see how to add translations, see [Adding the translations](#adding-the-translations).

## There is not my lang, how can I start?
### Thinking about the lang name, UID and fallback
Each lang has a lang name \(*soon* displayed in the options menu), a lang UID \(a Unique IDentity, used internally only) and an optional lang fallback.

A lang UID \(internally lang ID) is a unique way to refer to this lang.
It is recommanded to follow the following: `ll_CC`, where `ll` is the two-lowercase-letters "general" lang ID (like `en` for american/british english) and `CC` is the two-uppercase-letters language's country (like `US` for american english or `GB` for Great Britain's english).

A lang fallback is used when the lang doesn't have a translation.
For instance, if the lang `a` has `ig.map.sword` and the lang `b` has `a` as fallback, but doesn't have a translation for `ig.map.sword`, it will use `a`'s one.

By default, the fallback is the american english `en_US` lang. If you don't want any fallback, the fallback will be `false` without any `"` (like for the american english lang).
Beware, if you remove the fallback, any unknown translaton will be replaced by the translation string (with dots and all, like `ig.map.sword` or `options.difficulty.value:3`).

### Creating the file and integrating it in the program
From now on, the lang name, ID and fallback are replaced respectively by `[name]`, `[ID]` and `[fallback]` in the code parts.

Inside this `lang/` folder, you must create a file named `[ID].lgd`.
#### Creating the file
##### The easy/new way
Simply copy and paste the `blank.lgd` file, then rename it.

##### The hard/old way
You may create this file by using the Notepad (Windows), Nano (command-line \*nix), Mousepad (\*nix), Notepad++ (Windows and MacOS?) or any other **RAW TEXT** file editor. (That means, OpenOffice won't work.)
Then save a new/empty file **and remove EVERYTHING from the save name, including the `.txt`** to replace it with the file name.

**Beware: if the file name finishes by `.txt`, you created it wrong**. It won't work.

**Beware: if it is written anywhere that this file is a text file, you very likely created it wrong**. It probably won't work \(though since the file *is* a text file it may be OK).

It is possible that you created it wrong even if it display `.lgd` at the end of the name: you simply hid the file extensions.

*If you created it wrong, delete it and start again. It won't work.*

#### Register it
Next, [inside the dictionary.lua file, at line 440](dictionary.lua#L440), there is a line that start with `langs = {`.
(If that is not the case, search the file to find this line.)

Once you see that line, it is time to add the lang.
Before the finishing closing brackets, you must add `, {id = "[ID]", name = "[name]", fallback = "[fallback]"}`.

(Soon) ~If you don't see you lang in the languages list, there is something wrong.~ Be sure not to put this text after the finishing closing curly brackets (the line must end by `}}`).

*For now, as there is no language selection list, to enable you language, six lines below, there is something like `self.__active_id = langs[1].id`. Replace this by `self.__active_id = "[ID]"`.*
**This must be undo before creating any pull request**

If all this is done, good job! You successfully added your language to the list of registered langs!

#### Testing
To test if you successfully done everything until here, add `ig.prompt = Tested: working! ` to the file you created.
Then launch the game. If nothing changed, recreate the `.lgd` file.
## Adding the translations
### What is a translation?
In my `.lgd` files, a translation is a "states-key to string" correspondance.

A states-key is a string.
States are keywords separated by `.`.
A key is a keyword, optionally followed by `:` and a keyword.
Keywords are anything that doesn't contains any of `.:= ` and tab space. It is generally lowercase and spaces are replaced by `_`.

When the game tries to translate a string (for instance `ig.sword.sword`), it first try to get the translation for these states and the key, but if it can't find that translation, it removes the last state (for instance the first `sword.`) and try again (with `ig.sword` then `sword` with the example).

### What are alternatives?
When the key contains a `:`, it defines an alternative and not a string anymore.

Alternatives may be used when you ~want to write less code~ have different states and the states make the translation differs.

The alternative keyword is what precedes the `:` (and follow the final `.` ), and the alternative name is what follows the `:` (and precedes the `=` part).
By default, the active alternative is the first alternative defined.

### What about the lines starting with #?
These are comments and are ignored by the langs.

### Creating the translation
The translation string is the states (separated with `.`), followed by the key/alternative group.
Then you have the ` = ` part that separate the key from the translation.
Then you have the translation.

All this **must** be in one line.
#### I want to have a multi-line translation, how do I do?
There are multiple escaped characters. The one you are looking for is the `%l`.

## Escaped characters
If it is translated "at reading time", it is replaced by the corresponding value when reading the file.
If it is translated "at translation time", it is replaced by the corresponding value when translating (generally using the arguments passed when asking for translate).
When upper-case is supported, the first letter is changed to an upper-case letter. To have it, just change the letter after the `%` to an upper-case letter.

1. `%% `: translation time. Note the finishing space. It is replaced by `%`.
2. `%b`: translation time, upper-case supported. Replaced by `on` or `off`.
3. `%c[]m`: reading time. Replaced by the color replacing `[]` using the escape codes (`ESC[`...`m`, see ASCII escape codes). **There is no check for whether this is valid, be careful with this otherwise it will display weird things.**
4. `%I[] `: translation time, no argument. The final ` ` may be replaced by a tab. It is replaced by the translation of what replaces `[]` *in the active lang, not the current one if translating using a fallback*.
5. `%j`: reading time. Replaced by a `^J` (moves one character back, but does not removes it).
6. `%l`: reading time. Replaced by a new line.
7. `%n`: translation time. Replaced by a number or `?`.
8. `%r`: reading time. Replaced by the color/bold/... reset (same as `%cm`, but better for syntax coloration).
9. `%s`: translation time. Replaced by a string.
10. `%y`: translation time, upper-case supported. Replaced by `yes` or `no`.

## What about the level lang dictionaries?
The difference between `lld` and `lgd` files is that in the `lld` files, the translation "state" starts with the lang ID.

Also, there are some state that are automatically added:
- Before all other states: ig.levels
- Before the translation key: the level name

These are designed to be used only for levels.

Meaning the line:
```
en_US.lores.end.death:default = You DIE. Maybe next time you'll survive?%l
```
in `starter.lld` will be equivalent to adding for the `en_US` language:
```
ig.levels.lores.end.starter.death:default = You DIE. Maybe next time you'll survive?%l
```

# What about that nanorc file?
This file is a syntaxic coloration only supported by Nano.

## What is Nano?
It is a terminal-based text editor, available on \*nix.

## How can I use it?
To enable it, first locate it. It will be replaced by `[pwd]` below.
- In \*nix, in a terminal, go into where it is located and type `pwd`\<Enter\>. The answer is the location.
- In \*nix, in a file navigator, right-click and click on `Open a terminal here` then type `pwd`\<Enter\>. The answer is the location.

Then, in the terminal, type `nano ~/.nanorc`\<Enter\> and append
```
include [pwd]/lgd.nanorc
include [pwd]/lld.nanorc
```
. Then exit Nano.

## What will it do?
- It will write in bright red everything that is wrong.
- It will write states and key/alternatives in yellow, the equals sign in red and the rest in green.
- It will write every states and key/alternatives registered in bright yellow.
- It will fill extra spaces before and after the translation \(that are actually in the translated text) in green.
- It will tell you where are the valid \(bold green)/invalid \(bold red or red if at end of line) `%.`, but also if the `%c` is valid: there must be no `%cm`, `%c0m`, `%c00m`, any invalid 3+ digit numbers, anything else than numbers or `;`, a finishing `m` letter. Eventually it will color in magenta the text between the `%c` and the `%r`.
- It will tell you if the `%I` are in a valid state and tell you that the space after is deleted. The insertion text \(after the `%I`) is bolded if it is recognized.
