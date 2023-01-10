require('strict').on()

local t = require('luatest')
local g = t.group('unit.my_module')

local my_module = require('app.my_module')

g.test_hello = function()
    t.assert_equals(my_module.hello('world'), 'Hello, world!')
end

g.test_f = function()
    t.assert_equals({my_module.f('third')}, {1, 2, 'third'})
end