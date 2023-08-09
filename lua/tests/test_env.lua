-- :lua MiniTest.run_file()

local new_set = MiniTest.new_set
local expect = MiniTest.expect
local add_note = MiniTest.add_note
local child = MiniTest.new_child_neovim()

local T = new_set({
    -- Register hooks
    hooks = {
        pre_case = function()
            child.restart({ "-u", "lua/tests/minimal_termguicolors_init.lua" })
            child.lua([[ M = require('fzfx.env') ]])
        end,
        -- This will be executed one after all tests from this set are finished
        post_case = child.stop,
    },
})

T["debug"] = new_set()

T["debug"]["debug_disable"] = function()
    child.lua(
        [[ require('fzfx.env').setup({ debug = {enable = false}, icon = {enable = true} }) ]]
    )
    local actual = child.lua_get([[ M.debug_enable() ]])
    expect.equality(actual, false)
end

T["debug"]["debug_enable"] = function()
    child.lua(
        [[ require('fzfx.env').setup({ debug = {enable = true}, icon = {enable = true} }) ]]
    )
    local actual = child.lua_get([[ M.debug_enable() ]])
    expect.equality(actual, true)
end

T["icon"] = new_set()

T["icon"]["icon_disable"] = function()
    child.lua(
        [[ require('fzfx.env').setup({ debug = {enable = true}, icon = {enable = false} }) ]]
    )
    local actual = child.lua_get([[ M.icon_enable() ]])
    add_note(string.format("actual(%s):%s", type(actual), vim.inspect(actual)))
    expect.equality(actual, false)
end

T["icon"]["icon_enable"] = function()
    child.lua(
        [[ require('fzfx.env').setup({ debug = {enable = true}, icon = {enable = true} }) ]]
    )
    local actual = child.lua_get([[ M.icon_enable() ]])
    add_note(string.format("actual(%s):%s", type(actual), vim.inspect(actual)))
    expect.equality(actual, true)
end

return T
