require('strict').on()

local fiber = require('fiber')

local CONSTANT = require('app.acl_v4.constant')
local ACL_CONSTANT = require('app.acl.constant')

local Module = {}

function Module.init()
    local space = box.schema.space.create(CONSTANT.SPACE_NAME, {
        format        = CONSTANT.FORMAT,
        if_not_exists = true,
    })

    space:create_index(CONSTANT.INDEX_BY_ID, {
        type          = CONSTANT.INDEX_BY_ID_TYPE,
        parts         = CONSTANT.INDEX_BY_ID_FIELDS,
        unique        = CONSTANT.INDEX_BY_ID_UNIQUE,
        if_not_exists = true,
    })

    space:create_index(CONSTANT.INDEX_BY_COORD, {
        type          = CONSTANT.INDEX_BY_COORD_TYPE,
        parts         = CONSTANT.INDEX_BY_COORD_FIELDS,
        unique        = CONSTANT.INDEX_BY_COORD_UNIQUE,
        distance      = CONSTANT.INDEX_BY_COORD_DISTANCE,
        dimension     = CONSTANT.INDEX_BY_COORD_DIMENSION,
        if_not_exists = true,
    })
end

function Module.space_name()
    return CONSTANT.SPACE_NAME
end

function Module.contains(num)
    local space = box.space[CONSTANT.SPACE_NAME]
    local index = space.index[CONSTANT.INDEX_BY_COORD]

    -- Iterator GE searches for tuples with a specified rectangle within their rectangles
    local found = index:select({ACL_CONSTANT.ACTIVE, num}, {
        iterator = box.index.GE,
        limit    = 1,
    })

    return #found > 0
end

function Module.create(num_from, num_to, is_active, comment)
    local space = box.space[CONSTANT.SPACE_NAME]

    local now = fiber.time64()

    local max_tuple = space.index[CONSTANT.INDEX_BY_ID]:max()
    local max_id = 0
    if max_tuple ~= nil then
        max_id = Module.get_id(max_tuple)
    end

    local active_value = is_active and ACL_CONSTANT.ACTIVE or ACL_CONSTANT.INACTIVE

    local tuple = space:insert({
        [CONSTANT.POS[CONSTANT.ID]]         = max_id + 1,
        [CONSTANT.POS[CONSTANT.COORD]]      = {
            active_value, num_from,
            active_value, num_to,
        },
        [CONSTANT.POS[CONSTANT.COMMENT]]    = comment,
        [CONSTANT.POS[CONSTANT.CREATED_AT]] = now,
        [CONSTANT.POS[CONSTANT.UPDATED_AT]] = now,
    })

    return tuple
end

function Module.get(id)
    local space = box.space[CONSTANT.SPACE_NAME]

    local tuple = space:get(id)

    return tuple
end

function Module.update(id, is_active, comment)
    local space = box.space[CONSTANT.SPACE_NAME]

    local tuple = Module.get(id)
    if tuple == nil then
        return nil
    end

    local update_it = {}
    if Module.get_is_active(tuple) ~= is_active then
        local active_value = is_active and ACL_CONSTANT.ACTIVE or ACL_CONSTANT.INACTIVE

        table.insert(update_it, { '=', CONSTANT.POS[CONSTANT.COORD], {
            active_value, Module.get_num_from(tuple),
            active_value, Module.get_num_to(tuple),
        }})
    end

    if Module.get_comment(tuple) ~= comment then
        table.insert(update_it, { '=', CONSTANT.POS[CONSTANT.COMMENT], comment })
    end

    if #update_it > 0 then
        table.insert(update_it, { '=', CONSTANT.POS[CONSTANT.UPDATED_AT], fiber.time64() })
    end

    if #update_it > 0 then
        tuple = space:update(id, update_it)
    end

    return tuple
end

function Module.delete(id)
    local space = box.space[CONSTANT.SPACE_NAME]

    local tuple = space:delete(id)

    return tuple
end

function Module.list(from, limit)
    local space = box.space[CONSTANT.SPACE_NAME]
    local index = space.index[CONSTANT.INDEX_BY_ID]

    return index:pairs({from}, {iterator = box.index.GT})
        :take(limit)
        :totable()
end

function Module.get_id(tuple)
    return tuple[CONSTANT.POS[CONSTANT.ID]]
end

function Module.get_num_from(tuple)
    local coord = tuple[CONSTANT.POS[CONSTANT.COORD]]
    return coord[2]
end

function Module.get_num_to(tuple)
    local coord = tuple[CONSTANT.POS[CONSTANT.COORD]]
    return coord[4]
end

function Module.get_is_active(tuple)
    local coord = tuple[CONSTANT.POS[CONSTANT.COORD]]
    return coord[1] == ACL_CONSTANT.ACTIVE
end

function Module.get_comment(tuple)
    return tuple[CONSTANT.POS[CONSTANT.COMMENT]]
end

function Module.get_created_at(tuple)
    return tuple[CONSTANT.POS[CONSTANT.CREATED_AT]]
end

function Module.get_updated_at(tuple)
    return tuple[CONSTANT.POS[CONSTANT.UPDATED_AT]]
end

function Module.to_table(tuple)
    return {
        id          = Module.get_id(tuple),
        num_from    = Module.get_num_from(tuple),
        num_to      = Module.get_num_to(tuple),
        is_active   = Module.get_is_active(tuple),
        comment     = Module.get_comment(tuple),
        created_at  = Module.get_created_at(tuple),
        updated_at  = Module.get_updated_at(tuple),
    }
end

return Module
