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

local function test_rgb_color(msg, color)
    print(
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
    print(
        string.format(
            "%s result(%s):%s",
            msg,
            type(result),
            vim.inspect(result)
        )
    )
    expect.equality(type(result), "string")
    expect.equality(string.len(result) > 0, true)
    local i1, j1 = result:find("\x1b%[%d+m")
    expect.equality(i1 >= 1, true)
    expect.equality(j1 >= 1, true)
    local i2, j2 = result:find("\x1b%[%d+;%d+m")
    if i2 ~= nil and j2 ~= nil then
        expect.equality(i2 >= 1, true)
        expect.equality(j2 >= 1, true)
    end
    local i3, j3 = result:find("\x1b%[%d+;%d+;%d+m")
    if i3 ~= nil and j3 ~= nil then
        expect.equality(i3 >= 1, true)
        expect.equality(j3 >= 1, true)
    end
    local i4, j4 = result:find("\x1b%[0m")
    expect.equality(i4 > 1, true)
    expect.equality(j4 > 1, true)
    if i2 ~= nil and j2 ~= nil then
        expect.equality(i2 < i4, true)
        expect.equality(j2 < j4, true)
    end
    if i3 ~= nil and j3 ~= nil then
        expect.equality(i3 < i4, true)
        expect.equality(j3 < j4, true)
    end
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
