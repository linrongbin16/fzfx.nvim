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

local hlgroups = {
    "Special",
    "Normal",
    "LineNr",
    "TabLine",
    "Exception",
    "Comment",
    "Label",
    "String",
}

T["get_color"]["fg"] = function()
    for _, g in ipairs(hlgroups) do
        local color =
            child.lua_get(string.format([[ M.get_color("fg", "%s") ]], g))
        test_ansi_color("fg " .. g, color)
    end
end

T["get_color"]["bg"] = function()
    for _, g in ipairs(hlgroups) do
        local color =
            child.lua_get(string.format([[ M.get_color("fg", "%s") ]], g))
        test_ansi_color("bg " .. g, color)
    end
end

return T
