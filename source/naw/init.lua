local ecs = require("naw.naw")

local PositionComponent = ecs.Component(function(x, y)
    return {
        x = x or 0,
        y = y or 0,
    }
end)

local VelocityComponent = ecs.Component(function(x, y)
    return {
        x = x or 0,
        y = y or 0,
    }
end, PositionComponent)

local SpriteComponent = ecs.Component(function(sprite)
    return true
end, PositionComponent)

local world = ecs.World()

local maxX, maxY = love.graphics.getDimensions()

function physicsSystem(world, dt)
    for entity in world:foreachEntity(VelocityComponent) do
        local pos = entity[PositionComponent]
        local vel = entity[VelocityComponent]
        pos.x = pos.x + vel.x * dt
        pos.y = pos.y + vel.y * dt

        if pos.x > maxX or pos.y > maxY then
            if love.math.random() < 0.4 then
                entity:destroy()
            else
                pos.x, pos.y = 0, 0
            end
        end
    end
end

function spriteRendererSystem(world)
    for entity in world:foreachEntity(SpriteComponent) do
        local pos = entity[PositionComponent]
        if enableDrawing then
            love.graphics.draw(testSprite, pos.x, pos.y)
        end
    end
end

return {
    update = function(dt)
        for _ = 1, 100 do
            if entityLimit and world.entities.size >= entityLimit then
                break
            end
            local entity = world:Entity()
            entity:addComponent(PositionComponent, 0, 0)
            entity:addComponent(VelocityComponent, love.math.random(10, 30), love.math.random(10, 30))
            entity:addComponent(SpriteComponent)
        end

        physicsSystem(world, dt)
    end,

    draw = function()
        spriteRendererSystem(world)
    end,

    getNumEntities = function()
        return world.entities.size
    end,
}
