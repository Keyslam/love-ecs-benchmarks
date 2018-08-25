package.path = package.path .. ";./?.lua;./?/init.lua;./init.lua"

local HooECS = require("HooECS")
HooECS.initialize({ globals = true })

describe('Eventmanager', function()
    local Listener, TestEvent
    local listener, eventManager, testEvent

    setup(
    function()
        -- Test Listener
        Listener = HooECS.class('Listener')
        Listener.number = 0
        function Listener:test(event)
            self.number = event.number
        end

        function Listener:valueReturnTest(event)
            return event.number
        end

        Listener2 = HooECS.class('Listener2')

        function Listener2:valueReturnTest(event)
            return event.number
        end

        -- Test Event
        TestEvent = HooECS.class('TestEvent')
        TestEvent.number = 12
    end
    )

    before_each(
    function()
        eventManager = EventManager()
        listener = Listener()
        listener2 = Listener2()
        testEvent = TestEvent()
    end
    )

    it('addListener() adds Listener', function()
        eventManager:addListener('TestEvent', listener, listener.test)
        assert.are.equal(type(eventManager.eventListeners['TestEvent']), 'table')
        assert.are.equal(eventManager.eventListeners['TestEvent'][1][1], listener )
    end)

    it('addListener() doesn`t add Listener twice', function()
        eventManager:addListener('TestEvent', listener, listener.test)
        assert.are.equal(type(eventManager.eventListeners['TestEvent']), 'table')
        assert.are.equal(eventManager.eventListeners['TestEvent'][1][1].number , 0)
        -- Creation of new Listener with same name but different variable
        listener = Listener()
        listener.number = 5
        eventManager:addListener('TestEvent', listener, listener.test)
        assert.are_not.equal(eventManager.eventListeners['TestEvent'][1][1].number, 5)
    end)

    it('addListener() without function throws debug message', function()
        -- Mock HooECS debug function
        local debug_spy = spy.on(HooECS, 'debug')

        eventManager:addListener('TestEvent', listener, 'lol')

        -- Assert that the debug function hast been called
        assert.spy(debug_spy).was_called()
        HooECS.debug:revert()
    end)

    it('addListener() without listener.class.name on listener throws debug message', function()
        -- Mock HooECS debug function
        local debug_spy = spy.on(HooECS, 'debug')

        eventManager:addListener('TestEvent', {class={}}, listener.test)

        -- Assert that the debug function hast been called
        assert.spy(debug_spy).was_called()
        HooECS.debug:clear()

        eventManager:addListener('TestEvent', {}, listener.test)
        assert.spy(debug_spy).was_called()
        HooECS.debug:revert()
    end)

    it('removeListener() removes Listener', function()
        eventManager:addListener('TestEvent', listener, listener.test)
        assert.are.equal(type(eventManager.eventListeners['TestEvent']), 'table')
        assert.are.equal(eventManager.eventListeners['TestEvent'][1][1], listener )

        eventManager:removeListener('TestEvent', listener.class.name)
        assert.are.equal(eventManager.eventListeners['TestEvent'][1], nil )
    end)

    it('removeListener() on unregistered listener throws debug message', function()
        -- Mock HooECS debug function
        local debug_spy = spy.on(HooECS, 'debug')

        eventManager:removeListener('TestEvent', listener)

        -- Assert that the debug function hast been called
        assert.spy(debug_spy).was_called()
        HooECS.debug:clear()

        eventManager:addListener('TestEvent', listener, listener.test)
        eventManager:removeListener('TestEvent', listener)
        eventManager:removeListener('TestEvent', listener)
        assert.spy(debug_spy).was_called()

        HooECS.debug:revert()
    end)


    it('fireEvent() listener Function is beeing called', function()
        eventManager:addListener('TestEvent', listener, listener.test)
        assert.are.equal(type(eventManager.eventListeners['TestEvent']), 'table')
        assert.are.equal(eventManager.eventListeners['TestEvent'][1][1], listener )

        eventManager:fireEvent(testEvent)
        assert.are.equal(eventManager.eventListeners['TestEvent'][1][1].number , testEvent.number)
    end)

    it('fireEvent() returns values appropriately', function()
        eventManager:addListener('TestEvent', listener, listener.valueReturnTest)
        assert.are.equal(eventManager:fireEvent(testEvent), 12)
        eventManager:addListener('TestEvent', listener2, listener2.valueReturnTest)
        assert.are.equal(#eventManager:fireEvent(testEvent), 2)
        assert.are.equal(eventManager:fireEvent(testEvent)[2], 12)
    end)

end)
