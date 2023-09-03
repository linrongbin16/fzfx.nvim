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
            [[ M.normalize("%s", true) ]],
            vim.fn.escape(
                [[C:\Users\linrongbin\github\linrongbin16\fzfx.nvim\lua\tests]],
                "\\"
            )
        )
    )
    local file1 =
        [[C:\Users\linrongbin\github\linrongbin16\fzfx.nvim\lua\tests\test_path.lua]]
    local file2 = child.lua_get(
        string.format(
            [[ M.normalize("%s") ]],
            vim.fn.escape(
                [[C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\lua\\tests\\test_path.lua]],
                "\\"
            )
        )
    )
    add_note(string.format("%s == %s", dir1, dir2))
    expect.equality(dir2, dir1)
    add_note(string.format("%s == %s", file1, file2))
    expect.equality(file2, file1)
end

T["path_separator"] = new_set()

T["path_separator"]["default"] = function()
    local actual = child.lua_get([[ require("fzfx.constants").path_separator ]])
    if vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0 then
        expect.equality(actual, "\\")
    else
        expect.equality(actual, "/")
    end
end

T["join"] = new_set()

T["join"]["default"] = function()
    local expect1 = "bin/files/provider.lua"
    local actual1 = child.lua_get([[ M.join("bin", "files", "provider.lua") ]])
    add_note(string.format("%s == %s", expect1, actual1))
    local expect2 = "files/provider.lua"
    local actual2 = child.lua_get([[ M.join("files", "provider.lua") ]])
    add_note(string.format("%s == %s", expect2, actual2))
    local expect3 = "provider.lua"
    local actual3 = child.lua_get([[ M.join("provider.lua") ]])
    add_note(string.format("%s == %s", expect3, actual3))
end

T["base_dir"] = new_set()

T["base_dir"]["base_dir"] = function()
    local actual = child.lua_get([[ M.base_dir() ]])
    add_note(string.format("base dir: %s", actual))
    expect.equality(vim.fn.expand("~/github/linrongbin16/fzfx.nvim"), actual)
end

return T
