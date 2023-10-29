local cwd = vim.fn.getcwd()

describe("utils", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local spawn = require("fzfx.spawn")
    local utils = require("fzfx.utils")

    describe("[Spawn]", function()
        it("open", function()
            local acmd = spawn.Spawn:make(
                { "cat", "README.md" },
                function() end
            ) --[[@as Spawn]]
            assert_eq(type(acmd), "table")
            assert_eq(type(acmd.cmds), "table")
            assert_eq(#acmd.cmds, 2)
            assert_eq(acmd.cmds[1], "cat")
            assert_eq(acmd.cmds[2], "README.md")
            assert_eq(type(acmd.out_pipe), "userdata")
            assert_eq(type(acmd.err_pipe), "userdata")
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
            local acmd = spawn.Spawn:make({ "cat", "README.md" }, process_line) --[[@as Spawn]]
            local pos = acmd:_consume_line(content, process_line)
            if pos <= #content then
                local line = content:sub(pos, #content)
                process_line(line)
            end
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
            local acmd = spawn.Spawn:make({ "cat", "README.md" }, process_line) --[[@as Spawn]]
            local content_splits =
                utils.string_split(content, "\n", { trimempty = false })
            for j, splits in ipairs(content_splits) do
                acmd:_on_stdout(nil, splits)
                if j < #content_splits then
                    acmd:_on_stdout(nil, "\n")
                end
            end
            acmd:_on_stdout(nil, nil)
            assert_true(acmd.out_pipe:is_closing())
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
            local acmd = spawn.Spawn:make({ "cat", "README.md" }, process_line) --[[@as Spawn]]
            local content_splits =
                utils.string_split(content, " ", { trimempty = false })
            for j, splits in ipairs(content_splits) do
                acmd:_on_stdout(nil, splits)
                if j < #content_splits then
                    acmd:_on_stdout(nil, " ")
                end
            end
            acmd:_on_stdout(nil, nil)
            assert_true(acmd.out_pipe:is_closing())
        end)
        local delimiter_i = 0
        while delimiter_i <= 25 do
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
                local acmd =
                    spawn.Spawn:make({ "cat", "README.md" }, process_line) --[[@as Spawn]]
                local content_splits = utils.string_split(
                    content,
                    lower_char,
                    { trimempty = false }
                )
                for j, splits in ipairs(content_splits) do
                    acmd:_on_stdout(nil, splits)
                    if j < #content_splits then
                        acmd:_on_stdout(nil, lower_char)
                    end
                end
                acmd:_on_stdout(nil, nil)
                assert_true(acmd.out_pipe:is_closing())
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
                local acmd =
                    spawn.Spawn:make({ "cat", "README.md" }, process_line) --[[@as Spawn]]
                local content_splits = utils.string_split(
                    content,
                    upper_char,
                    { trimempty = false }
                )
                for j, splits in ipairs(content_splits) do
                    acmd:_on_stdout(nil, splits)
                    if j < #content_splits then
                        acmd:_on_stdout(nil, upper_char)
                    end
                end
                acmd:_on_stdout(nil, nil)
                assert_true(acmd.out_pipe:is_closing())
            end)
            delimiter_i = delimiter_i + math.random(1, 5)
        end
        it("stderr", function()
            local acmd = spawn.Spawn:make(
                { "cat", "README.md" },
                function() end
            ) --[[@as Spawn]]
            acmd:_on_stderr(nil, nil)
            assert_true(acmd.err_pipe:is_closing())
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

            local acmd = spawn.Spawn:make({ "cat", "README.md" }, process_line) --[[@as Spawn]]
            acmd:run()
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

            local acmd =
                spawn.Spawn:make({ "cat", "lua/fzfx/config.lua" }, process_line) --[[@as Spawn]]
            acmd:run()
        end)
        it("close handle", function()
            local acmd = spawn.Spawn:make(
                { "cat", "lua/fzfx/config.lua" },
                function() end
            ) --[[@as Spawn]]
            acmd:run()
            assert_true(acmd.process_handle ~= nil)
            acmd:_close_handle(acmd.process_handle)
            assert_true(acmd.process_handle:is_closing())
        end)
    end)
end)
