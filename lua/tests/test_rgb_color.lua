-- :lua MiniTest.run_file()

local new_set = MiniTest.new_set
local expect = MiniTest.expect
local add_note = MiniTest.add_note
local child = MiniTest.new_child_neovim()

local T = new_set({
    -- Register hooks
    hooks = {
        pre_once = function()
            child.restart({ "-u", "lua/tests/minimal_termguicolors_init.lua" })
            child.lua([[ require("lazy").install() ]])
            child.lua([[ M = require('fzfx.color') ]])
        end,
        -- This will be executed one after all tests from this set are finished
        post_once = child.stop,
    },
})

T["get_color"] = new_set()

local function test_rgb_color(msg, color)
    add_note(
        string.format("%s, color(%s):%s", msg, type(color), vim.inspect(color))
    )
    expect.equality(type(color) == "string" or color == vim.NIL, true)
    if type(color) == "string" then
        local r, g, b = color:match("#(..)(..)(..)")
        expect.equality(type(r), "string")
        expect.equality(tonumber(r, 16) > 0, true)
        expect.equality(type(g), "string")
        expect.equality(tonumber(g, 16) > 0, true)
        expect.equality(type(b), "string")
        expect.equality(tonumber(b, 16) > 0, true)
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
        test_rgb_color("fg " .. g, color)
    end
end

T["get_color"]["bg"] = function()
    for _, g in ipairs(hlgroups) do
        local color =
            child.lua_get(string.format([[ M.get_color("fg", "%s") ]], g))
        test_rgb_color("bg " .. g, color)
    end
end

T["ansi"] = new_set()

local ansicolors = {
    black = "Comment",
    red = "Exception",
    green = "Label",
    yellow = "LineNr",
    blue = "TabLine",
    magenta = "Special",
    cyan = "String",
}

-- see: https://stackoverflow.com/a/55324681/4438921
local function test_ansi(msg, result)
    add_note(
        string.format(
            "%s result(%s):%s",
            msg,
            type(result),
            vim.inspect(result)
        )
    )
    expect.equality(type(result), "string")
    expect.equality(string.len(result) > 0, true)
    -- local i1, j1 = result:find("\x1b%[%d+m")
    -- expect.equality(i1 >= 1, true)
    -- expect.equality(j1 >= 1, true)
    local i1, j1 = result:find("\x1b%[[%d;]+%d+m")
    expect.equality(i1 ~= nil, true)
    expect.equality(j1 ~= nil, true)
    expect.equality(i1 >= 1, true)
    expect.equality(j1 >= 1, true)
    local i0, j0 = result:find("\x1b%[0m")
    expect.equality(i0 > 1, true)
    expect.equality(j0 > 1, true)
    expect.equality(i1 < i0, true)
    expect.equality(j1 < j0, true)
end

T["ansi"]["default"] = function()
    for c, g in pairs(ansicolors) do
        local result = child.lua_get(
            string.format([[ M.ansi("default", "%s", "%s") ]], c, g)
        )
        test_ansi("default " .. c .. " " .. g, result)
    end
end

return T
