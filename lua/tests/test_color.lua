-- :lua MiniTest.run_file()

local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

T["get_color"] = new_set()

local function test_rgbcolor(color)
    expect.equality(type(color) == "string" or color == nil, true)
    if type(color) == "string" then
        local r, g, b = color:match("#(..)(..)(..)")
        expect.equality(type(r), "string")
        expect.equality(tonumber(r) > 0, true)
        expect.equality(type(g), "string")
        expect.equality(tonumber(g) > 0, true)
        expect.equality(type(b), "string")
        expect.equality(tonumber(b) > 0, true)
    end
end

T["get_color"]["fg"] = function()
    local M = require("fzfx.color")
    local special = M.get_color("fg", "Special")
    local normal = M.get_color("fg", "Normal")
    local linenr = M.get_color("fg", "LineNr")
    local tabline = M.get_color("fg", "TabLine")
    local exception = M.get_color("fg", "Exception")
    local comment = M.get_color("fg", "Comment")
    local label = M.get_color("fg", "Label")
    local string = M.get_color("fg", "String")
    test_rgbcolor(special)
    test_rgbcolor(normal)
    test_rgbcolor(linenr)
    test_rgbcolor(tabline)
    test_rgbcolor(exception)
    test_rgbcolor(comment)
    test_rgbcolor(label)
    test_rgbcolor(string)
end

T["get_color"]["bg"] = function()
    local M = require("fzfx.color")
    local special = M.get_color("bg", "Special")
    local normal = M.get_color("bg", "Normal")
    local linenr = M.get_color("bg", "LineNr")
    local tabline = M.get_color("bg", "TabLine")
    local exception = M.get_color("bg", "Exception")
    local comment = M.get_color("bg", "Comment")
    local label = M.get_color("bg", "Label")
    local string = M.get_color("bg", "String")
    test_rgbcolor(special)
    test_rgbcolor(normal)
    test_rgbcolor(linenr)
    test_rgbcolor(tabline)
    test_rgbcolor(exception)
    test_rgbcolor(comment)
    test_rgbcolor(label)
    test_rgbcolor(string)
end

return T
