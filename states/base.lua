local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = import_prefix:match("(.-)states%.[^%.]+$") end
if not import_prefix then import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

local classmodule = require(import_prefix .. "class")

BaseState = abst_class(function(self) end)
function BaseState:onPush() end
function BaseState:onPoppedUpper(stateName, state) end
function BaseState:onPop() end
BaseState:__addAbstract("runIteration")
