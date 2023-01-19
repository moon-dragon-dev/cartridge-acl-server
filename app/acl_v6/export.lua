require('strict').on()

local fun = require('fun')

local util = require('app.util')

local ipv6 = require('ipv6')

local acl_v6 = require('app.acl_v6')

local CONSTANT = require('app.acl.constant')

local Module = {}

function Module.create_from_interval(ip_from, ip_to, is_active, comment)
    if ip_from == nil then
        return CONSTANT.STATUS_UNDEFINED_IP_FROM
    end

    local ip_from_p1, ip_from_p2 = ipv6.ip_to_u64_pair(ip_from)
    if ip_from_p1 == nil then
        return CONSTANT.STATUS_INVALID_IP_FROM
    end

    if ip_to == nil then
        return CONSTANT.STATUS_UNDEFINED_IP_TO
    end

    local ip_to_p1, ip_to_p2 = ipv6.ip_to_u64_pair(ip_to)
    if ip_to_p1 == nil then
        return CONSTANT.STATUS_INVALID_IP_TO
    end

    if is_active == nil then
        return CONSTANT.STATUS_UNDEFINED_IS_ACTIVE
    end

    if type(is_active) ~= 'boolean' then
        return CONSTANT.STATUS_INVALID_IS_ACTIVE
    end

    if comment == nil then
        return CONSTANT.STATUS_UNDEFINED_COMMENT
    end
    comment = tostring(comment)

    return CONSTANT.STATUS_OK, acl_v6.to_table(
        acl_v6.create(ip_from_p1, ip_from_p2, ip_to_p1, ip_to_p2, is_active, comment))
end

function Module.create_from_network(network, is_active, comment)
    if network == nil then
        return CONSTANT.STATUS_UNDEFINED_NETWORK
    end

    local ip_from_p1, ip_from_p2, ip_to_p1, ip_to_p2 = ipv6.cidr_network_to_u64_pairs(network)
    if ip_from_p1 == nil then
        return CONSTANT.STATUS_INVALID_NETWORK
    end

    if is_active == nil then
        return CONSTANT.STATUS_UNDEFINED_IS_ACTIVE
    end

    if type(is_active) ~= 'boolean' then
        return CONSTANT.STATUS_INVALID_IS_ACTIVE
    end

    if comment == nil then
        return CONSTANT.STATUS_UNDEFINED_COMMENT
    end
    comment = tostring(comment)

    return CONSTANT.STATUS_OK, acl_v6.to_table(
        acl_v6.create(ip_from_p1, ip_from_p2, ip_to_p1, ip_to_p2, is_active, comment))
end

function Module.contains(ip)
    if ip == nil then
        return CONSTANT.STATUS_UNDEFINED_IP
    end

    local ip_p1, ip_p2 = ipv6.ip_to_u64_pair(ip)
    if ip_p1 == nil then
        return CONSTANT.STATUS_INVALID_IP
    end

    return CONSTANT.STATUS_OK, acl_v6.contains(ip_p1, ip_p2)
end

function Module.list(from, limit)
    if from ~= nil then
        if not util.is_unsigned(from) then
            return CONSTANT.STATUS_INVALID_ID
        end
    else
        from = nil
    end

    if limit == nil then
        return CONSTANT.STATUS_UNDEFINED_LIMIT
    end

    if not util.is_unsigned(limit) then
        return CONSTANT.STATUS_INVALID_LIMIT
    end
    limit = tonumber(limit)

    local result = fun.iter(acl_v6.list(from, limit)):map(acl_v6.to_table):totable()

    return CONSTANT.STATUS_OK, result
end

function Module.get(id)
    if id == nil then
        return CONSTANT.STATUS_UNDEFINED_ID
    end

    if not util.is_unsigned(id) then
        return CONSTANT.STATUS_INVALID_ID
    end

    local result = acl_v6.get(id)
    if result == nil then
        return CONSTANT.STATUS_NOT_FOUND
    end

    return CONSTANT.STATUS_OK, acl_v6.to_table(result)
end

function Module.update(id, is_active, comment)
    if id == nil then
        return CONSTANT.STATUS_UNDEFINED_ID
    end

    if not util.is_unsigned(id) then
        return CONSTANT.STATUS_INVALID_ID
    end

    if is_active == nil then
        return CONSTANT.STATUS_UNDEFINED_IS_ACTIVE
    end

    if type(is_active) ~= 'boolean' then
        return CONSTANT.STATUS_INVALID_IS_ACTIVE
    end

    if comment == nil then
        return CONSTANT.STATUS_UNDEFINED_COMMENT
    end
    comment = tostring(comment)

    local result = acl_v6.update(id, is_active, comment)
    if result == nil then
        return CONSTANT.STATUS_NOT_FOUND
    end

    return CONSTANT.STATUS_OK, acl_v6.to_table(result)
end

function Module.delete(id)
    if id == nil then
        return CONSTANT.STATUS_UNDEFINED_ID
    end

    if not util.is_unsigned(id) then
        return CONSTANT.STATUS_INVALID_ID
    end

    local result = acl_v6.delete(id)
    if result == nil then
        return CONSTANT.STATUS_NOT_FOUND
    end

    return CONSTANT.STATUS_OK, acl_v6.to_table(result)
end

return Module