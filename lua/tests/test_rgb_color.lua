-- :lua MiniTest.run_file()

local new_set = MiniTest.new_set
local expect = MiniTest.expect
local child = MiniTest.new_child_neovim()

local T = new_set({
    -- Register hooks
    hooks = {
        pre_case = function()
            child.restart({ "-u", "lua/tests/minimal_termguicolors_init.lua" })
            child.lua([[ require("lazy").install() ]])
            child.lua([[ M = require('fzfx.color') ]])
        end,
        -- This will be executed one after all tests from this set are finished
        post_once = child.stop,
    },
})

T["get_color"] = new_set()

local function test_rgb_color(color)
    expect.equality(type(color) == "string", true)
    local r, g, b = color:match("#(..)(..)(..)")
    print(
        string.format(
            "color:%s, r:%s, g:%s, b:%s",
            vim.inspect(color),
            vim.inspect(r),
            vim.inspect(g),
            vim.inspect(b)
        )
    )
    expect.equality(type(r), "string")
    expect.equality(tonumber(r) > 0, true)
    expect.equality(type(g), "string")
    expect.equality(tonumber(g) > 0, true)
    expect.equality(type(b), "string")
    expect.equality(tonumber(b) > 0, true)
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
    test_rgb_color(special)
    test_rgb_color(normal)
    test_rgb_color(linenr)
    test_rgb_color(tabline)
    test_rgb_color(exception)
    test_rgb_color(comment)
    test_rgb_color(label)
    test_rgb_color(string)
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
    test_rgb_color(special)
    test_rgb_color(normal)
    test_rgb_color(linenr)
    test_rgb_color(tabline)
    test_rgb_color(exception)
    test_rgb_color(comment)
    test_rgb_color(label)
    test_rgb_color(string)
end

return T
