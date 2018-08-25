local nata = {
	_VERSION = 'Nata',
	_DESCRIPTION = 'Entity management for Lua.',
	_URL = 'https://github.com/tesselode/nata',
	_LICENSE = [[
		MIT License

		Copyright (c) 2018 Andrew Minnich

		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:

		The above copyright notice and this permission notice shall be included in all
		copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		SOFTWARE.
	]]
}

local function find(t, item)
	for i, v in ipairs(t) do
		if v == item then return i end
	end
	return false
end

local function doesEntityHaveComponents(entity, components)
	for _, component in ipairs(components) do
		if not entity[component] then return false end
	end
	return true
end

local function shouldSystemProcess(system, entity)
	if not system.filter then return true
	elseif type(system.filter) == 'table' then
		return doesEntityHaveComponents(entity, system.filter)
	elseif type(system.filter) == 'function' then
		return system.filter(entity)
	else
		error 'system filter must be either a table or a function'
	end
end

local Pool = {}
Pool.__index = Pool

function Pool:callOn(entity, event, ...)
	for _, system in ipairs(self.systems) do
		if system[event] and self._cache[system][entity] then
			system[event](entity, ...)
		end
	end
end

function Pool:call(event, ...)
	for _, system in ipairs(self.systems) do
		if system[event] then
			system[event](self._cache[system], ...)
		end
	end
end

function Pool:queue(entity, ...)
	table.insert(self._queue, {entity, {...}})
	return entity
end

function Pool:flush()
	for i, v in ipairs(self._queue) do
		local entity, args = v[1], v[2]
		table.insert(self._entities, entity)
		for _, system in ipairs(self.systems) do
			if shouldSystemProcess(system, entity) then
				self._cache[system] = self._cache[system] or {}
				table.insert(self._cache[system], entity)
				self._cache[system][entity] = true
				if system.sort then
					table.sort(self._cache[system], system.sort)
				end
				if system.add then system.add(entity, args) end
			end
		end
		self._queue[i] = nil
	end
end

function Pool:remove(f, ...)
	for i = #self._entities, 1, -1 do
		local entity = self._entities[i]
		if f(entity) then
			for _, system in ipairs(self.systems) do
				if self._cache[system] and self._cache[system][entity] then
					if system.remove then system.remove(entity, ...) end
					table.remove(self._cache[system], find(self._cache[system], entity))
					self._cache[system][entity] = nil
					break
				end
			end
			table.remove(self._entities, i)
		end
	end
end

function Pool:get(f)
	local entities = {}
	for _, entity in ipairs(self._entities) do
		if not f or f(entity) then
			table.insert(entities, entity)
		end
	end
	return entities
end

function Pool:getSize()
	return #self._entities
end

--[[
Returns a system that, whenever an index is accessed (except for reserved
names), will return a function that calls the function of the same name on
the entity (if the entity has a function with that name). These functions
are cached to avoid creating functions every frame.

For example, system.myWeirdlyNamedEvent will be this function:
	function(entity, ...)
		if type(entity.myWeirdlyNamedEvent) == 'function' then
			entity:myWeirdlyNamedEvent(...)
		end
	end
]]
function nata.oop()
	return setmetatable({_f = {}}, {
		__index = function(t, k)
			if k == '_f' or k == 'filter' or k == 'sort' then
				return rawget(t, k)
			else
				t._f[k] = t._f[k] or function(e, ...)
					if type(e[k]) == 'function' then
						e[k](e, ...)
					end
				end
				return t._f[k]
			end
		end
	})
end

function nata.new(systems)
	return setmetatable({
		systems = systems or {nata.oop()},
		_entities = {},
		_cache = {},
		_queue = {},
	}, {__index = Pool})
end

return nata
