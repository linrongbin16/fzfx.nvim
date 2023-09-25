local cwd = vim.fn.getcwd()

describe("cmd", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local CmdResult = require("fzfx.cmd").CmdResult
    local Cmd = require("fzfx.cmd").Cmd
    describe("[CmdResult]", function()
        it("new result is empty", function()
            local cr = CmdResult:new()
            assert_true(vim.tbl_isempty(cr.stdout))
            assert_true(vim.tbl_isempty(cr.stderr))
            assert_true(cr.exitcode == nil)
        end)
        it("new result is not wrong", function()
            local cr = CmdResult:new()
            assert_false(cr:wrong())
        end)
    end)
    describe("[Cmd]", function()
        it("echo", function()
            local c = Cmd:run("echo 1")
            assert_eq(type(c), "table")
            assert_eq(type(c.result), "table")
            assert_eq(type(c.result.stdout), "table")
            assert_eq(#c.result.stdout, 1)
            assert_eq(c.result.stdout[1], "1")
            assert_eq(type(c.result.stderr), "table")
            assert_eq(#c.result.stderr, 0)
            assert_eq(c.result.exitcode, 0)
            assert_false(c:wrong())
            assert_false(c.result:wrong())
        end)
    end)
    local cmd = require("fzfx.cmd")
    describe("[GitRootCmd]", function()
        it("print git repo root", function()
            local c = cmd.GitRootCmd:run()
            assert_eq(type(c), "table")
            assert_eq(type(c.result), "table")
            assert_eq(type(c.result.stdout), "table")
            assert_eq(#c.result.stdout, 1)
            assert_false(c:wrong())
            assert_eq(type(c:value()), "string")
            print(string.format("git root:%s\n", c:value()))
            assert_true(string.len(c:value() --[[@as string]]) > 0)
        end)
    end)
    describe("[GitBranchCmd]", function()
        it("echo git branches", function()
            local c = cmd.GitBranchCmd:run()
            assert_eq(type(c), "table")
            assert_eq(type(c.result), "table")
            assert_eq(type(c.result.stdout), "table")
            assert_true(#c.result.stdout > 0)
            assert_false(c:wrong())
            assert_eq(type(c:value()), "table")
            print(string.format("git branches:%s\n", vim.inspect(c:value())))
            assert_true(#c:value() > 0)
            assert_true(string.len(c:value()[1]) > 0)
        end)
    end)
    describe("[GitCurrentBranchCmd]", function()
        it("echo git current branch", function()
            local c = cmd.GitCurrentBranchCmd:run()
            assert_eq(type(c), "table")
            assert_eq(type(c.result), "table")
            assert_eq(type(c.result.stdout), "table")
            assert_eq(#c.result.stdout, 1)
            assert_false(c:wrong())
            assert_eq(type(c:value()), "string")
            print(string.format("git current branch:%s\n", c:value()))
            assert_true(string.len(c:value() --[[@as string]]) > 0)
        end)
    end)
    describe("[AsyncCmd]", function()
        it("open", function()
            local function line_consumer(line)
                assert_eq(type(line), "string")
                assert_eq(line, "1")
            end
            local c = cmd.AsyncCmd:open({ "echo", "1" }, line_consumer) --[[@as AsyncCmd]]
            assert_true(c ~= nil)
        end)
        it("echo README.md", function()
            local utils = require("fzfx.utils")
            local lines = utils.readlines("README.md") --[[@as table]]
            local content = utils.readfile("README.md")
            local i = 1
            local function line_consumer(line)
                print(string.format("[%d]%s", i, vim.inspect(line)))
                assert_eq(type(line), "string")
                assert_eq(lines[i], line)
                i = i + 1
            end
            local c = cmd.AsyncCmd:open({ "cat", "README.md" }, line_consumer) --[[@as AsyncCmd]]
            c:consume(content)
        end)
        it("echo lua/fzfx/config.lua", function()
            local utils = require("fzfx.utils")
            local lines = utils.readlines("lua/fzfx/config.lua") --[[@as table]]
            local content = utils.readfile("lua/fzfx/config.lua")
            local i = 1
            local function line_consumer(line)
                print(string.format("[%d]%s", i, vim.inspect(line)))
                assert_eq(type(line), "string")
                assert_eq(lines[i], line)
                i = i + 1
            end
            local c = cmd.AsyncCmd:open(
                { "cat", "lua/fzfx/config.lua" },
                line_consumer
            ) --[[@as AsyncCmd]]
            c:consume(content)
        end)
    end)
end)
