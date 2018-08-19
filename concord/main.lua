local Concord = require("concord").init()

local Position = Concord.component(function(e, x, y)
   e.x = x
   e.y = y
end)

local Velocity = Concord.component(function(e, vx, vy)
   e.vx = vx
   e.vy = vy
end)

local Sprite = Concord.component(function(e)
end)

local Physics = Concord.system({Position, Velocity})
function Physics:init()
   self.maxX = love.graphics.getWidth()
   self.maxY = love.graphics.getHeight()
end

function Physics:update(dt)
   for i = 1, self.pool.size do
      local e = self.pool:get(i)

      local position = e[Position]
      local velocity = e[Velocity]

      position.x = position.x + velocity.vx * dt
      position.y = position.y + velocity.vy * dt

      if position.x > self.maxX or position.y > self.maxY then
         if love.math.random() < 0.4 then
            e:destroy()
         else
            position.x = 0
            position.y = 0
         end
      end
   end
end

local SpriteRenderer = Concord.system({Position, Sprite})
function SpriteRenderer:init()
   self.sprite = love.graphics.newCanvas(16,16)
   love.graphics.setCanvas(sprite)
   love.graphics.setColor(1,1,1,1)
   love.graphics.circle("fill",8,8,6)
   love.graphics.setColor(0,0,0,1)
   love.graphics.circle("line",8,8,6)
   love.graphics.circle("line",10,8,1)
   love.graphics.setCanvas()
   love.graphics.setColor(1,1,1,1)
end

function SpriteRenderer:draw()
   for i = 1, self.pool.size do
      local e = self.pool:get(i)
   
      local position = e[Position]

      love.graphics.draw(self.sprite, position.x, position.y)
   end
end

local Game = Concord.instance()

local physics        = Physics()
local spriteRenderer = SpriteRenderer()

Game:addSystem(physics, "update")
Game:addSystem(spriteRenderer, "draw")

function love.update(dt)
   for i = 1, 100 do
      local e = Concord.entity()
      :give(Position, 0, 0)
      :give(Velocity, love.math.random(10, 30), love.math.random(10, 30))
      :give(Sprite)

      Game:addEntity(e)
   end

   Game:emit("update", dt)

   love.window.setTitle("FPS: " ..love.timer.getFPS().. " Entities: " ..Game.entities.size)
end

function love.draw()
   --Game:emit("draw")
end