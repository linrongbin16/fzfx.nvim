-- :lua MiniTest.run_file()

local function hello()
    return "hello"
end

local T = MiniTest.new_set()
local expect = MiniTest.expect

T["hello"] = function()
    local h = hello()
    expect.equality(h, "hello")
end

return T
