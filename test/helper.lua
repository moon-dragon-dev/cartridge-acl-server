require('strict').on()

local fio = require('fio')

local cartridge_helpers = require('cartridge.test-helpers')

local helper = {}

helper.root = fio.dirname(fio.abspath(package.search('init')))
helper.datadir = fio.pathjoin(helper.root, 'tmp', 'db_test')
helper.server_command = fio.pathjoin(helper.root, 'init.lua')

helper.cluster = cartridge_helpers.Cluster:new({
    server_command = helper.server_command,
    datadir = helper.datadir,
    use_vshard = false,
    replicasets = {
        {
            alias = 'api',
            uuid = cartridge_helpers.uuid('a'),
            roles = {'app.roles.api'},
            servers = {
                { instance_uuid = cartridge_helpers.uuid('a', 1), alias = 'api' },
            }
        }
    }
})

return helper