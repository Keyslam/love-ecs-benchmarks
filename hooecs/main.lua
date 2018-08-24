local HooECS = require("hooECS")
HooECS.initialize({
   globals = true,
})

local entityLimit = 50000

local Position = Component.create("Position", {"x", "y"}, {x = 0, y = 0})
local Velocity = Component.create("Velocity", {"x", "y"}, {x = 0, y = 0})
local Sprite   = Component.create("Position", {"isSprite"}, {isSprite = true})

local Game = Engine()
local eCount = 0

local Physics = class("Physics", System)

function Physics:initialize()
   System.initialize(self)
   self.maxX = love.graphics.getWidth()
   self.maxY = love.graphics.getHeight()
end

function Physics:update(dt)
   for _, e in pairs(self.targets) do
      local position = e:get("Position")
      local velocity = e:get("Velocity")

      position.x = position.x + velocity.x * dt
      position.y = position.y + velocity.y * dt

      if position.x > self.maxX or position.y > self.maxY then
         if love.math.random() < 0.4  then
            Game:removeEntity(e)
            eCount = eCount - 1
         else
            position.x = 0
            position.y = 0
         end
      end
   end
end

function Physics:requires()
   return {"Position", "Velocity"}
end

local SpriteRenderer = class("SpriteRenderer")

function SpriteRenderer:update(dt)
   for _, e in pairs(self.targets) do
      local position = e:get("Position")

      -- love.graphics.draw(something something)
   end
end

function SpriteRenderer:requires()
   return {"Position", "Sprite"}
end

Game:addSystem(Physics())

function love.update(dt)
   for _ = 1, 100 do
      if entityLimit and eCount >= entityLimit then
         break
      end

      local e = Entity()
      e:add(Position())
      e:add(Velocity(love.math.random(10, 30), love.math.random(10, 30)))
      e:add(Sprite())

      Game:addEntity(e)

      eCount = eCount + 1
   end

   Game:update(dt)

   love.window.setTitle(" Entities: " .. eCount
      .. " | FPS: " .. love.timer.getFPS()
      .. " | Memory: " .. math.floor(collectgarbage 'count') .. 'kb'
      .. " | Delta: " .. love.timer.getDelta())
end

function love.draw()
   Game:draw()
end
