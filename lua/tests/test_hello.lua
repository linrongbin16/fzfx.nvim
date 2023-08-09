-- :lua MiniTest.run_file()

local new_set = MiniTest.new_set
local expect = MiniTest.expect
local child = MiniTest.new_child_neovim()

local T = new_set({
    -- Register hooks
    hooks = {
        -- This will be executed before every (even nested) case
        pre_once = function()
            -- Restart child process with custom 'init.lua' script
            child.restart({ "-u", "lua/tests/minimal_init.lua" })
            -- Load tested plugin
            child.lua([[M = require('fzfx.color')]])
        end,
        -- This will be executed one after all tests from this set are finished
        post_once = child.stop,
    },
})

T["hello"] = function()
    expect.equality(
        child.lua_get(
            [[ type(M.get_color('fg', 'Special')) == "string" or M.get_color('fg', 'Special') == nil ]]
        ),
        true
    )
end

return T
