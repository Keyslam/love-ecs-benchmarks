local library = arg[2]
entityLimit = tonumber(arg[3]) or 50000
enableDrawing = arg[4] == 'true'

testSprite = love.graphics.newCanvas(16, 16)
love.graphics.setCanvas(testSprite)
love.graphics.setColor(1,1,1,1)
love.graphics.circle("fill",8,8,6)
love.graphics.setColor(0,0,0,1)
love.graphics.circle("line",8,8,6)
love.graphics.circle("line",10,8,1)
love.graphics.setCanvas()
love.graphics.setColor(1,1,1,1)

local test = require(library)

function love.update(dt)
	test.update(dt)
	love.window.setTitle(" Entities: " .. test.getNumEntities()
.. " | FPS: " .. love.timer.getFPS()
.. " | Memory: " .. math.floor(collectgarbage 'count') .. 'kb'
.. " | Delta: " .. love.timer.getDelta())
end

function love.draw()
	test.draw()
end
