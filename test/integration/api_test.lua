require('strict').on()

local t = require('luatest')
local g = t.group('integration.api')

local helper = require('test.helper')

g.before_all(function()
    g.cluster = helper.cluster
    g.cluster:start()
end)

g.after_all(function()
    g.cluster:stop()
end)

g.test_hello = function()
end