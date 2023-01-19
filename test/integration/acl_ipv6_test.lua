require('strict').on()

local t = require('luatest')
local g = t.group('integration.acl_ipv6')

local helper = require('test.helper.integration')

local STATUS = require('test.helper.status')

local FUNC = {
    ACL_V6_CREATE_FROM_INTERVAL = 'acl_v6_create_from_interval',
    ACL_V6_CREATE_FROM_NETWORK  = 'acl_v6_create_from_network',
    ACL_V6_CONTAINS             = 'acl_v6_contains',
    ACL_V6_GET                  = 'acl_v6_get',
    ACL_V6_LIST                 = 'acl_v6_list',
    ACL_V6_UPDATE               = 'acl_v6_update',
    ACL_V6_DELETE               = 'acl_v6_delete',
}

local VALID = {
    ID        = 1,
    IP        = '2001:0db8:0000:0000:0000:0000:0010:ad12',
    IP_FROM   = '2001:0db8:0000:0000:0000:0000:0010:ad12',
    IP_TO     = '2001:0db8:0000:0000:0000:0000:0010:ffff',
    NETWORK   = '2001:4860:4860:0000:0000:0000:0000:8888/32',
    IS_ACTIVE = true,
    COMMENT   = 'comment',
    LIMIT     = 10,
}

local INVALID = {
    ID        = 'invalid_id',
    IP        = 'invalid_ip',
    IP_FROM   = 'invalid_ip_from',
    IP_TO     = 'invalid_ip_to',
    NETWORK_1 = 'invalid_network/invalid_mask',
    NETWORK_2 = 'invalid_network/32',
    NETWORK_3 = 'invalid_network',
    NETWORK_4 = '2001:0db8:0000:0000:0000:0000:0010:ad12/invalid_mask',
    IS_ACTIVE = 'invalid_is_active',
    LIMIT     = 'invalid_limit',
}

local DATA = {
    {
        ip_from  = '2001:4860:4860:0000:0000:0000:0000:8888',
        ip_to    = '2001:4860:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF',
        contains = {
            '2001:4860:4860:0000:0000:0000:0000:8888',
            '2001:4860:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF',
            '2001:4860:FFFF:0000:0000:0000:0000:0000',
        },
        not_contains = {
            '2002:4860:4860:0000:0000:0000:0000:8888',
        }
    },
    {
        ip_from  = '2001:4860:4860:0000:0000:0000:0000:8888',
        ip_to    = '2001:4860:4860:0000:0000:0000:0000:FFFF',
        contains = {
            '2001:4860:4860:0000:0000:0000:0000:8888',
            '2001:4860:4860:0000:0000:0000:0000:AAAA',
            '2001:4860:4860:0000:0000:0000:0000:FFFF',
        },
        not_contains = {
            '2001:4860:4860:0000:0000:0000:0000:8887',
            '2001:4860:4860:0000:0000:0000:0001:0000',
        }
    },
    {
        ip_from  = '2001:4860:1111:2222:3333:4444:5555:6666',
        ip_to    = '2001:4860:1111:2222:3334:0000:1111:2222',
        contains = {
            '2001:4860:1111:2222:3333:4444:5555:6666',
            '2001:4860:1111:2222:3333:4444:5555:6667',
            '2001:4860:1111:2222:3334:0000:1111:1111',
        },
        not_contains = {
            '2001:4860:1111:2222:3333:4444:5555:6665',
            '2001:4860:1111:2222:3334:0000:1111:2223',
        }
    },
    {
        ip_from  = '2001:4860:1111:2222:3333:4444:5555:6666',
        ip_to    = '2001:4860:1111:2222:8888:0000:1111:2222',
        contains = {
            '2001:4860:1111:2222:3333:4444:5555:6666',
            '2001:4860:1111:2222:4444:4444:4444:4444',
            '2001:4860:1111:2222:8887:FFFF:FFFF:FFFF',
            '2001:4860:1111:2222:8888:0000:1111:2222',
        },
        not_contains = {
            '2001:4860:1111:2222:3333:4444:5555:6665',
            '2001:4860:1111:2222:8888:0000:1111:2223',
        }
    },
    {
        ip_from  = '2001:4860:1111:2222:3333:4444:5555:6666',
        ip_to    = '2001:4861:0000:1111:2222:3333:4444:5555',
        contains = {
            '2001:4860:1111:2222:3333:4444:5555:6666',
            '2001:4860:1111:2222:4444:4444:4444:4444',
            '2001:4861:0000:0000:0000:0000:0000:0000',
            '2001:4861:0000:1111:2222:3333:4444:5555',
        },
        not_contains = {
            '2001:4860:1111:2222:3333:4444:5555:6665',
            '2001:4861:0000:1111:2222:3333:4444:5556',
        }
    },
    {
        ip_from  = '2001:4860:1111:2222:3333:4444:5555:6666',
        ip_to    = '2001:486F:0000:1111:2222:3333:4444:5555',
        contains = {
            '2001:4860:1111:2222:3333:4444:5555:6666',
            '2001:4860:1111:2222:4444:4444:4444:4444',
            '2001:486F:0000:0000:0000:0000:0000:0000',
            '2001:486F:0000:1111:2222:3333:4444:5555',
        },
        not_contains = {
            '2001:4860:1111:2222:3333:4444:5555:6665',
            '2001:486F:0000:1111:2222:3333:4444:5556',
        }
    },
    {
        ip_from  = '2001:4860:0000:0000:0000:0000:0000:0000',
        ip_to    = '2001:4860:0000:0000:0001:0000:0000:0000',
        contains = {
            '2001:4860:0000:0000:0000:0000:0000:0000',
            '2001:4860:0000:0000:0000:FFFF:FFFF:FFFF',
            '2001:4860:0000:0000:0001:0000:0000:0000',
        },
        not_contains = {
            '2001:4859:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF',
            '2001:4860:0000:0000:0001:0000:0000:0001',
        }
    },
    {
        ip_from  = '0001:0000:1111:2222:3333:0000:0000:0000',
        ip_to    = '0003:0000:0000:0000:0000:4444:5555:6666',
        contains = {
            '0001:0000:1111:2222:3333:0000:0000:0000',
            '0002:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF',
            '0003:0000:0000:0000:0000:0000:0000:0000',
            '0003:0000:0000:0000:0000:4444:5555:6666',
        },
        not_contains = {
            '0001:0000:1111:2222:3332:FFFF:FFFF:FFFF',
            '0003:0000:0000:0000:0000:4444:5555:6667',
        }
    },
    {
        ip_from  = '0001:0000:1111:2222:3333:0000:0000:0000',
        ip_to    = '0001:0001:0000:0000:0000:4444:5555:6666',
        contains = {
            '0001:0000:1111:2222:3333:0000:0000:0000',
            '0001:0000:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF',
            '0001:0001:0000:0000:0000:0000:0000:0000',
            '0001:0001:0000:0000:0000:4444:5555:6666',
        },
        not_contains = {
            '0001:0000:1111:2222:3332:FFFF:FFFF:FFFF',
            '0001:0001:0000:0000:0000:4444:5555:6667',
        }
    },
    {
        network = '2001:4860:1111:2222:3333:4444:5555:6666/128',
        contains = {
            '2001:4860:1111:2222:3333:4444:5555:6666',
        },
        not_contains = {
            '2001:4860:1111:2222:3333:4444:5555:6665',
            '2001:4860:1111:2222:3333:4444:5555:6667',
        }
    }
}

g.test_acl = function()
    local not_active = false
    local comment = 'some comment'

    for _, d in pairs(DATA) do
        do
            local status, res
            if d.network then
                status, res = helper.cluster.main_server.net_box:call(
                    FUNC.ACL_V6_CREATE_FROM_NETWORK,
                    {d.network, not_active, comment}
                )
                d.desc = string.format('network = %s', d.network)
            else
                status, res = helper.cluster.main_server.net_box:call(
                    FUNC.ACL_V6_CREATE_FROM_INTERVAL,
                    {d.ip_from, d.ip_to, not_active, comment}
                )
                d.desc = string.format('network = %s - %s', d.ip_from, d.ip_to)
            end
            t.assert_equals(status, STATUS.OK, d.desc)
            t.assert_equals(type(res), 'table', d.desc)
            d.id = res.id
        end

        do
            local status, res = helper.cluster.main_server.net_box:call(
                FUNC.ACL_V6_GET,
                {d.id}
            )
            t.assert_equals(status, STATUS.OK, d.desc)
            t.assert_equals(type(res), 'table', d.desc)
            t.assert_equals(res.id, d.id, d.desc)
        end

        do
            local status = helper.cluster.main_server.net_box:call(
                FUNC.ACL_V6_GET,
                {d.id + 1}
            )
            t.assert_equals(status, STATUS.NOT_FOUND, d.desc)
        end

        do
            local status, res = helper.cluster.main_server.net_box:call(
                FUNC.ACL_V6_UPDATE,
                {d.id, not_active, comment}
            )
            t.assert_equals(status, STATUS.OK, d.desc)
            t.assert_equals(type(res), 'table', d.desc)
        end

        do
            local status = helper.cluster.main_server.net_box:call(
                FUNC.ACL_V6_UPDATE,
                {d.id + 1, not_active, comment}
            )
            t.assert_equals(status, STATUS.NOT_FOUND, d.desc)
        end

        do
            local status, res = helper.cluster.main_server.net_box:call(
                FUNC.ACL_V6_UPDATE,
                {d.id, not not_active, 'another comment'}
            )
            t.assert_equals(status, STATUS.OK, d.desc)
            t.assert_equals(type(res), 'table', d.desc)
        end

        for _, ip in pairs(d.contains) do
            local status, res = helper.cluster.main_server.net_box:call(
                FUNC.ACL_V6_CONTAINS,
                {ip}
            )
            local desc = string.format('%s, ip = %s', d.desc, ip)
            t.assert_equals(status, STATUS.OK, desc)
            t.assert_equals(type(res), 'boolean', desc)
            t.assert_equals(res, true, desc)
        end

        for _, ip in pairs(d.not_contains) do
            local status, res = helper.cluster.main_server.net_box:call(
                FUNC.ACL_V6_CONTAINS,
                {ip}
            )
            local desc = string.format('%s, ip = %s', d.desc, ip)
            t.assert_equals(status, STATUS.OK, desc)
            t.assert_equals(type(res), 'boolean', desc)
            t.assert_equals(res, false, desc)
        end

        do
            local status, res = helper.cluster.main_server.net_box:call(
                FUNC.ACL_V6_DELETE,
                {d.id}
            )
            t.assert_equals(status, STATUS.OK, d.desc)
            t.assert_equals(type(res), 'table', d.desc)
            t.assert_equals(res.id, d.id, d.desc)
        end

        do
            local status = helper.cluster.main_server.net_box:call(
                FUNC.ACL_V6_DELETE,
                {d.id + 1}
            )
            t.assert_equals(status, STATUS.NOT_FOUND, d.desc)
        end
    end
end

g.test_acl_v6_list = function()
    local active = true
    local comment = 'some comment'

    for i, d in pairs(DATA) do
        do
            local status, res
            if d.network then
                status, res = helper.cluster.main_server.net_box:call(
                    FUNC.ACL_V6_CREATE_FROM_NETWORK,
                    {d.network, active, comment}
                )
                d.desc = string.format('network = %s', d.network)
            else
                status, res = helper.cluster.main_server.net_box:call(
                    FUNC.ACL_V6_CREATE_FROM_INTERVAL,
                    {d.ip_from, d.ip_to, active, comment}
                )
                d.desc = string.format('network = %s - %s', d.ip_from, d.ip_to)
            end
            t.assert_equals(status, STATUS.OK, d.desc)
            t.assert_equals(type(res), 'table')
            d.id = res.id
        end

        do
            local status, res = helper.cluster.main_server.net_box:call(
                FUNC.ACL_V6_LIST,
                {nil, #DATA + 1}
            )
            t.assert_equals(status, STATUS.OK, d.desc)
            t.assert_equals(type(res), 'table', d.desc)
            t.assert_equals(#res, i, d.desc)
        end
    end
end

g.test_params_acl_v6_create_from_interval = function()
    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_CREATE_FROM_INTERVAL,
            {}
        )
        t.assert_equals(status, STATUS.UNDEFINED_IP_FROM)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_CREATE_FROM_INTERVAL,
            {INVALID.IP_FROM}
        )
        t.assert_equals(status, STATUS.INVALID_IP_FROM)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_CREATE_FROM_INTERVAL,
            {VALID.IP_FROM}
        )
        t.assert_equals(status, STATUS.UNDEFINED_IP_TO)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_CREATE_FROM_INTERVAL,
            {VALID.IP_FROM, INVALID.IP_TO}
        )
        t.assert_equals(status, STATUS.INVALID_IP_TO)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_CREATE_FROM_INTERVAL,
            {VALID.IP_FROM, VALID.IP_TO}
        )
        t.assert_equals(status, STATUS.UNDEFINED_IS_ACTIVE)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_CREATE_FROM_INTERVAL,
            {VALID.IP_FROM, VALID.IP_TO, INVALID.IS_ACTIVE}
        )
        t.assert_equals(status, STATUS.INVALID_IS_ACTIVE)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_CREATE_FROM_INTERVAL,
            {VALID.IP_FROM, VALID.IP_TO, VALID.IS_ACTIVE}
        )
        t.assert_equals(status, STATUS.UNDEFINED_COMMENT)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_CREATE_FROM_INTERVAL,
            {VALID.IP_FROM, VALID.IP_TO, VALID.IS_ACTIVE, VALID.COMMENT}
        )
        t.assert_equals(status, STATUS.OK)
    end
end

g.test_params_acl_v6_create_from_network = function()
    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_CREATE_FROM_NETWORK,
            {}
        )
        t.assert_equals(status, STATUS.UNDEFINED_NETWORK)
    end

    for _, network in pairs({INVALID.NETWORK_1, INVALID.NETWORK_2, INVALID.NETWORK_3, INVALID.NETWORK_4}) do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_CREATE_FROM_NETWORK,
            {network}
        )
        t.assert_equals(status, STATUS.INVALID_NETWORK)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_CREATE_FROM_NETWORK,
            {VALID.NETWORK}
        )
        t.assert_equals(status, STATUS.UNDEFINED_IS_ACTIVE)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_CREATE_FROM_NETWORK,
            {VALID.NETWORK, INVALID.IS_ACTIVE}
        )
        t.assert_equals(status, STATUS.INVALID_IS_ACTIVE)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_CREATE_FROM_NETWORK,
            {VALID.NETWORK, VALID.IS_ACTIVE}
        )
        t.assert_equals(status, STATUS.UNDEFINED_COMMENT)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_CREATE_FROM_NETWORK,
            {VALID.NETWORK, VALID.IS_ACTIVE, VALID.COMMENT}
        )
        t.assert_equals(status, STATUS.OK)
    end
end

g.test_params_acl_v6_contains = function()
    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_CONTAINS,
            {}
        )
        t.assert_equals(status, STATUS.UNDEFINED_IP)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_CONTAINS,
            {INVALID.IP}
        )
        t.assert_equals(status, STATUS.INVALID_IP)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_CONTAINS,
            {VALID.IP}
        )
        t.assert_equals(status, STATUS.OK)
    end
end

g.test_params_acl_v6_get = function()
    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_GET,
            {}
        )
        t.assert_equals(status, STATUS.UNDEFINED_ID)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_GET,
            {INVALID.ID}
        )
        t.assert_equals(status, STATUS.INVALID_ID)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_GET,
            {VALID.ID}
        )
        t.assert_equals(status, STATUS.OK)
    end
end

g.test_params_acl_v6_list = function()
    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_LIST,
            {}
        )
        t.assert_equals(status, STATUS.UNDEFINED_LIMIT)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_LIST,
            {INVALID.ID}
        )
        t.assert_equals(status, STATUS.INVALID_ID)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_LIST,
            {VALID.ID}
        )
        t.assert_equals(status, STATUS.UNDEFINED_LIMIT)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_LIST,
            {VALID.ID, INVALID.LIMIT}
        )
        t.assert_equals(status, STATUS.INVALID_LIMIT)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_LIST,
            {VALID.ID, VALID.LIMIT}
        )
        t.assert_equals(status, STATUS.OK)
    end
end

g.test_params_acl_v6_update = function()
    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_UPDATE,
            {}
        )
        t.assert_equals(status, STATUS.UNDEFINED_ID)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_UPDATE,
            {INVALID.ID}
        )
        t.assert_equals(status, STATUS.INVALID_ID)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_UPDATE,
            {VALID.ID}
        )
        t.assert_equals(status, STATUS.UNDEFINED_IS_ACTIVE)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_UPDATE,
            {VALID.ID, INVALID.IS_ACTIVE}
        )
        t.assert_equals(status, STATUS.INVALID_IS_ACTIVE)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_UPDATE,
            {VALID.ID, VALID.IS_ACTIVE}
        )
        t.assert_equals(status, STATUS.UNDEFINED_COMMENT)
    end
end

g.test_params_acl_v6_delete = function()
    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_DELETE,
            {}
        )
        t.assert_equals(status, STATUS.UNDEFINED_ID)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_DELETE,
            {INVALID.ID}
        )
        t.assert_equals(status, STATUS.INVALID_ID)
    end

    do
        local status = helper.cluster.main_server.net_box:call(
            FUNC.ACL_V6_DELETE,
            {VALID.ID}
        )
        t.assert_equals(status, STATUS.OK)
    end
end