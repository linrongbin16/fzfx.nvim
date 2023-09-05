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
        it("print git repo root", function()
            local c = gitcmd.GitRootCmd:run()
            assert_eq(type(c), "table")
            assert_eq(type(c.result), "table")
            assert_eq(type(c.result.stdout), "table")
            assert_eq(#c.result.stdout, 1)
            print(string.format("git root:%s\n", c.result.stdout[1]))
            assert_true(string.len(c.result.stdout[1]) > 0)
        end)
    end)
    describe("[GitBranchCmd]", function()
        it("echo git branches", function()
            local c = gitcmd.GitBranchCmd:run()
            assert_eq(type(c), "table")
            assert_eq(type(c.result), "table")
            assert_eq(type(c.result.stdout), "table")
            assert_true(#c.result.stdout > 0)
            print(
                string.format("git branches:%s\n", vim.inspect(c.result.stdout))
            )
            assert_true(string.len(c.result.stdout[1]) > 0)
        end)
    end)
    describe("[GitCurrentBranchCmd]", function()
        it("echo git current branch", function()
            local c = gitcmd.GitCurrentBranchCmd:run()
            assert_eq(type(c), "table")
            assert_eq(type(c.result), "table")
            assert_eq(type(c.result.stdout), "table")
            assert_eq(#c.result.stdout, 1)
            print(
                string.format(
                    "git current branch:%s\n",
                    vim.inspect(c.result.stdout)
                )
            )
            assert_true(string.len(c.result.stdout[1]) > 0)
        end)
    end)
end)
