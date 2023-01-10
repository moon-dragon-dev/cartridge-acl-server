require('strict').on()

local Module = {}

function Module.hello(name)
    return string.format('Hello, %s!', name)
end

function Module.f(param)
    return 1, 2, param
end

return Module