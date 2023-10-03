local cwd = vim.fn.getcwd()

describe("cmd", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local CmdResult = require("fzfx.cmd").CmdResult
    local cmd = require("fzfx.cmd")
    local utils = require("fzfx.utils")
    describe("[CmdResult]", function()
        it("new result is empty", function()
            local cr = CmdResult:new()
            assert_true(vim.tbl_isempty(cr.stdout))
            assert_true(vim.tbl_isempty(cr.stderr))
            assert_true(cr.code == nil)
        end)
        it("new result is not wrong", function()
            local cr = CmdResult:new()
            assert_false(cr:wrong())
        end)
    end)
    describe("[Cmd]", function()
        it("echo", function()
            local Cmd = require("fzfx.cmd").Cmd
            local c = Cmd:run("echo 1")
            assert_eq(type(c), "table")
            assert_eq(type(c.result), "table")
            assert_eq(type(c.result.stdout), "table")
            assert_eq(#c.result.stdout, 1)
            assert_eq(c.result.stdout[1], "1")
            assert_eq(type(c.result.stderr), "table")
            assert_eq(#c.result.stderr, 0)
            assert_eq(c.result.code, 0)
            assert_false(c:wrong())
            assert_false(c.result:wrong())
        end)
    end)
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
            local async_spawn = cmd.AsyncCmd:open(
                { "cat", "README.md" },
                function(line) end
            ) --[[@as AsyncCmd]]
            assert_eq(type(async_spawn), "table")
            assert_eq(type(async_spawn.cmd), "table")
            assert_eq(#async_spawn.cmd, 2)
            assert_eq(async_spawn.cmd[1], "cat")
            assert_eq(async_spawn.cmd[2], "README.md")
            assert_eq(type(async_spawn.out_pipe), "userdata")
            assert_eq(type(async_spawn.err_pipe), "userdata")
        end)
        it("consume line", function()
            local content = utils.readfile("README.md") --[[@as string]]
            local lines = utils.readlines("README.md") --[[@as table]]

            local i = 1
            local function process_line(line)
                -- print(string.format("[%d]%s", i, line))
                assert_eq(type(line), "string")
                assert_eq(line, lines[i])
                i = i + 1
            end
            local async_spawn =
                cmd.AsyncCmd:open({ "cat", "README.md" }, process_line) --[[@as AsyncCmd]]
            local pos = async_spawn:consume_line(content, process_line)
            if pos <= #content then
                local line = content:sub(pos, #content)
                process_line(line)
            end
        end)
        it("exit", function()
            local async_spawn = cmd.AsyncCmd:open(
                { "cat", "README.md" },
                function(line) end,
                {
                    on_exit = function(code, signal)
                        assert_eq(code, 0)
                        assert_eq(signal, 0)
                    end,
                }
            ) --[[@as AsyncCmd]]
            async_spawn:on_exit(0, 0)
        end)
        it("stdout on newline", function()
            local content = utils.readfile("README.md") --[[@as string]]
            local lines = utils.readlines("README.md") --[[@as table]]

            local i = 1
            local function process_line(line)
                -- print(string.format("[%d]%s\n", i, line))
                assert_eq(type(line), "string")
                assert_eq(line, lines[i])
                i = i + 1
            end
            local async_spawn =
                cmd.AsyncCmd:open({ "cat", "README.md" }, process_line) --[[@as AsyncCmd]]
            local content_splits =
                utils.string_split(content, "\n", { trimempty = false })
            for j, splits in ipairs(content_splits) do
                async_spawn:on_stdout(nil, splits)
                if j < #content_splits then
                    async_spawn:on_stdout(nil, "\n")
                end
            end
            async_spawn:on_stdout(nil, nil)
        end)
        it("stdout on whitespace", function()
            local content = utils.readfile("README.md") --[[@as string]]
            local lines = utils.readlines("README.md") --[[@as table]]

            local i = 1
            local function process_line(line)
                -- print(string.format("[%d]%s\n", i, line))
                assert_eq(type(line), "string")
                assert_eq(line, lines[i])
                i = i + 1
            end
            local async_spawn =
                cmd.AsyncCmd:open({ "cat", "README.md" }, process_line) --[[@as AsyncCmd]]
            local content_splits =
                utils.string_split(content, " ", { trimempty = false })
            for j, splits in ipairs(content_splits) do
                async_spawn:on_stdout(nil, splits)
                if j < #content_splits then
                    async_spawn:on_stdout(nil, " ")
                end
            end
            async_spawn:on_stdout(nil, nil)
        end)
        for delimiter_i = 0, 25 do
            -- lower case: a
            local lower_char = string.char(97 + delimiter_i)
            it(string.format("stdout on %s", lower_char), function()
                local content = utils.readfile("README.md") --[[@as string]]
                local lines = utils.readlines("README.md") --[[@as table]]

                local i = 1
                local function process_line(line)
                    -- print(string.format("[%d]%s\n", i, line))
                    assert_eq(type(line), "string")
                    assert_eq(line, lines[i])
                    i = i + 1
                end
                local async_spawn =
                    cmd.AsyncCmd:open({ "cat", "README.md" }, process_line) --[[@as AsyncCmd]]
                local content_splits = utils.string_split(
                    content,
                    lower_char,
                    { trimempty = false }
                )
                for j, splits in ipairs(content_splits) do
                    async_spawn:on_stdout(nil, splits)
                    if j < #content_splits then
                        async_spawn:on_stdout(nil, lower_char)
                    end
                end
                async_spawn:on_stdout(nil, nil)
            end)
            -- upper case: A
            local upper_char = string.char(65 + delimiter_i)
            it(string.format("stdout on %s", upper_char), function()
                local content = utils.readfile("README.md") --[[@as string]]
                local lines = utils.readlines("README.md") --[[@as table]]

                local i = 1
                local function process_line(line)
                    -- print(string.format("[%d]%s\n", i, line))
                    assert_eq(type(line), "string")
                    assert_eq(line, lines[i])
                    i = i + 1
                end
                local async_spawn =
                    cmd.AsyncCmd:open({ "cat", "README.md" }, process_line) --[[@as AsyncCmd]]
                local content_splits = utils.string_split(
                    content,
                    upper_char,
                    { trimempty = false }
                )
                for j, splits in ipairs(content_splits) do
                    async_spawn:on_stdout(nil, splits)
                    if j < #content_splits then
                        async_spawn:on_stdout(nil, upper_char)
                    end
                end
                async_spawn:on_stdout(nil, nil)
            end)
        end
        it("stderr", function()
            local async_spawn = cmd.AsyncCmd:open(
                { "cat", "README.md" },
                function() end
            ) --[[@as AsyncCmd]]
            async_spawn:on_stderr(nil, nil)
        end)
        it("iterate on README.md", function()
            local lines = utils.readlines("README.md") --[[@as table]]

            local i = 1
            local function process_line(line)
                print(string.format("[%d]%s\n", i, line))
                assert_eq(type(line), "string")
                assert_eq(lines[i], line)
                i = i + 1
            end

            local async_spawn =
                cmd.AsyncCmd:open({ "cat", "README.md" }, process_line) --[[@as AsyncCmd]]
            async_spawn:run()
        end)
        it("iterate on lua/fzfx/config.lua", function()
            local lines = utils.readlines("lua/fzfx/config.lua") --[[@as table]]

            local i = 1
            local function process_line(line)
                print(string.format("[%d]%s\n", i, line))
                assert_eq(type(line), "string")
                assert_eq(lines[i], line)
                i = i + 1
            end

            local async_spawn = cmd.AsyncCmd:open(
                { "cat", "lua/fzfx/config.lua" },
                process_line
            ) --[[@as AsyncCmd]]
            async_spawn:run()
        end)
    end)
end)
