require('strict').on()

local t = require('luatest')

local helper = require('test.helper.common')

local cartridge_helpers = require('cartridge.test-helpers')

helper.cluster = cartridge_helpers.Cluster:new({
    server_command = helper.server_command,
    datadir        = helper.datadir,
    use_vshard     = false,
    replicasets    = {
        {
            alias   = 'api',
            uuid    = cartridge_helpers.uuid('a'),
            roles   = {'app.roles.api'},
            servers = {
                { instance_uuid = cartridge_helpers.uuid('a', 1), alias = 'api' },
            }
        }
    }
})

t.before_suite(function() helper.cluster:start() end)
t.after_suite(function() helper.cluster:stop() end)

return helper