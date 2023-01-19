require('strict').on()

local CONSTANT = require('app.constant')

local acl_v4 = require('app.acl_v4.export')
local acl_v6 = require('app.acl_v6.export')

local INIT_MODULES = {
    require('app.acl_v4'),
    require('app.acl_v6'),
}

local API_FUNCTIONS = {
    acl_v4_create_from_interval = acl_v4.create_from_interval,
    acl_v4_create_from_network  = acl_v4.create_from_network,
    acl_v4_contains             = acl_v4.contains,
    acl_v4_get                  = acl_v4.get,
    acl_v4_list                 = acl_v4.list,
    acl_v4_update               = acl_v4.update,
    acl_v4_delete               = acl_v4.delete,

    acl_v6_create_from_interval = acl_v6.create_from_interval,
    acl_v6_create_from_network  = acl_v6.create_from_network,
    acl_v6_contains             = acl_v6.contains,
    acl_v6_get                  = acl_v6.get,
    acl_v6_list                 = acl_v6.list,
    acl_v6_update               = acl_v6.update,
    acl_v6_delete               = acl_v6.delete,
}

local function apply_config(conf, opts)     -- luacheck: no unused args
    if opts.is_master then
        box.schema.role.create(CONSTANT.ROLE_API, { if_not_exists = true })

        for _, module in pairs(INIT_MODULES) do
            if module.init ~= nil then
                module.init(opts)
            end

            if module.space_name ~= nil then
                box.schema.role.grant(
                    CONSTANT.ROLE_API,
                    'read,write',
                    'space',
                    module.space_name(),
                    {
                        if_not_exists = true,
                    }
                )
            end
        end

        for name, _ in pairs(API_FUNCTIONS) do
            box.schema.func.create(name, { if_not_exists = true })

            box.schema.role.grant(
                CONSTANT.ROLE_API,
                'execute',
                'function',
                name,
                {
                    if_not_exists = true,
                }
            )
        end
    end

    return true
end

for name, func in pairs(API_FUNCTIONS) do
    rawset(_G, name, func)
end

return {
    role_name    = 'app.roles.api',
    apply_config = apply_config,
}