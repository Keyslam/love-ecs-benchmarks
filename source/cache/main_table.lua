local entities = {}

local EntityCount = 1000000

for i = 1, EntityCount do
   entities[i] = {
      x = love.math.random(0, 1100),
      y = love.math.random(0, 600),
      vx = love.math.random(20, 40),
      vy = love.math.random(20, 40),
   }
end

function love.update(dt)
   for _, e in ipairs(entities) do
      e.x = e.x + e.vx * dt
      e.y = e.y + e.vy * dt
   end

   love.window.setTitle(love.timer.getFPS())
end
