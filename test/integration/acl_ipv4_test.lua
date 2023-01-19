require('strict').on()

local t = require('luatest')
local g = t.group('integration.acl_ipv4')

local helper = require('test.helper.integration')

local STATUS = require('test.helper.status')

local FUNC = {
    ACL_V4_CREATE_FROM_INTERVAL = 'acl_v4_create_from_interval',
    ACL_V4_CREATE_FROM_NETWORK  = 'acl_v4_create_from_network',
    ACL_V4_CONTAINS             = 'acl_v4_contains',
    ACL_V4_GET                  = 'acl_v4_get',
    ACL_V4_LIST                 = 'acl_v4_list',
    ACL_V4_UPDATE               = 'acl_v4_update',
    ACL_V4_DELETE               = 'acl_v4_delete',
}

local VALID = {
    ID        = 1,
    IP_FROM   = '1.2.3.0',
    IP_TO     = '1.2.3.255',
    NETWORK   = '192.168.0.1/24',
    IS_ACTIVE = true,
    COMMENT   = 'comment',
    LIMIT     = 10,
}

local INVALID = {
    ID        = 'invalid_id',
    IP        = '256.256.256.256',
    IP_FROM   = 'invalid_ip_from',
    IP_TO     = 'invalid_ip_to',
    NETWORK_1 = 'invalid_network/invalid_mask',
    NETWORK_2 = 'invalid_network/32',
    NETWORK_3 = 'invalid_network',
    NETWORK_4 = '1.2.3.4/invalid_mask',
    IS_ACTIVE = 'invalid_is_active',
    LIMIT     = 'invalid_limit',
}

g.test_acl = function()
    local data = {
        {
            ip_from  = '192.168.0.255',
            ip_to    = '192.168.0.1',
            contains = {
                '192.168.0.1',
                '192.168.0.255',
                '192.168.0.100',
            },
            not_contains = {
                '192.1.2.3',
            },
        },
        {
            ip_from  = '10.0.0.0',
            ip_to    = '10.255.255.255',
            contains = {
                '10.0.0.0',
                '10.255.255.255',
                '10.1.2.3',
            },
            not_contains = {
                '11.0.0.0',
                '9.0.0.0',
            },
        },
        {
            network = '1.2.3.4/24',
            contains = {
                '1.2.3.4',
                '1.2.3.0',
                '1.2.3.255',
            },
            not_contains = {
                '2.3.4.5',
                '1.2.2.255',
                '1.2.4.0',
            }
        },
        {
            network = '0.0.0.0/0',
            contains = {
                '0.0.0.0',
                '255.255.255.255',
            },
            not_contains = {}
        }
    }

    local active = true

    for _, d in pairs(data) do
        do
            local status, res
            if d.network then
                status, res = helper.cluster.main_server.net_box:call(
                    FUNC.ACL_V4_CREATE_FROM_NETWORK,
                    {d.network, not active, 'some comment'}
                )
                d.desc = string.format('network = %s', d.network)
            else
                status, res = helper.cluster.main_server.net_box:call(
                    FUNC.ACL_V4_CREATE_FROM_INTERVAL,
                    {d.ip_from, d.ip_to, not active, 'some comment'}
                )
                d.desc = string.format('network = %s - %s', d.ip_from, d.ip_to)
            end

            t.assert_equals(status, STATUS.OK)
            t.assert_equals(type(res), 'table')
            d.id = res.id
        end

        do
            local status, res = helper.cluster.main_server.net_box:call(
                FUNC.ACL_V4_GET,
                {d.id}
            )
            t.assert_equals(status, STATUS.OK)
            t.assert_equals(type(res), 'table')
            t.assert_equals(res.id, d.id)
        end

        do
            local status = helper.cluster.main_server.net_box:call(
                FUNC.ACL_V4_GET,
                {d.id + 1}
            )
            t.assert_equals(status, STATUS.NOT_FOUND)
        end

        do
            local status, res = helper.cluster.main_server.net_box:call(
                FUNC.ACL_V4_UPDATE,
                {d.id, active, 'another comment'}
            )
            t.assert_equals(status, STATUS.OK)
            t.assert_equals(type(res), 'table')
            t.assert_equals(res.id, d.id)
        end

        do
            local status = helper.cluster.main_server.net_box:call(
                FUNC.ACL_V4_UPDATE,
                {d.id + 1, active, 'another comment'}
            )
            t.assert_equals(status, STATUS.NOT_FOUND)
        end

        for _, ip in pairs(d.contains) do
            local status, data = helper.cluster.main_server.net_box:call(
                FUNC.ACL_V4_CONTAINS,
                {ip}
            )
            t.assert_equals(status, STATUS.OK)
            t.assert_equals(type(data), 'boolean')
            t.assert_equals(data, true, string.format('%s, ip = %s', d.desc, ip))
        end

        for _, ip in pairs(d.not_contains) do
            local status, data = helper.cluster.main_server.net_box:call(
                FUNC.ACL_V4_CONTAINS,
                {ip}
            )
            t.assert_equals(status, STATUS.OK)
            t.assert_equals(type(data), 'boolean')
            t.assert_equals(data, false, string.format('%s, ip = %s', d.desc, d.network, ip))
        end

        do
            local status, data = helper.cluster.main_server.net_box:call(
                FUNC.ACL_V4_DELETE,
                {d.id}
            )
            t.assert_equals(status, STATUS.OK)
            t.assert_equals(type(data), 'table')
            t.assert_equals(data.id, d.id)
        end
    end
end

g.test_params_acl_v4_create_from_interval = function()
    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_CREATE_FROM_INTERVAL,
            {}
        )
        t.assert_equals(status, STATUS.UNDEFINED_IP_FROM)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_CREATE_FROM_INTERVAL,
            {INVALID.IP_FROM}
        )
        t.assert_equals(status, STATUS.INVALID_IP_FROM)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_CREATE_FROM_INTERVAL,
            {VALID.IP_FROM}
        )
        t.assert_equals(status, STATUS.UNDEFINED_IP_TO)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_CREATE_FROM_INTERVAL,
            {VALID.IP_FROM, INVALID.IP_TO}
        )
        t.assert_equals(status, STATUS.INVALID_IP_TO)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_CREATE_FROM_INTERVAL,
            {VALID.IP_FROM, VALID.IP_TO}
        )
        t.assert_equals(status, STATUS.UNDEFINED_IS_ACTIVE)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_CREATE_FROM_INTERVAL,
            {VALID.IP_FROM, VALID.IP_TO, INVALID.IS_ACTIVE}
        )
        t.assert_equals(status, STATUS.INVALID_IS_ACTIVE)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_CREATE_FROM_INTERVAL,
            {VALID.IP_FROM, VALID.IP_TO, VALID.IS_ACTIVE}
        )
        t.assert_equals(status, STATUS.UNDEFINED_COMMENT)
    end

    do
        local status, data = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_CREATE_FROM_INTERVAL,
            {VALID.IP_FROM, VALID.IP_TO, VALID.IS_ACTIVE, VALID.COMMENT}
        )
        t.assert_equals(status, STATUS.OK)
        t.assert_equals(type(data), 'table')
        t.assert_equals(type(data.id), 'number')
    end
end

g.test_params_acl_v4_create_from_network = function()
    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_CREATE_FROM_NETWORK,
            {}
        )
        t.assert_equals(status, STATUS.UNDEFINED_NETWORK)
    end

    local invalid_networks = {
        INVALID.NETWORK_1,
        INVALID.NETWORK_2,
        INVALID.NETWORK_3,
    }
    for _, invalid_network in ipairs(invalid_networks) do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_CREATE_FROM_NETWORK,
            {invalid_network}
        )
        t.assert_equals(status, STATUS.INVALID_NETWORK, string.format('network = %s', invalid_network))
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_CREATE_FROM_NETWORK,
            {VALID.NETWORK}
        )
        t.assert_equals(status, STATUS.UNDEFINED_IS_ACTIVE)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_CREATE_FROM_NETWORK,
            {VALID.NETWORK, INVALID.IS_ACTIVE}
        )
        t.assert_equals(status, STATUS.INVALID_IS_ACTIVE)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_CREATE_FROM_NETWORK,
            {VALID.NETWORK, VALID.IS_ACTIVE}
        )
        t.assert_equals(status, STATUS.UNDEFINED_COMMENT)
    end

    do
        local status, data = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_CREATE_FROM_NETWORK,
            {VALID.NETWORK, VALID.IS_ACTIVE, VALID.COMMENT}
        )
        t.assert_equals(status, STATUS.OK)
        t.assert_equals(type(data), 'table')
        t.assert_equals(type(data.id), 'number')
    end
end

g.test_params_acl_v4_get = function()
    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_GET,
            {}
        )
        t.assert_equals(status, STATUS.UNDEFINED_ID)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_GET,
            {INVALID.ID}
        )
        t.assert_equals(status, STATUS.INVALID_ID)
    end
end

g.test_params_acl_v4_contains = function()
    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_CONTAINS,
            {}
        )
        t.assert_equals(status, STATUS.UNDEFINED_IP)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_CONTAINS,
            {INVALID.IP}
        )
        t.assert_equals(status, STATUS.INVALID_IP)
    end
end

g.test_params_acl_v4_update = function()
    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_UPDATE,
            {}
        )
        t.assert_equals(status, STATUS.UNDEFINED_ID)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_UPDATE,
            {INVALID.ID}
        )
        t.assert_equals(status, STATUS.INVALID_ID)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_UPDATE,
            {VALID.ID}
        )
        t.assert_equals(status, STATUS.UNDEFINED_IS_ACTIVE)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_UPDATE,
            {VALID.ID, INVALID.IS_ACTIVE}
        )
        t.assert_equals(status, STATUS.INVALID_IS_ACTIVE)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_UPDATE,
            {VALID.ID, VALID.IS_ACTIVE}
        )
        t.assert_equals(status, STATUS.UNDEFINED_COMMENT)
    end

    do
        local status, data = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_UPDATE,
            {VALID.ID, VALID.IS_ACTIVE, VALID.COMMENT}
        )
        t.assert_equals(status, STATUS.OK)
        t.assert_equals(type(data), 'table')
    end
end

g.test_params_acl_v4_list = function()
    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_LIST,
            {INVALID.ID}
        )
        t.assert_equals(status, STATUS.INVALID_ID)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_LIST,
            {}
        )
        t.assert_equals(status, STATUS.UNDEFINED_LIMIT)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_LIST,
            {box.NULL}
        )
        t.assert_equals(status, STATUS.UNDEFINED_LIMIT)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_LIST,
            {VALID.ID}
        )
        t.assert_equals(status, STATUS.UNDEFINED_LIMIT)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_LIST,
            {box.NULL, INVALID.LIMIT}
        )
        t.assert_equals(status, STATUS.INVALID_LIMIT)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_LIST,
            {box.NULL, VALID.LIMIT}
        )
        t.assert_equals(status, STATUS.OK)
    end
end

g.test_params_acl_v4_delete = function()
    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_DELETE,
            {}
        )
        t.assert_equals(status, STATUS.UNDEFINED_ID)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_DELETE,
            {INVALID.ID}
        )
        t.assert_equals(status, STATUS.INVALID_ID)
    end

    do
        local status, data = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V4_DELETE,
            {VALID.ID}
        )
        t.assert_equals(status, STATUS.OK)
        t.assert_equals(type(data), 'table')
    end
end