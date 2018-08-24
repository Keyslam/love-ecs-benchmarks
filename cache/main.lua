local Ffi = require("ffi")
local Lds = require("lds")
local Bit = require("bit")

local EntityCount = 50000

local nextMask = 1
local function newComponent(struct)
   local type     = Ffi.typeof("struct {"..struct.."}")
   local entities = Lds.Array(type, EntityCount)
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
   local entities = Ffi.new("int[?]", EntityCount)
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

for i = 1, EntityCount do
   local myEntity = newEntity()
   giveComponent(myEntity, Position, 0, 0)
   giveComponent(myEntity, Velocity, love.math.random(10, 30), love.math.random(10, 30))
   giveComponent(myEntity, Sprite, true)

   filter(myEntity)
end

local sprite = love.graphics.newCanvas(16, 16)
love.graphics.setCanvas(sprite)
love.graphics.setColor(1,1,1,1)
love.graphics.circle("fill",8,8,6)
love.graphics.setColor(0,0,0,1)
love.graphics.circle("line",8,8,6)
love.graphics.circle("line",10,8,1)
love.graphics.setCanvas()
love.graphics.setColor(1,1,1,1)

local maxX, maxY = love.graphics.getWidth(), love.graphics.getHeight()
function love.update(dt)
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

   love.window.setTitle(" Entities: " .. nextID
.. " | FPS: " .. love.timer.getFPS()
.. " | Memory: " .. math.floor(collectgarbage 'count') .. 'kb'
.. " | Delta: " .. love.timer.getDelta())
end

function love.draw()
   for i = 1, SpriteRenderer.items do
      local id = SpriteRenderer.entities[i - 1]
      local position = Position.entities:get(id)

      --love.graphics.draw(sprite, position.x, position.y)
   end
end
