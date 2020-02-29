local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = import_prefix:match("(.-)states%.[^%.]+$") end
if not import_prefix then import_prefix = "" end

local errormodule = require(import_prefix .. "error")

local utilmodule = load_module(import_prefix .. "util", true)

local classmodule = load_module(import_prefix .. "class", true)

BaseState = abst_class(function(self) end)
function BaseState:onPush() end
function BaseState:onPoppedUpper(stateName, state) end
function BaseState:onPop() end
BaseState:__addAbstract("runIteration")
