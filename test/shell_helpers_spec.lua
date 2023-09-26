local cwd = vim.fn.getcwd()

describe("shell_helpers", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local shell_helpers = require("fzfx.shell_helpers")
    vim.env._FZFX_NVIM_DEVICONS_PATH = nil
    describe("[is_windows]", function()
        it("is windows", function()
            assert_eq(type(shell_helpers.is_windows), "boolean")
        end)
    end)
    describe("[log]", function()
        it("debug", function()
            assert_true(shell_helpers.log_debug("logs without params") == nil)
            assert_true(
                shell_helpers.log_debug("logs with params 1, %d", 1) == nil
            )
            assert_true(
                shell_helpers.log_debug("logs with params 2, %d, %s", 1, "asdf")
                    == nil
            )
        end)
        it("err", function()
            assert_true(shell_helpers.log_err("logs without params") == nil)
            assert_true(
                shell_helpers.log_err("logs with params 1, %d", 1) == nil
            )
            assert_true(
                shell_helpers.log_err("logs with params 2, %d, %s", 1, "asdf")
                    == nil
            )
        end)
        it("ensure", function()
            assert_true(
                shell_helpers.log_ensure(true, "logs without params") == nil
            )
            local ok, err = pcall(
                shell_helpers.log_ensure,
                false,
                "logs with params 1, %d",
                1
            )
            assert_false(ok)
            assert_eq(type(err), "string")
            assert_true(string.len(err --[[@as string]]) > 0)
        end)
        it("throw", function()
            local ok, err =
                pcall(shell_helpers.log_throw, "logs with params 1, %d", 1)
            assert_false(ok)
            assert_eq(type(err), "string")
            assert_true(string.len(err --[[@as string]]) > 0)
        end)
    end)
end)
