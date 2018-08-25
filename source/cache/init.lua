local Ffi = require("ffi")
local Lds = require("cache.lds")
local Bit = require("bit")

local nextMask = 1
local function newComponent(struct)
   local type     = Ffi.typeof("struct {"..struct.."}")
   local entities = Lds.Array(type, entityLimit)
   local mask     = nextMask

   nextMask = nextMask * 2

   return {
      type     = type,
      entities = entities,
      mask     = mask,
   }
end

local systems = {}
local function newSystem(filter)
   local mask     = 0
   local entities = Ffi.new("int[?]", entityLimit)
   local items    = 0

   for _, component in ipairs(filter) do
      mask = mask + component.mask
   end

   local system = {
      mask     = mask,
      entities = entities,
      items    = items,
   }

   systems[#systems + 1] = system

   return system
end

local nextID = 0
local function newEntity()
   local id   = nextID
   local mask = 0

   nextID = nextID + 1

   return {
      id   = id,
      mask = mask,
   }
end

local function giveComponent(e, component, ...)
   component.entities:set(e.id, component.type(...))
   e.mask = e.mask + component.mask
end

local function filter(e)
   for _, system in ipairs(systems) do
      if bit.band(e.mask, system.mask) == system.mask then
         system.entities[system.items] = e.id
         system.items = system.items + 1
      end
   end
end

local Position = newComponent([[
   float x, y;
]])

local Velocity = newComponent([[
   float x, y;
]])

local Sprite = newComponent([[
   bool hasSprite;
]])

local Physics        = newSystem({Position, Velocity})
local SpriteRenderer = newSystem({Position, Sprite})

for _ = 1, entityLimit do
   local myEntity = newEntity()
   giveComponent(myEntity, Position, 0, 0)
   giveComponent(myEntity, Velocity, love.math.random(10, 30), love.math.random(10, 30))
   giveComponent(myEntity, Sprite, true)

   filter(myEntity)
end

local maxX, maxY = love.graphics.getWidth(), love.graphics.getHeight()

return {
    update = function(dt)
        for i = 1, Physics.items do
            local id = Physics.entities[i - 1]

            local position = Position.entities:get(id)
            local velocity = Velocity.entities:get(id)

            position.x = position.x + velocity.y * dt
            position.y = position.y + velocity.x * dt

            if position.x > maxX or position.y > maxY then
               position.x = 0
               position.y = 0
            end
        end
    end,

    draw = function()
        for i = 1, SpriteRenderer.items do
            local id = SpriteRenderer.entities[i - 1]
            local position = Position.entities:get(id)
            if enableDrawing then
                love.graphics.draw(testSprite, position.x, position.y)
            end
         end
    end,

    getNumEntities = function() return nextID end,
}
