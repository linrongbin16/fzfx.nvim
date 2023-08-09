-- :lua MiniTest.run_file()

local new_set = MiniTest.new_set
local expect = MiniTest.expect
local add_note = MiniTest.add_note
local child = MiniTest.new_child_neovim()

local T = new_set({
    hooks = {
        pre_once = function()
            child.restart({ "-u", "lua/tests/minimal_termguicolors_init.lua" })
            child.lua([[ M = require('fzfx.path') ]])
        end,
        post_once = child.stop,
    },
})

T["normalize"] = new_set()

T["normalize"]["unix"] = function()
    local dir1 = "~/github/linrongbin16/fzfx.nvim/lua/tests"
    local dir2 = child.lua_get(string.format([[ M.normalize("%s") ]], dir1))
    local file1 = "~/github/linrongbin16/fzfx.nvim/lua/tests/test_path.lua"
    local file2 = child.lua_get(string.format([[ M.normalize("%s") ]], file1))
    add_note(string.format("%s == %s", dir1, dir2))
    expect.equality(dir2, dir1)
    add_note(string.format("%s == %s", file1, file2))
    expect.equality(file2, file1)
end

T["normalize"]["windows"] = function()
    local dir1 = [[C:/Users/linrongbin/github/linrongbin16/fzfx.nvim/lua/tests]]
    local dir2 = child.lua_get(
        string.format(
            [[ M.normalize("%s") ]],
            vim.fn.escape(
                [[C:\Users\linrongbin\github\linrongbin16\fzfx.nvim\lua\tests]],
                "\\"
            )
        )
    )
    local file1 =
        [[C:/Users/linrongbin/github/linrongbin16/fzfx.nvim/lua/tests/test_path.lua]]
    local file2 = child.lua_get(
        string.format(
            [[ M.normalize("%s") ]],
            vim.fn.escape(
                [[C:\Users\linrongbin\github\linrongbin16\fzfx.nvim\lua\tests\test_path.lua]],
                "\\"
            )
        )
    )
    add_note(string.format("%s == %s", dir1, dir2))
    expect.equality(dir2, dir1)
    add_note(string.format("%s == %s", file1, file2))
    expect.equality(file2, file1)
end

return T
