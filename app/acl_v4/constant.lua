require('strict').on()

local CONSTANT = {}

CONSTANT.SPACE_NAME = 'acl_v4'

CONSTANT.ID         = 'id'
CONSTANT.COORD      = 'coord'
CONSTANT.COMMENT    = 'comment'
CONSTANT.CREATED_AT = 'created_at'
CONSTANT.UPDATED_AT = 'updated_at'

CONSTANT.FORMAT = {
    { name = CONSTANT.ID,         type = 'unsigned' },
    { name = CONSTANT.COORD,      type = 'array'  },
    { name = CONSTANT.COMMENT,    type = 'string' },
    { name = CONSTANT.CREATED_AT, type = 'unsigned' },
    { name = CONSTANT.UPDATED_AT, type = 'unsigned' },
}

CONSTANT.POS = {}
for i, v in pairs(CONSTANT.FORMAT) do
    CONSTANT.POS[v.name] = i
end

CONSTANT.INDEX_BY_ID        = 'by_id'
CONSTANT.INDEX_BY_ID_FIELDS = { CONSTANT.ID }
CONSTANT.INDEX_BY_ID_UNIQUE = true
CONSTANT.INDEX_BY_ID_TYPE   = 'TREE'

CONSTANT.INDEX_BY_COORD           = 'by_coord'
CONSTANT.INDEX_BY_COORD_FIELDS    = { CONSTANT.COORD }
CONSTANT.INDEX_BY_COORD_UNIQUE    = false
CONSTANT.INDEX_BY_COORD_TYPE      = 'RTREE'
CONSTANT.INDEX_BY_COORD_DISTANCE  = 'manhattan'
CONSTANT.INDEX_BY_COORD_DIMENSION = 2

return CONSTANT