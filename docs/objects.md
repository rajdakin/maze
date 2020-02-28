# What is this?
This is the documentation for the objects.

It is held in [objects.lua](/objects.lua)

# Quick summary
1. [What is an object?](#what-is-an-object)
   1. [What is an Objects instance?](#what-is-an-objects-instance)
      1. [What is an object group?](#what-is-an-object-group)
   2. [What is an object held by an Objects instance?](#what-is-an-object-held-by-an-objects-instance)
2. [How to add objects?](#how-to-add-objects)
   1. [Add an object group](#add-an-object-group)
   2. [Add an object to a group](#add-an-object-to-a-group)
   3. [Add an object type](#add-an-object-type)

# What is an object?
Object can here refer to:
- a class instance,
- more precisely, an `Objects` instance,
- an object held by an Object instance.

The first possibility is mostly unused \(in this project) as it is called "instance" and not "object".

## What is an Objects instance?
An `Objects` instance is an instance that holds multiple objects. For instance, the player can hold a key, a red key and a sword. These are all reunited in a single `Objects` instance.

### What is an object group?
An object group is a predefined `Objects`' objects definitions \(not instance!).

The object group may be:
- `1`: the player's objects.
  - a `key`: held \(multiple alternatives autoset).
  - a `redkey`: held \(multiple alternatives autoset).
  - a `sword`: held \(multiple alternatives autoset).

## What is an object held by an Objects instance?
An object here is a thing with a type that can be:
- any Lua type in:
  - string \(a string)
  - number \(a number)
  - boolean \(`true` or `false`)
  - nil \(always `nil`)
- held; this is a special type that points to a physical object \(a key for instance); allows to dynamically change [alternatives](lang.md#what-are-alternatives). Outputs a number or `false`.
- anything else \(can be anything)

# How to add objects?
It depends on whether you want add an object group or an object type.

## Add an object group
To add an object group, you need to find a name/number: the group's ID (later replaced by `[ID]`).

To find it, you need to edit the file [objects.lua@line128](/objects.lua#L128).

Here there should be around something like:
```lua
if objKind == 0 then -- Empty object
elseif objKind == 1 then
	self:addObject(...)
	...
end -- Line 128
```
Before the `end`, you must insert:
```lua
elseif objKind == [ID] then
```
then add the objects to the group.

## Add an object to a group
First, find the corresponding `elseif` line.

Then, append this line after, where the object's name is `[name]`, its starting value is `[starting_val]` and its type is `[type]`:
```lua
self:addObject([name], [starting_val], [type])
```
If you want to be able to dynamically change [alternatives](lang.md#what-are-alternatives), the type must be `"held"`, then append, before the `)`, a comma then a list of triples:
- the first thing is the [state table](lang.md#what-is-a-translation)
- the second is the [key name](lang.md#what-is-a-translation)
- the third is a function that takes in whether there is at least one object an optional extra arguments, and output the [alternative name](lang.md#what-is-a-translation)

## Add an object type
You must look the [`get`/`setObject`](objects.lua#L12).

In these functions, there is a switch using the object type.
To add a new type, simply add an other case to this switch.
_Please, also add the documentation for that new type if you want to make a [push request](CONTRIBUTING.md#submit-a-contribution)._
