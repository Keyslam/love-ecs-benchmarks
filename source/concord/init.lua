local Concord = require("concord.concord").init()

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
end

function SpriteRenderer:draw()
   for i = 1, self.pool.size do
      local e = self.pool:get(i)
      local position = e[Position]
      if enableDrawing then
        love.graphics.draw(testSprite, position.x, position.y)
      end
   end
end

local Game = Concord.instance()

local physics        = Physics()
local spriteRenderer = SpriteRenderer()

Game:addSystem(physics, "update")
Game:addSystem(spriteRenderer, "draw")

return {
  update = function(dt)
    for _ = 1, 100 do
      if entityLimit and Game.entities.size >= entityLimit then
        break
      end
      local e = Concord.entity()
      :give(Position, 0, 0)
      :give(Velocity, love.math.random(10, 30), love.math.random(10, 30))
      :give(Sprite)
      Game:addEntity(e)
   end

   Game:emit("update", dt)
  end,

  draw = function()
    Game:emit("draw")
  end,

  getNumEntities = function() return Game.entities.size end,
}
