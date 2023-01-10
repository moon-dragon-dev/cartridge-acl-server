#!/usr/bin/env tarantool

require('strict').on()

if package.setsearchroot ~= nil then
    package.setsearchroot()
end

local cartridge = require('cartridge')

local ok, err = cartridge.cfg({
    roles = {
        'app.roles.api',
    },
})

assert(ok, tostring(err))