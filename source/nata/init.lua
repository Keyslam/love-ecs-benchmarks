local function createEntity()
	return {
		x = 0,
		y = 0,
		vx = love.math.random(10, 30),
		vy = love.math.random(10, 30),
		sprite = true,
	}
end

local maxX, maxY = love.graphics.getWidth(), love.graphics.getHeight()

local physicsSystem = {
	filter = function(e)
		return e.x and e.y and e.vx and e.vy
	end,

	update = function(e, dt)
		e.x = e.x + e.vx * dt
		e.y = e.y + e.vy * dt
		if e.x > maxX or e.y > maxY then
			if love.math.random() < .4 then
				e.dead = true
			else
				e.x = 0
				e.y = 0
			end
		end
	end,
}

local spriteRendererSystem = {
	filter = function(e)
		return e.x and e.y and e.sprite
	end,

	draw = function(e)
		if enableDrawing then
			love.graphics.draw(testSprite, e.x, e.y)
		end
	end,
}

local entities = require 'nata.nata'.new {
	physicsSystem,
	spriteRendererSystem
}

local removeCheck = function(e) return e.dead end

return {
	update = function(dt)
		for _ = 1, 100 do
			if entityLimit and entities:getSize() >= entityLimit then
				break
			end
			entities:queue(createEntity())
			entities:flush()
		end
		entities:call('update', dt)
		entities:remove(removeCheck)
	end,

	draw = function()
		entities:call 'draw'
	end,

	getNumEntities = function()
		return entities:getSize()
	end,
}
