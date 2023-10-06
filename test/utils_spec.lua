local cwd = vim.fn.getcwd()

describe("utils", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local utils = require("fzfx.utils")
    local ShellOptsContext = require("fzfx.utils").ShellOptsContext
    local WindowOptsContext = require("fzfx.utils").WindowOptsContext
    local FileLineReader = require("fzfx.utils").FileLineReader
    describe("[get_buf_option/set_buf_option]", function()
        it("get buffer filetype", function()
            local ft = utils.get_buf_option(0, "filetype")
            print(
                string.format("filetype get buf option:%s\n", vim.inspect(ft))
            )
            assert_eq(type(ft), "string")
        end)
        it("set buffer filetype", function()
            utils.set_buf_option(0, "filetype", "lua")
            local ft = utils.get_buf_option(0, "filetype")
            print(
                string.format("filetype set buf option:%s\n", vim.inspect(ft))
            )
            assert_eq(ft, "lua")
        end)
    end)
    describe("[is_buf_valid]", function()
        it("is buffer valid", function()
            assert_false(utils.is_buf_valid())
            assert_false(utils.is_buf_valid(nil))
        end)
    end)
    describe("[get_win_option/set_win_option]", function()
        it("get windows spell", function()
            utils.set_win_option(0, "spell", true)
            local s = utils.get_win_option(0, "spell")
            print(string.format("spell get win option:%s\n", vim.inspect(s)))
            assert_eq(type(s), "boolean")
            assert_true(s)
        end)
        it("set windows spell", function()
            utils.set_win_option(0, "spell", false)
            local s = utils.get_win_option(0, "spell")
            print(string.format("spell set win option:%s\n", vim.inspect(s)))
            assert_false(s)
        end)
    end)
    describe("[string_empty/string_not_empty]", function()
        it("is empty", function()
            assert_true(utils.string_empty())
            assert_true(utils.string_empty(nil))
            assert_true(utils.string_empty(""))
            assert_false(utils.string_not_empty())
            assert_false(utils.string_not_empty(nil))
            assert_false(utils.string_not_empty(""))
        end)
        it("is not empty", function()
            assert_true(utils.string_not_empty(" "))
            assert_true(utils.string_not_empty(" asdf "))
            assert_false(utils.string_empty(" "))
            assert_false(utils.string_empty(" asdf "))
        end)
    end)
    describe("[string_find/string_rfind]", function()
        it("found", function()
            assert_eq(utils.string_find("abcdefg", "a"), 1)
            assert_eq(utils.string_find("abcdefg", "a", 1), 1)
            assert_eq(utils.string_find("abcdefg", "g"), 7)
            assert_eq(utils.string_find("abcdefg", "g", 1), 7)
            assert_eq(utils.string_find("abcdefg", "g", 7), 7)
        end)
        it("not found", function()
            assert_eq(utils.string_find("abcdefg", "a", 2), nil)
            assert_eq(utils.string_find("abcdefg", "a", 7), nil)
            assert_eq(utils.string_find("abcdefg", "g", 8), nil)
            assert_eq(utils.string_find("abcdefg", "g", 9), nil)
        end)
        it("reverse found", function()
            assert_eq(utils.string_rfind("abcdefg", "a"), 1)
            assert_eq(utils.string_rfind("abcdefg", "a", 1), 1)
            assert_eq(utils.string_rfind("abcdefg", "a", 7), 1)
            assert_eq(utils.string_rfind("abcdefg", "g"), 7)
            assert_eq(utils.string_rfind("abcdefg", "g", 7), 7)
        end)
        it("reverse not found", function()
            assert_eq(utils.string_rfind("abcdefg", "a", 0), nil)
            assert_eq(utils.string_rfind("abcdefg", "g", 1), nil)
            assert_eq(utils.string_rfind("abcdefg", "g", 6), nil)
        end)
    end)
    describe("[string_ltrim/string_rtrim]", function()
        it("trim left", function()
            assert_eq(utils.string_ltrim("asdf"), "asdf")
            assert_eq(utils.string_ltrim(" asdf"), "asdf")
            assert_eq(utils.string_ltrim(" \nasdf"), "asdf")
            assert_eq(utils.string_ltrim("\tasdf"), "asdf")
            assert_eq(utils.string_ltrim(" asdf  "), "asdf  ")
            assert_eq(utils.string_ltrim(" \nasdf\n"), "asdf\n")
            assert_eq(utils.string_ltrim("\tasdf\t"), "asdf\t")
        end)
        it("trim right", function()
            assert_eq(utils.string_rtrim("asdf"), "asdf")
            assert_eq(utils.string_rtrim(" asdf "), " asdf")
            assert_eq(utils.string_rtrim(" \nasdf"), " \nasdf")
            assert_eq(utils.string_rtrim(" \nasdf\n"), " \nasdf")
            assert_eq(utils.string_rtrim("\tasdf\t"), "\tasdf")
        end)
    end)
    describe("[string_split]", function()
        it("splits rg options-1", function()
            local actual = utils.string_split("-w -g *.md", " ")
            local expect = { "-w", "-g", "*.md" }
            assert_eq(#actual, #expect)
            for i, v in ipairs(actual) do
                assert_eq(v, expect[i])
            end
        end)
        it("splits rg options-2", function()
            local actual = utils.string_split("  -w -g *.md  ", " ")
            local expect = { "-w", "-g", "*.md" }
            assert_eq(#actual, #expect)
            for i, v in ipairs(actual) do
                assert_eq(v, expect[i])
            end
        end)
        it("splits rg options-3", function()
            local actual =
                utils.string_split("  -w -g *.md  ", " ", { trimempty = false })
            local expect = { "", "", "-w", "-g", "*.md", "", "" }
            -- print(string.format("splits rg3, actual:%s", vim.inspect(actual)))
            -- print(string.format("splits rg3, expect:%s", vim.inspect(expect)))
            assert_eq(#actual, #expect)
            for i, v in ipairs(actual) do
                assert_eq(v, expect[i])
            end
        end)
    end)
    describe("[number_bound]", function()
        it("bound left", function()
            assert_eq(utils.number_bound(1, 1, 2), 1)
            assert_eq(utils.number_bound(2, 1, 3), 2)
            assert_eq(utils.number_bound(3, 1, 4), 3)
            assert_eq(utils.number_bound(3, 2, 4), 3)
            assert_eq(utils.number_bound(3, 3, 4), 3)
            assert_eq(utils.number_bound(3, 4, 4), 4)
            assert_eq(utils.number_bound(nil, -10), -10)
        end)
        it("bound right", function()
            assert_eq(utils.number_bound(1, 1, 5), 1)
            assert_eq(utils.number_bound(2, 3, 6), 3)
            assert_eq(utils.number_bound(3, 5, 7), 5)
            assert_eq(utils.number_bound(3, 9, 8), 8)
            assert_eq(utils.number_bound(3, 10, 9), 9)
            assert_eq(utils.number_bound(3, 15, 10), 10)
            assert_eq(utils.number_bound(3, 15), 15)
        end)
    end)
    describe("[ShellOptsContext]", function()
        it("save", function()
            local ctx = ShellOptsContext:save()
            assert_eq(type(ctx), "table")
            assert_false(vim.tbl_isempty(ctx))
            assert_true(ctx.shell ~= nil)
        end)
        it("restore", function()
            local ctx = ShellOptsContext:save()
            assert_eq(type(ctx), "table")
            assert_false(vim.tbl_isempty(ctx))
            assert_true(ctx.shell ~= nil)
            ctx:restore()
        end)
    end)
    describe("[WindowOptsContext]", function()
        it("save", function()
            local ctx = WindowOptsContext:save()
            assert_eq(type(ctx), "table")
            assert_false(vim.tbl_isempty(ctx))
            assert_true(ctx.bufnr ~= nil)
        end)
        it("restore", function()
            local ctx = WindowOptsContext:save()
            assert_eq(type(ctx), "table")
            assert_false(vim.tbl_isempty(ctx))
            assert_true(ctx.bufnr ~= nil)
            ctx:restore()
        end)
    end)
    describe("[FileLineReader]", function()
        local batch = 10
        while batch <= 10000 do
            it(string.format("read README.md with batch=%d", batch), function()
                local i = 1
                local iter = FileLineReader:open("README.md", batch) --[[@as FileLineReader]]
                assert_eq(type(iter), "table")
                while iter:has_next() do
                    local line = iter:next() --[[@as string]]
                    -- print(string.format("[%d]%s\n", i, line))
                    i = i + 1
                    assert_eq(type(line), "string")
                    assert_true(string.len(line) >= 0)
                    if string.len(line) > 0 then
                        assert_true(line:sub(#line, #line) ~= "\n")
                    end
                end
                iter:close()
            end)
            it(
                string.format("read lua/fzfx.lua with batch=%d", batch),
                function()
                    local i = 1
                    local iter = FileLineReader:open("lua/fzfx.lua", batch) --[[@as FileLineReader]]
                    assert_eq(type(iter), "table")
                    while iter:has_next() do
                        local line = iter:next() --[[@as string]]
                        -- print(string.format("[%d]%s\n", i, line))
                        i = i + 1
                        assert_eq(type(line), "string")
                        assert_true(string.len(line) >= 0)
                        if string.len(line) > 0 then
                            assert_true(line:sub(#line, #line) ~= "\n")
                        end
                    end
                    iter:close()
                end
            )
            it(
                string.format("read test/utils_spec.lua with batch=%d", batch),
                function()
                    local i = 1
                    local iter =
                        FileLineReader:open("test/utils_spec.lua", batch) --[[@as FileLineReader]]
                    assert_eq(type(iter), "table")
                    while iter:has_next() do
                        local line = iter:next() --[[@as string]]
                        -- print(string.format("[%d]%s\n", i, line))
                        i = i + 1
                        assert_eq(type(line), "string")
                        assert_true(string.len(line) >= 0)
                        if string.len(line) > 0 then
                            assert_true(line:sub(#line, #line) ~= "\n")
                        end
                    end
                    iter:close()
                end
            )
            batch = (batch + 3) * 3 + 3
        end
    end)
    describe("[readfile]", function()
        it("compares line by line and read all", function()
            local content = utils.readfile("README.md")
            local reader = FileLineReader:open("README.md") --[[@as FileLineReader]]
            local buffer = nil
            assert_eq(type(reader), "table")
            while reader:has_next() do
                local line = reader:next() --[[@as string]]
                assert_eq(type(line), "string")
                assert_true(string.len(line) >= 0)
                buffer = buffer and (buffer .. line .. "\n") or (line .. "\n")
            end
            reader:close()
            assert_eq(utils.string_rtrim(buffer --[[@as string]]), content)
        end)
    end)
    describe("[string_startswith]", function()
        it("start with", function()
            assert_true(utils.string_startswith("hello world", "hello"))
            assert_false(utils.string_startswith("hello world", "ello"))
        end)
    end)
    describe("[string_endswith]", function()
        it("end with", function()
            assert_true(utils.string_endswith("hello world", "world"))
            assert_false(utils.string_endswith("hello world", "hello"))
        end)
    end)
    describe("[parse_flag_query]", function()
        it("parse without flags1", function()
            local results = utils.parse_flag_query("asdf")
            assert_eq(type(results), "table")
            assert_eq(#results, 1)
            assert_eq(results[1], "asdf")
        end)
        it("parse without flags2", function()
            local results = utils.parse_flag_query("asdf  ")
            assert_eq(type(results), "table")
            assert_eq(#results, 1)
            assert_eq(results[1], "asdf")
        end)
        it("parse flags1", function()
            local results = utils.parse_flag_query("asdf --")
            assert_eq(type(results), "table")
            assert_eq(#results, 2)
            assert_eq(results[1], "asdf")
        end)
        it("parse flags2", function()
            local results = utils.parse_flag_query("asdf --  ")
            assert_eq(type(results), "table")
            assert_eq(#results, 2)
            assert_eq(results[1], "asdf")
        end)
        it("parse flags3", function()
            local results = utils.parse_flag_query("asdf --  -w")
            assert_eq(type(results), "table")
            assert_eq(#results, 2)
            assert_eq(results[1], "asdf")
            assert_eq(results[2], "-w")
        end)
        it("parse flags4", function()
            local results = utils.parse_flag_query("asdf --  -w \n")
            assert_eq(type(results), "table")
            assert_eq(#results, 2)
            assert_eq(results[1], "asdf")
            assert_eq(results[2], "-w")
        end)
    end)
    describe("[readfile/readlines]", function()
        it("compares lines and all", function()
            local content = utils.readfile("README.md")
            local lines = utils.readlines("README.md")
            local buffer = nil
            for _, line in
                ipairs(lines --[[@as table]])
            do
                assert_eq(type(line), "string")
                assert_true(string.len(line) >= 0)
                buffer = buffer and (buffer .. line .. "\n") or (line .. "\n")
            end
            assert_eq(utils.string_rtrim(buffer --[[@as string]]), content)
        end)
    end)
    describe("[writefile/writelines]", function()
        it("compares lines and all", function()
            local content = utils.readfile("README.md") --[[@as string]]
            local lines = utils.readlines("README.md") --[[@as table]]

            utils.writefile("test1-README.md", content)
            utils.writelines("test2-README.md", lines)

            content = utils.readfile("test1-README.md") --[[@as string]]
            lines = utils.readlines("test2-README.md") --[[@as table]]

            local buffer = nil
            for _, line in
                ipairs(lines --[[@as table]])
            do
                assert_eq(type(line), "string")
                assert_true(string.len(line) >= 0)
                buffer = buffer and (buffer .. line .. "\n") or (line .. "\n")
            end
            assert_eq(utils.string_rtrim(buffer --[[@as string]]), content)
        end)
    end)
    describe("[AsyncSpawn]", function()
        it("open", function()
            local async_spawn = utils.AsyncSpawn:make(
                { "cat", "README.md" },
                function() end
            ) --[[@as AsyncSpawn]]
            assert_eq(type(async_spawn), "table")
            assert_eq(type(async_spawn.cmds), "table")
            assert_eq(#async_spawn.cmds, 2)
            assert_eq(async_spawn.cmds[1], "cat")
            assert_eq(async_spawn.cmds[2], "README.md")
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
                utils.AsyncSpawn:make({ "cat", "README.md" }, process_line) --[[@as AsyncSpawn]]
            local pos = async_spawn:_consume_line(content, process_line)
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
            local async_spawn =
                utils.AsyncSpawn:make({ "cat", "README.md" }, process_line) --[[@as AsyncSpawn]]
            local content_splits =
                utils.string_split(content, "\n", { trimempty = false })
            for j, splits in ipairs(content_splits) do
                async_spawn:_on_stdout(nil, splits)
                if j < #content_splits then
                    async_spawn:_on_stdout(nil, "\n")
                end
            end
            async_spawn:_on_stdout(nil, nil)
            assert_true(async_spawn.out_pipe:is_closing())
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
                utils.AsyncSpawn:make({ "cat", "README.md" }, process_line) --[[@as AsyncSpawn]]
            local content_splits =
                utils.string_split(content, " ", { trimempty = false })
            for j, splits in ipairs(content_splits) do
                async_spawn:_on_stdout(nil, splits)
                if j < #content_splits then
                    async_spawn:_on_stdout(nil, " ")
                end
            end
            async_spawn:_on_stdout(nil, nil)
            assert_true(async_spawn.out_pipe:is_closing())
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
                    utils.AsyncSpawn:make({ "cat", "README.md" }, process_line) --[[@as AsyncSpawn]]
                local content_splits = utils.string_split(
                    content,
                    lower_char,
                    { trimempty = false }
                )
                for j, splits in ipairs(content_splits) do
                    async_spawn:_on_stdout(nil, splits)
                    if j < #content_splits then
                        async_spawn:_on_stdout(nil, lower_char)
                    end
                end
                async_spawn:_on_stdout(nil, nil)
                assert_true(async_spawn.out_pipe:is_closing())
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
                    utils.AsyncSpawn:make({ "cat", "README.md" }, process_line) --[[@as AsyncSpawn]]
                local content_splits = utils.string_split(
                    content,
                    upper_char,
                    { trimempty = false }
                )
                for j, splits in ipairs(content_splits) do
                    async_spawn:_on_stdout(nil, splits)
                    if j < #content_splits then
                        async_spawn:_on_stdout(nil, upper_char)
                    end
                end
                async_spawn:_on_stdout(nil, nil)
                assert_true(async_spawn.out_pipe:is_closing())
            end)
        end
        it("stderr", function()
            local async_spawn = utils.AsyncSpawn:make(
                { "cat", "README.md" },
                function() end
            ) --[[@as AsyncSpawn]]
            async_spawn:_on_stderr(nil, nil)
            assert_true(async_spawn.err_pipe:is_closing())
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
                utils.AsyncSpawn:make({ "cat", "README.md" }, process_line) --[[@as AsyncSpawn]]
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

            local async_spawn = utils.AsyncSpawn:make(
                { "cat", "lua/fzfx/config.lua" },
                process_line
            ) --[[@as AsyncSpawn]]
            async_spawn:run()
        end)
        it("close handle", function()
            local async_spawn = utils.AsyncSpawn:make(
                { "cat", "lua/fzfx/config.lua" },
                function() end
            ) --[[@as AsyncSpawn]]
            async_spawn:run()
            assert_true(async_spawn.process_handle ~= nil)
            async_spawn:_close_handle(async_spawn.process_handle)
            assert_true(async_spawn.process_handle:is_closing())
        end)
    end)
    describe("[list_index]", function()
        it("positive", function()
            for i = 1, 10 do
                assert_eq(utils.list_index(10, i), i)
            end
        end)
        it("negative", function()
            for i = -1, -10, -1 do
                assert_eq(utils.list_index(10, i), 10 + i + 1)
            end
            assert_eq(utils.list_index(10, -1), 10)
            assert_eq(utils.list_index(10, -10), 1)
            assert_eq(utils.list_index(10, -3), 8)
            assert_eq(utils.list_index(10, -5), 6)
        end)
    end)
end)
