--[[
lds - LuaJIT Data Structures

@copyright Copyright (c) 2012-2014 Evan Wies.  All rights reserved.
@license MIT License, see the COPYRIGHT file.

Common module require for convenience.

Individual data structures may be require'd instead, for example:
local lds = require 'cache.lds.Vector'
--]]

local lds = require 'cache.lds.Array'
require 'cache.lds.Vector'
require 'cache.lds.HashMap'

return lds
