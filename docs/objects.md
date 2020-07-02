# What is this

This is the documentation for the objects.

It is held in [objects.lua](../objects.lua)

## Quick summary

1. [What is an object?](#what-is-an-object)
   1. [What is an Objects instance?](#what-is-an-objects-instance)
      1. [What is an object group?](#what-is-an-object-group)
   2. [What is an object held by an Objects instance?](#what-is-an-object-held-by-an-objects-instance)
2. [How to add objects?](#how-to-add-objects)
   1. [Add an object group](#add-an-object-group)
   2. [Add an object to a group](#add-an-object-to-a-group)
   3. [Add an object type](#add-an-object-type)

## What is an object

Object can here refer to:

- a class instance,
- more precisely, an `Objects` instance,
- an object held by an Object instance.

The first possibility is mostly unused \(in this project) as it is called "instance" and not "object".

### What is an Objects instance

An `Objects` instance is an instance that holds multiple objects. For instance, the player can hold a key, a red key and a sword. These are all reunited in a single `Objects` instance.

#### What is an object group

An object group is a predefined `Objects`' objects definitions \(not instance!).

The object group may be:

- `1`: the player's objects.
  - a `key`: held \(multiple alternatives autoset).
  - a `redkey`: held \(multiple alternatives autoset).
  - a `sword`: held \(multiple alternatives autoset).

### What is an object held by an Objects instance

An object here is a thing with a type that can be:

- any Lua type in:
  - string \(a string)
  - number \(a number)
  - boolean \(`true` or `false`)
  - nil \(always `nil`)
- held; this is a special type that points to a physical object \(a key for instance); allows to dynamically change [alternatives](lang.md#what-are-alternatives). Outputs a number or `false`.
- anything else \(can be anything)

## How to add objects

It depends on whether you want add an object group or an object type.

### Add an object group

To add an object group, you need to find a name/number: the group's ID (later replaced by `[ID]`).

To find it, you need to edit the file [objects.lua@line137](../objects.lua#L137).

Here there should be around something like:

```lua
if objKind == 0 then -- Empty object
elseif objKind == 1 then
    _fallback = {...}

    setname = "standard"
elseif type(objKind) == "string" then -- Line 137
```

Before the `elseif`, you must insert:

```lua
elseif objKind == [ID] then
```

then add the objects to the group.

Optional *(but recommended)*: after this, add those lines too:

```lua
_fallback = {}
setname = [SETNAME]
```

where `[SETNAME]` is the object set name. This will allow to use the files instead of having hard-coded data.

### Add an object to a group

There are two ways to do this, using the custom file format or by hard-coding the data.

To add an object to a group using the file format, you need to get the name of the object group

#### Add an object to an object group file

First, get the correct file. It is either `objects/[SETNAME].objhld` or `objects/[SETNAME].objhld.ext` (depending on whether you want to add it to the main set or as an extension resp.) where `[SETNAME]` is the object group name.

Then, this is the structure of any object in a group:

```text
[name]: object
  type: string: [type]
  default: [deftype]: [def]
  alts: array:
    array:
      array:
        string: [stateparts]
        string: [statename]
      [funtype]
```

where `[name]` is the object's name, `[type]` its type, `[deftype]` its default value type and `[def]` its default value.

Note that the `alts` array is optional and is used to dynamically change [alternatives](lang.md#what-are-alternatives), and contains a list of arrays containing one array of strings representing the [states-key](lang.md#what-is-a-translation) (each string is a state and the last one is the key).

The `[funtype]` is the function type to get the [alternative name](lang.md#what-are-alternatives). It takes in whether there is at least one object and optional user-defined (at the calling site) extra arguments.

The two available function types are:

```text
typeconv: [type]
```

a simple function that converts its first input to `[type]` (available types are `string` and `number`)

```text
switchfunction:
  array:
    boolean: [par1]
    number-to-tristate: [par2], [step1], [step2]
  array:
    [rettype1]: [ret1]
    [rettype2]: [ret2]
    [rettype3]: [ret3]
    [rettype4]: [ret4]
    [rettype5]: [ret5]
    [rettype6]: [ret6]
```

a more complex function that switch between the return values depending on the boolean/trilean(?) values of the parameters.

It starts from the first parameter to the last, depth-first, and depending on the parameter type:

- a boolean is first compared to false, then to true
- a `number-to-tristate` is first compared (less or equal) to `[step1]` then (less or equal) to `[step2]` then if it is greater than both.

To see a better explanation, look at [the standard object group](../objects/standard.objhld).

#### Add a hard-coded object to a group

First, find the corresponding `elseif` line.

Then, inside the _fallback array add this array, where the object's name is `[name]`, its starting value is `[starting_val]` and its type is `[type]`:

```lua
{[name], [starting_val], [type]}
```

If you want to be able to dynamically change [alternatives](lang.md#what-are-alternatives), the type must be `"held"`, then append, before the `}`, a comma then an array of quadruple (each quadruple in a separate array):

- the first thing is a string containing what kind of additional info this is (in this case it is always `"altset"`, for ALTernative SET)
- the second is the [state table](lang.md#what-is-a-translation)
- the third is the [key name](lang.md#what-is-a-translation)
- the fourth and final is a function that takes in whether there is at least one object and optional user-defined (at the calling site) extra arguments, and output the [alternative name](lang.md#what-are-alternatives)

### Add an object type

You must look the [`get`/`setObject`](../objects.lua#L12) functions.

In these functions, there is a switch using the object type.
To add a new type, simply add an other case to this switch.

_Please, also add the documentation for that new type if you want to make a [push request](CONTRIBUTING.md#submit-a-contribution)._
