# What is this?
This is the documentation for classes, which constructor function is in [class.lua@line3](/class.lua#L3).

# Quick summary
1. [What's a class?](#whats-a-class)
2. [Creating a class](#creating-a-class)
   1. [Creating a new class](#creating-a-new-class)
   2. [Creating a subclass](#creating-a-subclass)
3. [What's an instance?](#whats-an-instance)
   1. [Creating an instance](#instanciate-a-class)

# What's a class?
A class is a special table that contains functions, and can be instanciate.

It also contains functions like `isinstance`, that are in all classes and can be used to get informations about the class. For instance, the `isinstance` function of a class is used to say whether the instance passed in parameter has the class as one of its superclasses \(see [What's a subclass?](#whats-a-subclass)).

## What's a subclass?
A subclass is a class that contains all function of a superclass, but it generally has modifications \(or not, it can be used as a marker, see [the events](/events.lua#L14)).

# Creating a class
To create a class, you need to know if you want to [create a new class](#creating-a-new-class) or [create a subclass](#creating-a-subclass)

## Creating a new class
To create a class, first you need a class name. It will be written as `[name]` below.

Then you need a constructor. It is a function that is called at the [instanciation](#whats-an-instance) of the class. Its arguments are `self`, then the arguments you want \(it can be none as it can be `a, b, c, d, e, f, g, h, i`). These will be written as `[args]`. Its body will be written as `(cstr)`.

To create the class, you need to write, near the beginning \(if you want to make a push request):
```lua
local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end
```
```lua
local classmodule = require(import_prefix .. "class")
```
If you don't want to do a push request, you need at least this \(in my git repository):
```lua
require("class")
```

Then to create the class, write this after:
```lua
[name] = class(function(self, [args])
	(cstr)
end)
```

Then, to add functions to this class, write \(where `(fcnname)` is the function name, `[args]` its arguments, `[body]` its arguments):
```lua
function [name]:(fcnname)([args])
	[body]
end
```
To access class members, use the `self` keyword.

## Creating a subclass
To create a subclass, first you need a subclass name and a superclass name. These will be written respectively as `[name]` and `[super]` below.

If you want to call the constructor of the superclass, you need to call `self._super.__init(self, [args])`. The superclass functions are stored in `self._super`.

Then you need a constructor. It is a function that is called at the [instanciation](#whats-an-instance) of the class. Its arguments are `self`, then the arguments you want \(it can be none as it can be `a, b, c, d, e, f, g, h, i`). These will be written as `[args]`. Its body will be written as `(cstr)`.

To create the class, you need to write, near the beginning \(if you want to make a push request):
```lua
local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end
```
```lua
local classmodule = require(import_prefix .. "class")
```
If you don't want to do a push request, you need at least this \(in my git repository):
```lua
require("class")
```

Then to create the class, write this after:
```lua
[name] = class(function(self, [args])
	(cstr)
end)
```

Then, to add functions to this class, write this after the class definition \(where `(fcnname)` is the function name, `[args]` its arguments, `[body]` its body):
```lua
function [name]:(fcnname)([args])
	[body]
end
```
To access class members, use the `self` keyword.

# What's an instance?
An instance \(of a class) is an object \(a table) that contains a class' functions and members.

## Instanciate a class
To instanciate the class named `(name)` and store the new instance in `[varn]`, with `[args]` as the arguments of the constructor, you need to write:
```lua
[varn] = (name)([args])
```
