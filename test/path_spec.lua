local cwd = vim.fn.getcwd()

describe("path", function()
    local assert_eq = assert.are.equal
    local assert_neq = assert.are_not.equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false
    local assert_truthy = assert.is.truthy
    local assert_falsy = assert.is.falsy

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local path = require("fzfx.path")
    describe("[normalize]", function()
        it("unix path remains the same", function()
            local expect1 = "~/github/linrongbin16/fzfx.nvim/lua/tests"
            local actual1 = path.normalize(expect1)
            local expect2 =
                "~/github/linrongbin16/fzfx.nvim/lua/tests/test_path.lua"
            local actual2 = path.normalize(expect2)
            assert_eq(actual1, expect1)
            assert_eq(actual2, expect2)
        end)
        it("windows path fix backslash", function()
            local actual1 = path.normalize(
                [[C:\Users\linrongbin\github\linrongbin16\fzfx.nvim\lua\tests]]
            )
            local expect1 =
                [[C:\Users\linrongbin\github\linrongbin16\fzfx.nvim\lua\tests]]
            assert_eq(actual1, expect1)
            local actual2 = path.normalize(
                [[C:\Users\linrongbin\github\linrongbin16\fzfx.nvim\lua\tests]],
                true
            )
            local expect2 =
                [[C:/Users/linrongbin/github/linrongbin16/fzfx.nvim/lua/tests]]
            assert_eq(actual2, expect2)
            local actual3 = path.normalize(
                [[C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\lua\\tests\test_path.lua]]
            )
            local expect3 =
                [[C:\Users\linrongbin\github\linrongbin16\fzfx.nvim\lua\tests\test_path.lua]]
            assert_eq(actual3, expect3)
            local actual4 = path.normalize(
                [[C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\lua\\tests\\test_path.lua]],
                true
            )
            local expect4 =
                [[C:/Users/linrongbin/github/linrongbin16/fzfx.nvim/lua/tests/test_path.lua]]
            assert_eq(actual4, expect4)
        end)
    end)
    describe("[join]", function()
        it("make path", function()
            local actual1 = path.join("a", "b", "c")
            local expect1 = "a/b/c"
            assert_eq(actual1, expect1)
            local actual2 = path.join("a")
            local expect2 = "a"
            assert_eq(actual2, expect2)
        end)
    end)
    describe("[base_dir]", function()
        it("make path with slash", function()
            local actual1 = path.base_dir()
            assert_eq(type(actual1), "string")
        end)
    end)
    describe("[shorten]", function()
        it("make shorter path based on home dir", function()
            local expect1 = "~/.config/nvim/lazy/fzfx.nvim/test/path_spec.lua"
            local actual1 = path.shorten(expect1)
            assert_eq(type(actual1), "string")
            assert_true(string.len(actual1) < string.len(expect1))
        end)
    end)
end)
