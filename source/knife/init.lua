local System = require "knife.system"

local function createEntity()
	return {
		pos = { x = 0, y = 0 },
    vel = {
      x = love.math.random(10, 30),
      y = love.math.random(10, 30)
    },
		sprite = true,
	}
end

local maxX, maxY = love.graphics.getWidth(), love.graphics.getHeight()

local physicsSystem = System(
  { 'pos', 'vel' },
	function(p, v, dt, entities, i)
    p.x = p.x + v.x * dt
    p.y = p.y + v.y * dt

    if p.x > maxX or p.y > maxY then
        if love.math.random() < .4 then
          table.remove(entities, i)
        else
          p.x = 0
          p.y = 0
        end
      end
    end)

local spriteRendererSystem = System(
  { 'pos', 'sprite' },
	function(p, s)
    if enableDrawing then
      love.graphics.draw(testSprite, p.x, p.y)
    end
  end)

local entities = {}

return {
	update = function(dt)
		for _ = 1, 100 do
			if entityLimit and #entities >= entityLimit then
				break
			end
      entities[#entities + 1] = createEntity()
		end

    for i = #entities, 1, -1 do
      physicsSystem(entities[i], dt, entities, i)
    end
	end,

	draw = function()
    for i = #entities, 1, -1 do
      spriteRendererSystem(entities[i])
    end
	end,

	getNumEntities = function()
		return #entities
	end,
}
