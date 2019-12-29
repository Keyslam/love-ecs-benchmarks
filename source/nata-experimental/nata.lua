local nata = {
	_VERSION = 'Nata',
	_DESCRIPTION = 'Entity management for Lua.',
	_URL = 'https://github.com/tesselode/nata',
	_LICENSE = [[
		MIT License

		Copyright (c) 2019 Andrew Minnich

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

local Collection = {}
Collection.__index = Collection

function Collection:add(item)
	local index
	if #self._holes > 0 then
		index = self._holes[#self._holes]
		self._holes[#self._holes] = nil
	else
		index = self._highestIndex + 1
		self._highestIndex = self._highestIndex + 1
	end
	self._items[index] = item
	self._itemIndices[item] = index
end

function Collection:remove(item)
	local index = self._itemIndices[item]
	self._items[index] = nil
	self._itemIndices[item] = nil
	if index == self._highestIndex then
		self._highestIndex = self._highestIndex - 1
	else
		self._holes[#self._holes + 1] = index
	end
end

local function collectionIterator(collection, i)
	repeat
		i = i + 1
		if i > collection._highestIndex then return end
	until collection._items[i]
	return i, collection._items[i]
end

function Collection:items()
	return collectionIterator, self, 0
end

function Collection:has(item)
	return self._itemIndices[item] and true or false
end

function Collection:count()
	return self._highestIndex - #self._holes
end

local function newCollection()
	return setmetatable({
		_items = {},
		_itemIndices = {},
		_holes = {},
		_highestIndex = 0,
	}, Collection)
end

local function removeByValue(t, v)
	for i, item in ipairs(t) do
		if item == v then
			table.remove(t, i)
			break
		end
	end
end

local function entityHasKeys(entity, keys)
	for _, key in ipairs(keys) do
		if not entity[key] then return false end
	end
	return true
end

local function filterEntity(entity, filter)
	if type(filter) == 'table' then
		return entityHasKeys(entity, filter)
	elseif type(filter) == 'function' then
		return filter(entity)
	end
	return true
end

local World = {}
World.__index = World

function World:_init(options, ...)
	options = options or {}
	self._queue = {}
	self.entities = newCollection()
	self.groups = {}
	self._systems = {}
	self._events = {}
	self.data = options.data or {}
	local groups = options.groups or {}
	local systems = options.systems or {nata.oop()}
	for groupName, groupOptions in pairs(groups) do
		self.groups[groupName] = {
			filter = groupOptions.filter,
			sort = groupOptions.sort,
			entities = newCollection(),
			hasEntity = {},
		}
	end
	for _, systemDefinition in ipairs(systems) do
		local system = setmetatable({
			world = self,
		}, {__index = systemDefinition})
		table.insert(self._systems, system)
	end
	self:emit('init', ...)
end

function World:_addToGroup(groupName, entity)
	local group = self.groups[groupName]
	group.entities:add(entity)
	self:emit('addToGroup', groupName, entity)
end

function World:_removeFromGroup(groupName, entity)
	local group = self.groups[groupName]
	group.entities:remove(entity)
	self:emit('removeFromGroup', groupName, entity)
end

function World:queue(entity)
	table.insert(self._queue, entity)
	return entity
end

function World:flush()
	for i = 1, #self._queue do
		local entity = self._queue[i]
		-- check if the entity belongs in each group and
		-- add it to/remove it from the group as needed
		for groupName, group in pairs(self.groups) do
			if filterEntity(entity, group.filter) then
				if not group.entities:has(entity) then
					self:_addToGroup(groupName, entity)
				end
				if group.sort then group._needsResort = true end
			elseif group.entities:has(entity) then
				self:_removeFromGroup(groupName, entity)
			end
		end
		-- add the entity to the world if it hasn't been added already
		if not self.entities:has(entity) then
			self.entities:add(entity)
			self:emit('add', entity)
		end
		self._queue[i] = nil
	end
	-- re-sort groups
	for _, group in pairs(self.groups) do
		if group._needsResort then
			--table.sort(group.entities, group.sort)
			group._needsResort = nil
		end
	end
end

function World:remove(f)
	for _, entity in self.entities:items() do
		if f(entity) then
			self:emit('remove', entity)
			for groupName, group in pairs(self.groups) do
				if group.entities:has(entity) then
					self:_removeFromGroup(groupName, entity)
				end
			end
			self.entities:remove(entity)
		end
	end
end

function World:on(event, f)
	self._events[event] = self._events[event] or {}
	table.insert(self._events[event], f)
	return f
end

function World:off(event, f)
	if self._events[event] then
		removeByValue(self._events[event], f)
	end
end

function World:emit(event, ...)
	for _, system in ipairs(self._systems) do
		if type(system[event]) == 'function' then
			system[event](system, ...)
		end
	end
	if self._events[event] then
		for _, f in ipairs(self._events[event]) do
			f(...)
		end
	end
end

function World:getSystem(systemDefinition)
	for _, system in ipairs(self._systems) do
		if getmetatable(system).__index == systemDefinition then
			return system
		end
	end
end

function nata.oop(options)
	local group = options and options.group
	local include, exclude
	if options and options.include then
		include = {}
		for _, event in ipairs(options.include) do
			include[event] = true
		end
	end
	if options and options.exclude then
		exclude = {}
		for _, event in ipairs(options.exclude) do
			exclude[event] = true
		end
	end
	return setmetatable({_cache = {}}, {
		__index = function(t, event)
			t._cache[event] = t._cache[event] or function(self, ...)
				local shouldCallEvent = true
				if include and not include[event] then shouldCallEvent = false end
				if exclude and exclude[event] then shouldCallEvent = false end
				if shouldCallEvent then
					local entities
					-- not using ternary here because if the group doesn't exist,
					-- i'd rather it cause an error than just silently falling back
					-- to the main entity world
					if group then
						entities = self.world.groups[group].entities
					else
						entities = self.world.entities
					end
					for _, entity in entities:items() do
						if type(entity[event]) == 'function' then
							entity[event](entity, ...)
						end
					end
				end
			end
			return t._cache[event]
		end
	})
end

function nata.new(...)
	local world = setmetatable({}, World)
	world:_init(...)
	return world
end

return nata
