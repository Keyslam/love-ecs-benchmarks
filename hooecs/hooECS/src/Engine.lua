-- Getting folder that contains our src
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")

local HooECS = require(folderOfThisFile .. 'namespace')

local Engine = HooECS.class("Engine")

function Engine:initialize()
    self.entities = {}
    self.entityId = 1
    self.rootEntity = HooECS.Entity()
    self.rootEntity.engine = self
    self.singleRequirements = {}
    self.allRequirements = {}
    self.entityLists = {}
    self.entityUpdateList = {}
    self.eventManager = HooECS.EventManager()

    self.systems = {}
    self.systemRegistry = {}
    self.systems["update"] = {}
    self.systems["draw"] = {}

    self.eventManager:addListener("ComponentRemoved", self, self.componentRemoved)
    self.eventManager:addListener("ComponentAdded", self, self.componentAdded)
    self.eventManager:addListener("EntityActivated", self, self.activateEntity)
    self.eventManager:addListener("EntityDeactivated", self, self.deactivateEntity)
end

function Engine:addEntity(entity)
    -- Setting engine eventManager as eventManager for entity
    entity.eventManager = self.eventManager
    -- Getting the next free ID or insert into table
    local newId = self.entityId
    self.entityId = self.entityId + 1
    entity.id = newId
    self.entities[entity.id] = entity

    -- If entity implements an update function. Add it to the update table.
    if type(entity.update) == "function" then
        self.entityUpdateList[entity.id] = entity
    end

    -- If a rootEntity entity is defined and the entity doesn't have a parent yet, the rootEntity entity becomes the entity's parent
    if entity.parent == nil then
        entity:setParent(self.rootEntity)
    end
    entity:registerAsChild()

    for _, component in pairs(entity.components) do
        local name = component.class.name
        -- Adding Entity to specific Entitylist
        if not self.entityLists[name] then self.entityLists[name] = {} end
        self.entityLists[name][entity.id] = entity

        -- Adding Entity to System if all requirements are granted
        if self.singleRequirements[name] then
            for _, system in pairs(self.singleRequirements[name]) do
                self:addEntityToSystem(entity, system)
            end
        end
    end
end

function Engine:removeEntity(entity, removeChildren, newParent)
    if self.entities[entity.id] then
        -- Removing the Entity from all Systems and engine
        for _, component in pairs(entity.components) do
            local name = component.class.name
            if self.singleRequirements[name] then
                for _, system in pairs(self.singleRequirements[name]) do
                    system:removeEntity(entity)
                end
            end
        end
        -- Deleting the Entity from the specific entity lists
        for _, component in pairs(entity.components) do
            self.entityLists[component.class.name][entity.id] = nil
        end

        -- If removeChild is defined, all children become deleted recursively
        if removeChildren then
            for _, child in pairs(entity.children) do
                self:removeEntity(child, true)
            end
        else
            -- If a new Parent is defined, this Entity will be set as the new Parent
            for _, child in pairs(entity.children) do
                if newParent then
                    child:setParent(newParent)
                else
                    child:setParent(self.rootEntity)
                end
                -- Registering as child
                entity:registerAsChild()
            end
        end
        -- Removing Reference to entity from parent
        for _, _ in pairs(entity.parent.children) do
            entity.parent.children[entity.id] = nil
        end
        -- Setting status of entity to dead. This is for other systems, which still got a hard reference on this
        self.entities[entity.id].alive = false
        -- Removing entity from engine
        self.entities[entity.id] = nil
    else
        HooECS.debug("Engine: Trying to remove non existent entity from engine.")
        if entity.id then
            HooECS.debug("Engine: Entity id: " .. entity.id)
        else
            HooECS.debug("Engine: Entity has not been added to any engine yet. (No entity.id)")
        end
        HooECS.debug("Engine: Entity's components:")
        for index, component in pairs(entity.components) do
            HooECS.debug(index, component)
        end
    end
end

function Engine:addSystem(system, type)
    local name = system.class.name

    -- Check if the specified type is correct
    if type ~= nil and type ~= "draw" and type ~= "update" then
        HooECS.debug("Engine: Trying to add System " .. name .. "with invalid type " .. type .. ". Aborting")
        return
    end

    -- Check if a type should be specified
    if system.draw and system.update and not type then
        HooECS.debug("Engine: Trying to add System " .. name .. ", which has an update and a draw function, without specifying type. Aborting")
        return
    end

    -- Check if the user is accidentally adding two instances instead of one
    if self.systemRegistry[name] and self.systemRegistry[name] ~= system then
        HooECS.debug("Engine: Trying to add two different instances of the same system. Aborting.")
        return
    end

    -- Adding System to engine system reference table
    if not (self.systemRegistry[name]) then
        self:registerSystem(system)
    -- This triggers if the system doesn't have update and draw and it's already existing.
    elseif not (system.update and system.draw) then
        if self.systemRegistry[name] then
            HooECS.debug("Engine: System " .. name .. " already exists. Aborting")
            return
        end
    end

    -- Adding System to draw table
    if system.draw and (not type or type == "draw") then
        for _, registeredSystem in pairs(self.systems["draw"]) do
            if registeredSystem.class.name == name then
                HooECS.debug("Engine: System " .. name .. " already exists. Aborting")
                return
            end
        end
        table.insert(self.systems["draw"], system)
    -- Adding System to update table
    elseif system.update and (not type or type == "update") then
        for _, registeredSystem in pairs(self.systems["update"]) do
            if registeredSystem.class.name == name then
                HooECS.debug("Engine: System " .. name .. " already exists. Aborting")
                return
            end
        end
        table.insert(self.systems["update"], system)
    end

    -- Checks if some of the already existing entities match the required components.
    for _, entity in pairs(self.entities) do
        self:addEntityToSystem(entity, system)
    end

    return system
end

function Engine:registerSystem(system)
    local name = system.class.name
    self.systemRegistry[name] = system
    -- case: system:requires() returns a table of strings
    if system:requires()[1] and type(system:requires()[1]) == "string" then
        for index, req in pairs(system:requires()) do
            -- Registering at singleRequirements
            if index == 1 then
                self.singleRequirements[req] = self.singleRequirements[req] or {}
                table.insert(self.singleRequirements[req], system)
            end
            -- Registering at allRequirements
            self.allRequirements[req] = self.allRequirements[req] or {}
            table.insert(self.allRequirements[req], system)
        end
    end

    -- case: system:requires() returns a table of tables which contain strings
    if HooECS.util.firstElement(system:requires()) and type(HooECS.util.firstElement(system:requires())) == "table" then
        for index, componentList in pairs(system:requires()) do
            -- Registering at singleRequirements
            local component = componentList[1]
            self.singleRequirements[component] = self.singleRequirements[component] or {}
            table.insert(self.singleRequirements[component], system)

            -- Registering at allRequirements
            for _, req in pairs(componentList) do
                self.allRequirements[req] = self.allRequirements[req] or {}
                -- Check if this List already contains the System
                local contained = false
                for _, registeredSystem in pairs(self.allRequirements[req]) do
                    if registeredSystem == system then
                        contained = true
                        break
                    end
                end
                if not contained then
                    table.insert(self.allRequirements[req], system)
                end
            end
            -- Create tables for multiple requirements in the system's target directory
            system.targets[index] = {}
        end
    end
end

function Engine:stopSystem(name)
    if self.systemRegistry[name] then
        self.systemRegistry[name].active = false
    else
        HooECS.debug("Engine: Trying to stop not existing System: " .. name)
    end
end

function Engine:startSystem(name)
    if self.systemRegistry[name] then
        self.systemRegistry[name].active = true
    else
        HooECS.debug("Engine: Trying to start not existing System: " .. name)
    end
end

function Engine:toggleSystem(name)
    if self.systemRegistry[name] then
        self.systemRegistry[name].active = not self.systemRegistry[name].active
    else
        HooECS.debug("Engine: Trying to toggle not existing System: " .. name)
    end
end

function Engine:update(dt)
    for _, entity in pairs(self.entityUpdateList) do
        if entity.update then
            entity:update(dt)
        else
            self.entityUpdateList[entity.id] = nil
        end
    end
    for _, system in ipairs(self.systems["update"]) do
        if system.active then
            system:update(dt)
        end
    end
end

function Engine:addUpdateEntity(entity)
    if entity.id then
        self.entityUpdateList[entity.id] = entity
    end
end

function Engine:removeUpdateEntity(entity)
    self.entityUpdateList[entity.id] = nil
end

function Engine:draw()
    for _, system in ipairs(self.systems["draw"]) do
        if system.active then
            system:draw()
        end
    end
end

function Engine:componentRemoved(event)
    -- In case a single component gets removed from an entity, we inform
    -- all systems that this entity lost this specific component.
    local entity = event.entity
    local component = event.component

    -- Removing Entity from Entity lists
    self.entityLists[component][entity.id] = nil

    -- Removing Entity from systems
    if self.allRequirements[component] then
        for _, system in pairs(self.allRequirements[component]) do
            system:componentRemoved(entity, component)
        end
    end
end

function Engine:componentAdded(event)
    local entity = event.entity
    local component = event.component

    -- Adding the Entity to Entitylist
    if not self.entityLists[component] then self.entityLists[component] = {} end
    self.entityLists[component][entity.id] = entity

    -- Adding the Entity to the requiring systems
    if self.allRequirements[component] then
        for _, system in pairs(self.allRequirements[component]) do
            self:addEntityToSystem(entity, system)
        end
    end
end

function Engine:getRootEntity()
    if self.rootEntity ~= nil then
        return self.rootEntity
    end
end

-- Returns an Entitylist for a specific component. If the Entitylist doesn't exist yet it'll be created and returned.
function Engine:getEntitiesWithComponent(component)
    if not self.entityLists[component] then self.entityLists[component] = {} end
    return self.entityLists[component]
end

-- Returns a count of existing Entities with a given component
function Engine:getEntityCount(component)
    local count = 0
    if self.entityLists[component] then
        for _, system in pairs(self.entityLists[component]) do
            count = count + 1
        end
    end      
    return count    
end

function Engine:activateEntity(event)
    for _, component in pairs(event.entity.components) do
        local name = component.class.name

        if self.singleRequirements[name] then
            for _, system in pairs(self.singleRequirements[name]) do
                self:addEntityToSystem(event.entity, system)
            end
        end
    end
end

function Engine:deactivateEntity(event)
    for _, component in pairs(event.entity.components) do
        local name = component.class.name

        if self.singleRequirements[name] then
            for _, system in pairs(self.singleRequirements[name]) do
                self:removeEntityFromSystem(event.entity, system)
            end
        end
    end
end

function Engine:addEntityToSystem(entity, system) -- luacheck: ignore self
    local categories
    entity, categories = self:meetsRequirements(entity, system)
    if entity then
        if categories then
            for _, category in pairs(categories) do
                system:addEntity(entity, category)
            end
        else
            system:addEntity(entity)
        end
    end
end

function Engine:removeEntityFromSystem(entity, system)
    local categories
    entity, categories = self:meetsRequirements(entity, system)
    if entity then
        if categories then
            for _, category in pairs(categories) do
                system:removeEntity(entity, category)
            end
        else
            system:removeEntity(entity)
        end
    end
end

function Engine:meetsRequirements(entity, system)
    local meetsrequirements = true
    local categories = {}

    for index, req in pairs(system:requires()) do
        if type(req) == "string" then
            if not entity.components[req] then
                meetsrequirements = false
                break
            end
        elseif type(req) == "table" then
            meetsrequirements = true
            for _, req2 in pairs(req) do
                if not entity.components[req2] then
                    meetsrequirements = false
                    break
                end
            end
            if meetsrequirements == true then
                table.insert(categories, index)
            end
        end
    end
    if meetsrequirements == true and #categories == 0 then
        return entity
    elseif #categories > 0 then
        return entity, categories
    end
end

return Engine
