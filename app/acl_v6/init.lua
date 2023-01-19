require('strict').on()

local fiber = require('fiber')

local CONSTANT = require('app.acl_v6.constant')
local ACL_CONSTANT = require('app.acl.constant')

local P2_MAX = 0xFFFFFFFFFFFFULL
local P3_MAX = 0xFFFFFFFFFFFFULL

local function u64_pair_to_triplet(u64_1, u64_2)
    local t1 = bit.rshift(bit.band(u64_1, 0xFFFFFFFF00000000ULL), 32)
    local t2 = bit.bor(
        bit.lshift(bit.band(u64_1, 0xFFFFFFFFULL), 16),
        bit.rshift(bit.band(u64_2, 0xFFFF000000000000ULL), 48)
    )
    local t3 = bit.band(u64_2, 0xFFFFFFFFFFFFULL)
    return t1, t2, t3
end

local function triplet_to_u64_pair(t1, t2, t3)
    local u64_1 = bit.bor(
        bit.lshift(t1, 32),
        bit.rshift(bit.band(t2, 0xFFFFFFFF0000ULL), 16)
    )
    local u64_2 = bit.bor(
        bit.lshift(bit.band(t2, 0xFFFFULL), 48),
        t3
    )
    return u64_1, u64_2
end

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

local function get_pk(tuple)
    return {Module.get_id(tuple), Module.get_sub_id(tuple)}
end

function Module.contains(num_p1, num_p2)
    local space = box.space[CONSTANT.SPACE_NAME]
    local index = space.index[CONSTANT.INDEX_BY_COORD]

    local p1, p2, p3 = u64_pair_to_triplet(num_p1, num_p2)

    -- Iterator GE searches for tuples with a specified rectangle within their rectangles
    local found = index:select({ACL_CONSTANT.ACTIVE, p1, p2, p3}, {
        iterator = box.index.GE,
        limit    = 1,
    })

    return #found > 0
end

function Module.create_records(active_value, num_p1_from, num_p2_from, num_p1_to, num_p2_to)
    -- we have to use triplets instead of u64 pairs because of
    -- rtrees limitations (does not support u64 max)
    local f1, f2, f3 = u64_pair_to_triplet(num_p1_from, num_p2_from)
    local t1, t2, t3 = u64_pair_to_triplet(num_p1_to,   num_p2_to)

    -- some examples:
    -- imagine we must create records for the following range: 0x123456 - 0x789abc
    -- we are going to split this range into 6 parts:
    -- (0x12, 0x34, 0x56) - (0x78, 0x9a, 0xbc)
    -- and create some records:
    --     (0x12, 0x34, 0x56) - (0x12, 0x34, 0xff)      -- mark F
    --     (0x12, 0x35, 0x00) - (0x12, 0xff, 0xff)      -- mark G
    --     (0x13, 0x00, 0x00) - (0x77, 0xff, 0xff)      -- mark J
    --     (0x78, 0x00, 0x00) - (0x78, 0x99, 0xff)      -- mark K
    --     (0x78, 0x9a, 0x00) - (0x78, 0x9a, 0xbc)      -- mark L
    local result = {}
    if f1 == t1 then
        if f2 == t2 then
            -- mark A
            table.insert(result, {
                active_value, f1, f2, f3,
                active_value, t1, t2, t3,
            })
        else
            -- mark B
            table.insert(result, {
                active_value, f1, f2, f3,
                active_value, f1, f2, P3_MAX,
            })
            if f2 + 1 == t2 then
                -- mark C
                table.insert(result, {
                    active_value, f1, t2, 0,
                    active_value, t1, t2, t3,
                })
            else
                if t2 > 0 then
                    -- mark D
                    table.insert(result, {
                        active_value, f1, f2 + 1, 0,
                        active_value, f1, t2 - 1, P3_MAX,
                    })
                end
                -- mark E
                table.insert(result, {
                    active_value, f1, t2, 0,
                    active_value, t1, t2, t3,
                })
            end
        end
    else
        -- mark F
        table.insert(result, {
            active_value, f1, f2, f3,
            active_value, f1, f2, P3_MAX,
        })
        -- mark G
        table.insert(result, {
            active_value, f1, f2 + 1, 0,
            active_value, f1, P2_MAX, P3_MAX,
        })
        if f1 + 1 == t1 then
            if t2 > 0 then
                -- mark H
                table.insert(result, {
                    active_value, t1, 0, 0,
                    active_value, t1, t2 - 1, P3_MAX,
                })
            end

            -- mark I
            table.insert(result, {
                active_value, t1, t2, 0,
                active_value, t1, t2, t3,
            })
        else
            if t1 > 0 then
                -- mark J
                table.insert(result, {
                    active_value, f1 + 1, 0, 0,
                    active_value, t1 - 1, P2_MAX, P3_MAX,
                })
            end

            if t2 > 0 then
                -- mark K
                table.insert(result, {
                    active_value, t1, 0, 0,
                    active_value, t1, t2 - 1, P3_MAX,
                })
            end

            -- mark L
            table.insert(result, {
                active_value, t1, t2, 0,
                active_value, t1, t2, t3,
            })
        end
    end

    return result
end

function Module.create(num_p1_from, num_p2_from, num_p1_to, num_p2_to, is_active, comment)
    local space = box.space[CONSTANT.SPACE_NAME]

    local now = fiber.time64()

    local max_tuple = space.index[CONSTANT.INDEX_BY_ID]:max()
    local max_id = 0
    if max_tuple ~= nil then
        max_id = Module.get_id(max_tuple)
    end

    local active_value = is_active and ACL_CONSTANT.ACTIVE or ACL_CONSTANT.INACTIVE

    local insert_it = Module.create_records(active_value, num_p1_from, num_p2_from, num_p1_to, num_p2_to)

    local tuples = {}

    for i, coord in pairs(insert_it) do
        local tuple = space:insert({
            [CONSTANT.POS[CONSTANT.ID]]         = max_id + 1,
            [CONSTANT.POS[CONSTANT.SUB_ID]]     = i,
            [CONSTANT.POS[CONSTANT.COORD]]      = coord,
            [CONSTANT.POS[CONSTANT.COMMENT]]    = comment,
            [CONSTANT.POS[CONSTANT.CREATED_AT]] = now,
            [CONSTANT.POS[CONSTANT.UPDATED_AT]] = now,
        })
        table.insert(tuples, tuple)
    end

    return tuples
end

function Module.get(id)
    local space = box.space[CONSTANT.SPACE_NAME]
    local index = space.index[CONSTANT.INDEX_BY_ID]

    local tuples = {}

    for _, tuple in index:pairs({id}, {iterator = box.index.EQ}) do
        table.insert(tuples, tuple)
    end

    if #tuples == 0 then
        return nil
    end

    return tuples
end

function Module.update(id, is_active, comment)
    local space = box.space[CONSTANT.SPACE_NAME]

    local tuples = Module.get(id)
    if tuples == nil then
        return nil
    end

    local active_value = is_active and ACL_CONSTANT.ACTIVE or ACL_CONSTANT.INACTIVE

    local result = {}

    for _, tuple in pairs(tuples) do
        local update_it = {}

        local pk = get_pk(tuple)
        if Module.get_is_active(tuple) ~= is_active then
            table.insert(update_it, { '=', CONSTANT.POS[CONSTANT.COORD], {
                active_value,
                Module.get_num_from_p1(tuple),
                Module.get_num_from_p2(tuple),
                Module.get_num_from_p3(tuple),
                active_value,
                Module.get_num_to_p1(tuple),
                Module.get_num_to_p2(tuple),
                Module.get_num_to_p3(tuple),
            }})
        end

        if Module.get_comment(tuple) ~= comment then
            table.insert(update_it, { '=', CONSTANT.POS[CONSTANT.COMMENT], comment })
        end

        if #update_it > 0 then
            table.insert(update_it, { '=', CONSTANT.POS[CONSTANT.UPDATED_AT], fiber.time64() })
        end

        if #update_it > 0 then
            table.insert(result, space:update(pk, update_it))
        else
            table.insert(result, tuple)
        end
    end

    return result
end

function Module.list(from, limit)
    local space = box.space[CONSTANT.SPACE_NAME]
    local index = space.index[CONSTANT.INDEX_BY_ID]

    local result = {}
    local tuples = {}

    local cnt = 0
    local last_id = -1
    for _, tuple in index:pairs({from}, {iterator = box.index.GT}) do
        local id = Module.get_id(tuple)
        if id ~= last_id then
            last_id = id
            cnt = cnt + 1

            if #tuples > 0 then
                table.insert(result, tuples)
                tuples = {}
            end
        end

        if cnt > limit then
            break
        end

        table.insert(tuples, tuple)
    end

    if #tuples > 0 then
        table.insert(result, tuples)
    end

    return result
end

function Module.delete(id)
    local space = box.space[CONSTANT.SPACE_NAME]
    local index = space.index[CONSTANT.INDEX_BY_ID]

    local tuples = {}
    for _, tuple in index:pairs({id}, {iterator = box.index.EQ}) do
        table.insert(tuples, tuple)
    end

    for _, tuple in pairs(tuples) do
        space:delete(get_pk(tuple))
    end

    if #tuples == 0 then
        return nil
    end

    return tuples
end

function Module.get_id(tuple)
    return tuple[CONSTANT.POS[CONSTANT.ID]]
end

function Module.get_sub_id(tuple)
    return tuple[CONSTANT.POS[CONSTANT.SUB_ID]]
end

function Module.get_is_active(tuple)
    local coord = tuple[CONSTANT.POS[CONSTANT.COORD]]
    return coord[1] == ACL_CONSTANT.ACTIVE
end

function Module.get_num_from_p1(tuple)
    local coord = tuple[CONSTANT.POS[CONSTANT.COORD]]
    return coord[2]
end

function Module.get_num_from_p2(tuple)
    local coord = tuple[CONSTANT.POS[CONSTANT.COORD]]
    return coord[3]
end

function Module.get_num_from_p3(tuple)
    local coord = tuple[CONSTANT.POS[CONSTANT.COORD]]
    return coord[4]
end

function Module.get_num_to_p1(tuple)
    local coord = tuple[CONSTANT.POS[CONSTANT.COORD]]
    return coord[6]
end

function Module.get_num_to_p2(tuple)
    local coord = tuple[CONSTANT.POS[CONSTANT.COORD]]
    return coord[7]
end

function Module.get_num_to_p3(tuple)
    local coord = tuple[CONSTANT.POS[CONSTANT.COORD]]
    return coord[8]
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

function Module.to_table(tuples)
    local first_tuple = tuples[1]
    local last_tuple = tuples[#tuples]

    local f1 = Module.get_num_from_p1(first_tuple)
    local f2 = Module.get_num_from_p2(first_tuple)
    local f3 = Module.get_num_from_p3(first_tuple)

    local t1 = Module.get_num_to_p1(last_tuple)
    local t2 = Module.get_num_to_p2(last_tuple)
    local t3 = Module.get_num_to_p3(last_tuple)

    local num_from_p1, num_from_p2 = triplet_to_u64_pair(f1, f2, f3)
    local num_to_p1,   num_to_p2   = triplet_to_u64_pair(t1, t2, t3)

    return {
        id          = Module.get_id(first_tuple),
        is_active   = Module.get_is_active(first_tuple),
        num_from_p1 = num_from_p1,
        num_from_p2 = num_from_p2,
        num_to_p1   = num_to_p1,
        num_to_p2   = num_to_p2,
        comment     = Module.get_comment(first_tuple),
        created_at  = Module.get_created_at(first_tuple),
        updated_at  = Module.get_updated_at(first_tuple),
    }
end

return Module