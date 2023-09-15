local cwd = vim.fn.getcwd()

describe("log", function()
    local assert_eq = assert.are.equal
    local assert_neq = assert.are_not.equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false
    local assert_truthy = assert.is.truthy
    local assert_falsy = assert.is.falsy

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local log = require("fzfx.log")
    local LogLevel = require("fzfx.log").LogLevel
    log.setup({
        level = "DEBUG",
        console_log = true,
        file_log = true,
    })
    describe("[log]", function()
        it("echo", function()
            log.echo(LogLevel.INFO, "echo without parameters")
            log.echo(LogLevel.INFO, "echo with 1 parameters: %s", "a")
            log.echo(LogLevel.INFO, "echo with 2 parameters: %s, %d", "a", 1)
            log.echo(
                LogLevel.INFO,
                "echo with 3 parameters: %s, %d, %f",
                "a",
                1,
                3.12
            )
            assert_true(true)
        end)
        it("debug", function()
            log.debug("debug without parameters")
            log.debug("debug with 1 parameters: %s", "a")
            log.debug("debug with 2 parameters: %s, %d", "a", 1)
            log.debug("debug with 3 parameters: %s, %d, %f", "a", 1, 3.12)
            assert_true(true)
        end)
        it("info", function()
            log.info("info without parameters")
            log.info("info with 1 parameters: %s", "a")
            log.info("info with 2 parameters: %s, %d", "a", 1)
            log.info("info with 3 parameters: %s, %d, %f", "a", 1, 3.12)
            assert_true(true)
        end)
        it("warn", function()
            log.warn("warn without parameters")
            log.warn("warn with 1 parameters: %s", "a")
            log.warn("warn with 2 parameters: %s, %d", "a", 1)
            log.warn("warn with 3 parameters: %s, %d, %f", "a", 1, 3.12)
            assert_true(true)
        end)
        it("err", function()
            log.err("err without parameters")
            log.err("err with 1 parameters: %s", "a")
            log.err("err with 2 parameters: %s, %d", "a", 1)
            log.err("err with 3 parameters: %s, %d, %f", "a", 1, 3.12)
            assert_true(true)
        end)
        it("ensure", function()
            log.ensure(true, "ensure without parameters")
            log.ensure(true, "ensure with 1 parameters: %s", "a")
            log.ensure(true, "ensure with 2 parameters: %s, %d", "a", 1)
            log.ensure(
                true,
                "ensure with 3 parameters: %s, %d, %f",
                "a",
                1,
                3.12
            )
            assert_true(true)
            local ok1, err1 =
                pcall(log.ensure, false, "ensure without parameters")
            print(vim.inspect(err1) .. "\n")
            assert_false(ok1)
            local ok2, err2 =
                pcall(log.ensure, false, "ensure with 1 parameters: %s", "a")
            print(vim.inspect(err2) .. "\n")
            assert_false(ok2)
            local ok3, err3 = pcall(
                log.ensure,
                false,
                "ensure with 2 parameters: %s, %d",
                "a",
                1
            )
            print(vim.inspect(err3) .. "\n")
            assert_false(ok3)
            local ok4, err4 = pcall(
                log.ensure,
                false,
                "ensure with 3 parameters: %s, %d, %f",
                "a",
                1,
                3.12
            )
            print(vim.inspect(err4) .. "\n")
            assert_false(ok4)
        end)
    end)
end)
