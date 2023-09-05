local cwd = vim.fn.getcwd()

describe("cmd", function()
    local assert_eq = assert.are.equal
    local assert_neq = assert.are_not.equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false
    local assert_truthy = assert.is.truthy
    local assert_falsy = assert.is.falsy

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local Cmd = require("fzfx.cmd").Cmd
    describe("[Cmd]", function()
        it("echo without opts", function()
            local c = Cmd:run("echo 1")
            assert_eq(type(c), "table")
            assert_eq(type(c.result), "table")
            assert_eq(type(c.result.stdout), "table")
            assert_eq(#c.result.stdout, 1)
            assert_eq(c.result.stdout[1], "1")
            assert_eq(type(c.result.stderr), "table")
            assert_eq(#c.result.stderr, 0)
            assert_eq(c.result.exitcode, 0)
        end)
    end)
end)
