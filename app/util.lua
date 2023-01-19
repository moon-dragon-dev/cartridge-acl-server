require('strict').on()

local Module = {}

function Module.is_unsigned(value)
    return type(value) == 'number' and value >= 0
end

return Module