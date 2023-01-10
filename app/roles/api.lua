require('strict').on()

local my_module = require('app.my_module')

local API_FUNCTIONS = {
    hello = my_module.hello,
    f     = my_module.f,
}

for name, func in pairs(API_FUNCTIONS) do
    rawset(_G, name, func)
end

local function init(opts)   -- luacheck: no unused args
    return true
end

return {
    role_name = 'app.roles.api',
    init      = init,
}