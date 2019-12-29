local physics = {}

function physics:update(dt)
	for _, e in self.world.groups.velocity.entities:items() do
		e.x = e.x + e.vx * dt
		e.y = e.y + e.vy * dt
		if e.x > love.graphics.getWidth() or e.y > love.graphics.getHeight() then
			if love.math.random() < .4 then
				e.dead = true
			else
				e.x = 0
				e.y = 0
			end
		end
	end
end

local spriteRenderer = {}

function spriteRenderer:draw()
	if not enableDrawing then return end
	for _, e in self.world.groups.sprite.entities:items() do
		love.graphics.draw(testSprite, e.x, e.y)
	end
end

local world = require 'nata.nata'.new {
	groups = {
		velocity = {filter = {'x', 'y', 'vx', 'vy'}},
		sprite = {filter = {'x', 'y', 'sprite'}},
	},
	systems = {
		physics,
		spriteRenderer
	},
}

local removeCondition = function(e) return e.dead end

local nataDemo = {}

function nataDemo.update(dt)
	for _ = 1, 100 do
		if entityLimit and world.entities:count() > entityLimit then
			break
		end
		world:queue {
			x = 0,
			y = 0,
			vx = love.math.random(10, 30),
			vy = love.math.random(10, 30),
			sprite = true,
		}
	end
	world:flush()
	world:emit('update', dt)
	world:remove(removeCondition)
end

function nataDemo.draw()
	world:emit 'draw'
end

function nataDemo.getNumEntities()
	return world.entities:count()
end

return nataDemo
