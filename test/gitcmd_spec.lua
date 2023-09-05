local cwd = vim.fn.getcwd()

describe("gitcmd", function()
    local assert_eq = assert.are.equal
    local assert_neq = assert.are_not.equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false
    local assert_truthy = assert.is.truthy
    local assert_falsy = assert.is.falsy

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local gitcmd = require("fzfx.gitcmd")
    describe("[GitRootCmd]", function()
        it("echo git root dir", function()
            local c = gitcmd.GitRootCmd:run()
            assert_eq(type(c), "table")
            assert_eq(type(c.result), "table")
            assert_eq(type(c.result.stdout), "table")
            assert_eq(#c.result.stdout, 1)
            print(string.format("git root:%s\n", c.result.stdout[1]))
            assert_true(string.len(c.result.stdout[1]) > 0)
        end)
    end)
end)
