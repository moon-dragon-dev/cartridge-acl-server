require('strict').on()

local fun = require('fun')

local util = require('app.util')

local ipv4 = require('ipv4')

local acl_v4 = require('app.acl_v4')

local CONSTANT = require('app.acl.constant')

local Module = {}

function Module.create_from_interval(ip_from, ip_to, is_active, comment)
    if ip_from == nil then
        return CONSTANT.STATUS_UNDEFINED_IP_FROM
    end

    ip_from = ipv4.ip_to_u64(ip_from)
    if ip_from == nil then
        return CONSTANT.STATUS_INVALID_IP_FROM
    end

    if ip_to == nil then
        return CONSTANT.STATUS_UNDEFINED_IP_TO
    end

    ip_to = ipv4.ip_to_u64(ip_to)
    if ip_to == nil then
        return CONSTANT.STATUS_INVALID_IP_TO
    end

    if ip_from > ip_to then
        ip_from, ip_to = ip_to, ip_from
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

    return CONSTANT.STATUS_OK, acl_v4.to_table(acl_v4.create(ip_from, ip_to, is_active, comment))
end

function Module.create_from_network(network, is_active, comment)
    if network == nil then
        return CONSTANT.STATUS_UNDEFINED_NETWORK
    end

    local ip_from, ip_to = ipv4.cidr_network_to_u64_pair(network)
    if ip_from == nil then
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

    return CONSTANT.STATUS_OK, acl_v4.to_table(acl_v4.create(ip_from, ip_to, is_active, comment))
end

function Module.contains(ip)
    if ip == nil then
        return CONSTANT.STATUS_UNDEFINED_IP
    end

    ip = ipv4.ip_to_u64(ip)
    if ip == nil then
        return CONSTANT.STATUS_INVALID_IP
    end

    return CONSTANT.STATUS_OK, acl_v4.contains(ip)
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

    local result = fun.iter(acl_v4.list(from, limit)):map(acl_v4.to_table):totable()

    return CONSTANT.STATUS_OK, result
end

function Module.get(id)
    if id == nil then
        return CONSTANT.STATUS_UNDEFINED_ID
    end

    if not util.is_unsigned(id) then
        return CONSTANT.STATUS_INVALID_ID
    end

    local result = acl_v4.get(id)
    if result == nil then
        return CONSTANT.STATUS_NOT_FOUND
    end

    return CONSTANT.STATUS_OK, acl_v4.to_table(result)
end

function Module.update(id, is_active, comment)
    if id == nil then
        return CONSTANT.STATUS_UNDEFINED_ID
    end

    if not util.is_unsigned(id) then
        return CONSTANT.STATUS_INVALID_ID
    end
    id = tonumber(id)

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

    local result = acl_v4.update(id, is_active, comment)
    if result == nil then
        return CONSTANT.STATUS_NOT_FOUND
    end

    return CONSTANT.STATUS_OK, acl_v4.to_table(result)
end

function Module.delete(id)
    if id == nil then
        return CONSTANT.STATUS_UNDEFINED_ID
    end

    if not util.is_unsigned(id) then
        return CONSTANT.STATUS_INVALID_ID
    end
    id = tonumber(id)

    return CONSTANT.STATUS_OK, acl_v4.to_table(acl_v4.delete(id))
end

return Module