local cwd = vim.fn.getcwd()

describe("notify", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local notify = require("fzfx.notify")
    local LogLevels = require("fzfx.notify").LogLevels
    local LogLevelNames = require("fzfx.notify").LogLevelNames
    describe("[NotifyLevels]", function()
        it("check levels", function()
            for k, v in pairs(LogLevels) do
                assert_eq(type(k), "string")
                assert_eq(type(v), "number")
            end
        end)
        it("check level names", function()
            for v, k in pairs(LogLevelNames) do
                assert_eq(type(k), "string")
                assert_eq(type(v), "number")
            end
        end)
    end)

    describe("[echo]", function()
        it("info", function()
            notify.echo(LogLevels.INFO, "echo without parameters")
            notify.echo(LogLevels.INFO, "echo with 1 parameters: %s", "a")
            notify.echo(
                LogLevels.INFO,
                "echo with 2 parameters: %s, %d",
                "a",
                1
            )
            notify.echo(
                LogLevels.INFO,
                "echo with 3 parameters: %s, %d, %f",
                "a",
                1,
                3.12
            )
            assert_true(true)
        end)
        it("debug", function()
            notify.echo(LogLevels.DEBUG, "echo without parameters")
            notify.echo(LogLevels.DEBUG, "echo with 1 parameters: %s", "a")
            notify.echo(
                LogLevels.DEBUG,
                "echo with 2 parameters: %s, %d",
                "a",
                1
            )
            notify.echo(
                LogLevels.DEBUG,
                "echo with 3 parameters: %s, %d, %f",
                "a",
                1,
                3.12
            )
            assert_true(true)
        end)
        it("warn", function()
            notify.echo(LogLevels.WARN, "echo without parameters")
            notify.echo(LogLevels.WARN, "echo with 1 parameters: %s", "a")
            notify.echo(
                LogLevels.WARN,
                "echo with 2 parameters: %s, %d",
                "a",
                1
            )
            notify.echo(
                LogLevels.WARN,
                "echo with 3 parameters: %s, %d, %f",
                "a",
                1,
                3.12
            )
            assert_true(true)
        end)
        it("err", function()
            notify.echo(LogLevels.ERROR, "echo without parameters")
            notify.echo(LogLevels.ERROR, "echo with 1 parameters: %s", "a")
            notify.echo(
                LogLevels.ERROR,
                "echo with 2 parameters: %s, %d",
                "a",
                1
            )
            notify.echo(
                LogLevels.ERROR,
                "echo with 3 parameters: %s, %d, %f",
                "a",
                1,
                3.12
            )
            assert_true(true)
        end)
    end)
end)
