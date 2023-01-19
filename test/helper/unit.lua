require('strict').on()

local fio = require('fio')

local t = require('luatest')

local helper = require('test.helper.common')

t.before_suite(function()
    fio.rmtree(helper.datadir)
    fio.mktree(helper.datadir)
    box.cfg({work_dir = helper.datadir})
end)

return helper
