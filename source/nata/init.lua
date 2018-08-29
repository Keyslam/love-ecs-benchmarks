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
	filter = {'x', 'y', 'vx', 'vy'},

	process = {
		update = function(self, dt)
			for _, e in ipairs(self.entities) do
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
			end
		end,
	},
}

local spriteRendererSystem = {
	filter = {'x', 'y', 'sprite'},

	process = {
		draw = function(self)
			for _, e in ipairs(self.entities) do
				if enableDrawing then
					love.graphics.draw(testSprite, e.x, e.y)
				end
			end
		end,
	}

}

local entities = require 'nata.nata'.new {
	physicsSystem,
	spriteRendererSystem
}

local removeCheck = function(e) return e.dead end

return {
	update = function(dt)
		for _ = 1, 100 do
			if entityLimit and #entities.entities >= entityLimit then
				break
			end
			entities:queue(createEntity())
			entities:flush()
		end
		entities:process('update', dt)
		entities:remove(removeCheck)
	end,

	draw = function()
		entities:process 'draw'
	end,

	getNumEntities = function()
		return #entities.entities
	end,
}
