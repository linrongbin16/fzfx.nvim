-- :lua MiniTest.run_file()

local new_set = MiniTest.new_set
local expect = MiniTest.expect
local child = MiniTest.new_child_neovim()

local T = new_set({
    -- Register hooks
    hooks = {
        pre_case = function()
            child.restart({ "-u", "lua/tests/minimal_init.lua" })
            child.lua([[ require("lazy").install() ]])
            child.lua([[ M = require('fzfx.color') ]])
        end,
        -- This will be executed one after all tests from this set are finished
        post_once = child.stop,
    },
})

T["get_color"] = new_set()

local function test_ansi_color(msg, color)
    print(
        string.format(
            "%s, color(%s):%s, is string:%s",
            msg,
            type(color),
            vim.inspect(color),
            vim.inspect(type(color) == "string")
        )
    )
    expect.equality(type(color) == "string" or color == vim.NIL, true)
    if type(color) == "string" then
        expect.equality(tonumber(color) >= 0, true)
    end
end

T["get_color"]["fg"] = function()
    local special = child.lua_get([[ M.get_color("fg", "Special") ]])
    local normal = child.lua_get([[ M.get_color("fg", "Normal") ]])
    local linenr = child.lua_get([[ M.get_color("fg", "LineNr") ]])
    local tabline = child.lua_get([[ M.get_color("fg", "TabLine") ]])
    local exception = child.lua_get([[ M.get_color("fg", "Exception") ]])
    local comment = child.lua_get([[ M.get_color("fg", "Comment") ]])
    local label = child.lua_get([[ M.get_color("fg", "Label") ]])
    local string = child.lua_get([[ M.get_color("fg", "String") ]])
    test_ansi_color("fg special", special)
    test_ansi_color("fg normal", normal)
    test_ansi_color("fg linenr", linenr)
    test_ansi_color("fg tabline", tabline)
    test_ansi_color("fg exception", exception)
    test_ansi_color("fg comment", comment)
    test_ansi_color("fg label", label)
    test_ansi_color("fg string", string)
end

T["get_color"]["bg"] = function()
    local special = child.lua_get([[ M.get_color("bg", "Special") ]])
    local normal = child.lua_get([[ M.get_color("bg", "Normal") ]])
    local linenr = child.lua_get([[ M.get_color("bg", "LineNr") ]])
    local tabline = child.lua_get([[ M.get_color("bg", "TabLine") ]])
    local exception = child.lua_get([[ M.get_color("bg", "Exception") ]])
    local comment = child.lua_get([[ M.get_color("bg", "Comment") ]])
    local label = child.lua_get([[ M.get_color("bg", "Label") ]])
    local string = child.lua_get([[ M.get_color("bg", "String") ]])
    test_ansi_color("bg special", special)
    test_ansi_color("bg normal", normal)
    test_ansi_color("bg linenr", linenr)
    test_ansi_color("bg tabline", tabline)
    test_ansi_color("bg exception", exception)
    test_ansi_color("bg comment", comment)
    test_ansi_color("bg label", label)
    test_ansi_color("bg string", string)
end

return T
