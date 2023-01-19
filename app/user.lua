require('strict').on()

local Module = {}

local CONSTANT = require('app.constant')

function Module.create_api_user(user, passwd)
    box.schema.user.create(user, { password = passwd, if_not_exists = true })
    box.schema.user.grant(user, CONSTANT.ROLE_API, nil, nil, { if_not_exists = true })
end

return Module