local entityLimit = 20000

local sprite = love.graphics.newCanvas(16, 16)
love.graphics.setCanvas(sprite)
love.graphics.setColor(1,1,1,1)
love.graphics.circle("fill",8,8,6)
love.graphics.setColor(0,0,0,1)
love.graphics.circle("line",8,8,6)
love.graphics.circle("line",10,8,1)
love.graphics.setCanvas()
love.graphics.setColor(1,1,1,1)

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
		love.graphics.draw(sprite, e.x, e.y)
	end,
}

local entities = require 'nata'.new {
	physicsSystem,
	spriteRendererSystem
}

local removeCheck = function(e) return e.dead end

function love.update(dt)
	for _ = 1, 100 do
		if entityLimit and #entities._entities >= entityLimit then
			break
		end
		entities:queue(createEntity())
		entities:flush()
	end
	entities:call('update', dt)
	entities:remove(removeCheck)
	love.window.setTitle(" Entities: " .. #entities._entities
      .. " | FPS: " .. love.timer.getFPS()
      .. " | Memory: " .. math.floor(collectgarbage 'count') .. 'kb')
end

function love.draw()
	entities:call 'draw'
end
