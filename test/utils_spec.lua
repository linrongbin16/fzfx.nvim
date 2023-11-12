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
    describe(
        "[string_empty/string_not_empty/string_blank/string_not_blank]",
        function()
            it("empty", function()
                assert_true(utils.string_empty())
                assert_true(utils.string_empty(nil))
                assert_true(utils.string_empty(""))
                assert_false(utils.string_not_empty())
                assert_false(utils.string_not_empty(nil))
                assert_false(utils.string_not_empty(""))
            end)
            it("not empty", function()
                assert_true(utils.string_not_empty(" "))
                assert_true(utils.string_not_empty(" asdf "))
                assert_false(utils.string_empty(" "))
                assert_false(utils.string_empty(" asdf "))
            end)
            it("blank", function()
                assert_true(utils.string_blank())
                assert_true(utils.string_blank(nil))
                assert_true(utils.string_blank(" "))
                assert_true(utils.string_blank("\n"))
                assert_false(utils.string_not_blank())
                assert_false(utils.string_not_blank(nil))
                assert_false(utils.string_not_blank(""))
            end)
            it("not blank", function()
                assert_true(utils.string_not_blank(" x"))
                assert_true(utils.string_not_blank(" asdf "))
                assert_false(utils.string_blank("y "))
                assert_false(utils.string_blank(" asdf "))
            end)
        end
    )
    describe("[string_find]", function()
        it("found", function()
            assert_eq(utils.string_find("abcdefg", "a"), 1)
            assert_eq(utils.string_find("abcdefg", "a", 1), 1)
            assert_eq(utils.string_find("abcdefg", "g"), 7)
            assert_eq(utils.string_find("abcdefg", "g", 1), 7)
            assert_eq(utils.string_find("abcdefg", "g", 7), 7)
            assert_eq(utils.string_find("fzfx -- -w -g *.lua", "--"), 6)
            assert_eq(utils.string_find("fzfx -- -w -g *.lua", "--", 1), 6)
            assert_eq(utils.string_find("fzfx -- -w -g *.lua", "--", 2), 6)
            assert_eq(utils.string_find("fzfx -- -w -g *.lua", "--", 3), 6)
            assert_eq(utils.string_find("fzfx -- -w -g *.lua", "--", 6), 6)
            assert_eq(utils.string_find("fzfx -w -- -g *.lua", "--"), 9)
            assert_eq(utils.string_find("fzfx -w -- -g *.lua", "--", 1), 9)
            assert_eq(utils.string_find("fzfx -w -- -g *.lua", "--", 2), 9)
            assert_eq(utils.string_find("fzfx -w ---g *.lua", "--", 8), 9)
            assert_eq(utils.string_find("fzfx -w ---g *.lua", "--", 9), 9)
        end)
        it("not found", function()
            assert_eq(utils.string_find("abcdefg", "a", 2), nil)
            assert_eq(utils.string_find("abcdefg", "a", 7), nil)
            assert_eq(utils.string_find("abcdefg", "g", 8), nil)
            assert_eq(utils.string_find("abcdefg", "g", 9), nil)
            assert_eq(utils.string_find("fzfx -- -w -g *.lua", "--", 7), nil)
            assert_eq(utils.string_find("fzfx -- -w -g *.lua", "--", 8), nil)
            assert_eq(utils.string_find("fzfx -w -- -g *.lua", "--", 10), nil)
            assert_eq(utils.string_find("fzfx -w -- -g *.lua", "--", 11), nil)
            assert_eq(utils.string_find("fzfx -w ---g *.lua", "--", 11), nil)
            assert_eq(utils.string_find("fzfx -w ---g *.lua", "--", 12), nil)
            assert_eq(utils.string_find("", "--"), nil)
            assert_eq(utils.string_find("", "--", 1), nil)
            assert_eq(utils.string_find("-", "--"), nil)
            assert_eq(utils.string_find("--", "---", 1), nil)
        end)
    end)
    describe("[string_rfind]", function()
        it("found", function()
            assert_eq(utils.string_rfind("abcdefg", "a"), 1)
            assert_eq(utils.string_rfind("abcdefg", "a", 1), 1)
            assert_eq(utils.string_rfind("abcdefg", "a", 7), 1)
            assert_eq(utils.string_rfind("abcdefg", "a", 2), 1)
            assert_eq(utils.string_rfind("abcdefg", "g"), 7)
            assert_eq(utils.string_rfind("abcdefg", "g", 7), 7)
            assert_eq(utils.string_rfind("fzfx -- -w -g *.lua", "--"), 6)
            assert_eq(utils.string_rfind("fzfx -- -w -g *.lua", "--", 6), 6)
            assert_eq(utils.string_rfind("fzfx -- -w -g *.lua", "--", 7), 6)
            assert_eq(utils.string_rfind("fzfx -- -w -g *.lua", "--", 8), 6)
            assert_eq(utils.string_rfind("fzfx -w -- -g *.lua", "--"), 9)
            assert_eq(utils.string_rfind("fzfx -w -- -g *.lua", "--", 10), 9)
            assert_eq(utils.string_rfind("fzfx -w -- -g *.lua", "--", 9), 9)
            assert_eq(utils.string_rfind("fzfx -w -- -g *.lua", "--", 10), 9)
            assert_eq(utils.string_rfind("fzfx -w -- -g *.lua", "--", 11), 9)
            assert_eq(utils.string_rfind("fzfx -w ---g *.lua", "--", 9), 9)
            assert_eq(utils.string_rfind("fzfx -w ---g *.lua", "--", 10), 10)
            assert_eq(utils.string_rfind("fzfx -w ---g *.lua", "--", 11), 10)
        end)
        it("not found", function()
            assert_eq(utils.string_rfind("abcdefg", "a", 0), nil)
            assert_eq(utils.string_rfind("abcdefg", "a", -1), nil)
            assert_eq(utils.string_rfind("abcdefg", "g", 6), nil)
            assert_eq(utils.string_rfind("abcdefg", "g", 5), nil)
            assert_eq(utils.string_rfind("fzfx -- -w -g *.lua", "--", 5), nil)
            assert_eq(utils.string_rfind("fzfx -- -w -g *.lua", "--", 4), nil)
            assert_eq(utils.string_rfind("fzfx -- -w -g *.lua", "--", 1), nil)
            assert_eq(utils.string_rfind("fzfx -w -- -g *.lua", "--", 8), nil)
            assert_eq(utils.string_rfind("fzfx -w -- -g *.lua", "--", 7), nil)
            assert_eq(utils.string_rfind("fzfx -w ---g *.lua", "--", 8), nil)
            assert_eq(utils.string_rfind("fzfx -w ---g *.lua", "--", 7), nil)
            assert_eq(utils.string_rfind("", "--"), nil)
            assert_eq(utils.string_rfind("", "--", 1), nil)
            assert_eq(utils.string_rfind("-", "--"), nil)
            assert_eq(utils.string_rfind("--", "---", 1), nil)
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
    describe("[string_isxxx]", function()
        local function contains_char(s, c)
            assert(string.len(s) > 0)
            assert(string.len(c) == 1)
            for i = 1, #s do
                if string.byte(s, i) == string.byte(c, 1) then
                    return true
                end
            end
            return false
        end

        local function contains_code(s, c)
            for _, i in ipairs(s) do
                if i == c then
                    return true
                end
            end
            return false
        end

        it("isspace", function()
            local whitespaces = "\r\n \t"
            local char_codes = { 11, 12 }
            for i = 1, 255 do
                if
                    contains_char(whitespaces, string.char(i))
                    or contains_code(char_codes, i)
                then
                    assert_true(utils.string_isspace(string.char(i)))
                else
                    print(
                        string.format(
                            "isspace: %d: %s\n",
                            i,
                            vim.inspect(utils.string_isspace(string.char(i)))
                        )
                    )
                    assert_false(utils.string_isspace(string.char(i)))
                end
            end
        end)
        it("isalpha", function()
            local a = "a"
            local z = "z"
            local A = "A"
            local Z = "Z"
            for i = 1, 255 do
                if
                    (i >= string.byte(a) and i <= string.byte(z))
                    or (i >= string.byte(A) and i <= string.byte(Z))
                then
                    assert_true(utils.string_isalpha(string.char(i)))
                else
                    assert_false(utils.string_isalpha(string.char(i)))
                end
            end
        end)
        it("isdigit", function()
            local _0 = "0"
            local _9 = "9"
            for i = 1, 255 do
                if i >= string.byte(_0) and i <= string.byte(_9) then
                    assert_true(utils.string_isdigit(string.char(i)))
                else
                    assert_false(utils.string_isdigit(string.char(i)))
                end
            end
        end)
        it("isalnum", function()
            local a = "a"
            local z = "z"
            local A = "A"
            local Z = "Z"
            local _0 = "0"
            local _9 = "9"
            for i = 1, 255 do
                if
                    (i >= string.byte(a) and i <= string.byte(z))
                    or (i >= string.byte(A) and i <= string.byte(Z))
                    or (i >= string.byte(_0) and i <= string.byte(_9))
                then
                    assert_true(utils.string_isalnum(string.char(i)))
                else
                    assert_false(utils.string_isalnum(string.char(i)))
                end
            end
        end)
        it("ishex", function()
            local a = "a"
            local f = "f"
            local A = "A"
            local F = "F"
            local _0 = "0"
            local _9 = "9"
            for i = 1, 255 do
                if
                    (i >= string.byte(a) and i <= string.byte(f))
                    or (i >= string.byte(A) and i <= string.byte(F))
                    or (i >= string.byte(_0) and i <= string.byte(_9))
                then
                    assert_true(utils.string_ishex(string.char(i)))
                else
                    print(
                        string.format(
                            "ishex, %d:%s\n",
                            i,
                            vim.inspect(utils.string_ishex(string.char(i)))
                        )
                    )
                    assert_false(utils.string_ishex(string.char(i)))
                end
            end
        end)
        it("islower", function()
            local a = "a"
            local z = "z"
            for i = 1, 255 do
                if i >= string.byte(a) and i <= string.byte(z) then
                    assert_true(utils.string_islower(string.char(i)))
                else
                    assert_false(utils.string_islower(string.char(i)))
                end
            end
        end)
        it("isupper", function()
            local A = "A"
            local Z = "Z"
            for i = 1, 255 do
                if i >= string.byte(A) and i <= string.byte(Z) then
                    assert_true(utils.string_isupper(string.char(i)))
                else
                    assert_false(utils.string_isupper(string.char(i)))
                end
            end
        end)
    end)
    describe("[RingBuffer]", function()
        it("creates", function()
            local rb = utils.RingBuffer:new(10)
            assert_eq(type(rb), "table")
            assert_eq(#rb.queue, 0)
        end)
        it("loop", function()
            local rb = utils.RingBuffer:new(10)
            assert_eq(type(rb), "table")
            for i = 1, 10 do
                rb:push(i)
            end
            local p = rb:begin()
            while p do
                local actual = rb:get(p)
                assert_eq(actual, p)
                p = rb:next(p)
            end
            rb = utils.RingBuffer:new(10)
            for i = 1, 15 do
                rb:push(i)
            end
            local p = rb:begin()
            while p do
                local actual = rb:get(p)
                if p <= 5 then
                    assert_eq(actual, p + 10)
                else
                    assert_eq(actual, p)
                end
                p = rb:next(p)
            end
            rb = utils.RingBuffer:new(10)
            for i = 1, 20 do
                rb:push(i)
            end
            local p = rb:begin()
            while p do
                local actual = rb:get(p)
                assert_eq(actual, p + 10)
                p = rb:next(p)
            end
        end)
        it("get latest", function()
            local rb = utils.RingBuffer:new(10)
            for i = 1, 50 do
                rb:push(i)
                assert_eq(rb:get(), i)
            end
            local p = rb:begin()
            print(string.format("|utils_spec| begin, p:%s\n", vim.inspect(p)))
            while p do
                local actual = rb:get(p)
                print(
                    string.format(
                        "|utils_spec| get, p:%s, actual:%s\n",
                        vim.inspect(p),
                        vim.inspect(actual)
                    )
                )
                assert_eq(actual, p + 40)
                p = rb:next(p)
                print(
                    string.format("|utils_spec| next, p:%s\n", vim.inspect(p))
                )
            end
            p = rb:rbegin()
            print(
                string.format(
                    "|utils_spec| rbegin, p:%s, rb:%s\n",
                    vim.inspect(p),
                    vim.inspect(rb)
                )
            )
            while p do
                local actual = rb:get(p)
                print(
                    string.format(
                        "|utils_spec| rget, p:%s, actual:%s, rb:%s\n",
                        vim.inspect(p),
                        vim.inspect(actual),
                        vim.inspect(rb)
                    )
                )
                assert_eq(actual, p + 40)
                p = rb:rnext(p)
                print(
                    string.format(
                        "|utils_spec| rnext, p:%s, rb:%s\n",
                        vim.inspect(p),
                        vim.inspect(rb)
                    )
                )
            end
        end)
    end)
    describe("[make_uuid/make_unique_id]", function()
        it("make uuid", function()
            local actual = utils.make_uuid()
            assert_eq(type(actual), "string")
            local actual_splits = utils.string_split(actual, "-")
            assert_eq(type(actual_splits), "table")
            assert_eq(#actual_splits, 4)
        end)
        it("make unique id", function()
            local id1 = utils.make_unique_id()
            assert_true(tonumber(id1) >= 1)
            local id2 = utils.make_unique_id()
            assert_eq(tonumber(id2), tonumber(id1) + 1)
            local id3 = utils.make_unique_id()
            assert_eq(tonumber(id3), tonumber(id2) + 1)
        end)
    end)
    describe("[asyncreadfile]", function()
        it("read", function()
            utils.asyncreadfile("README.md", function(data)
                assert_true(string.len(data) > 0)
            end)
        end)
    end)
    describe("[asyncwritefile]", function()
        it("read", function()
            local content = "hello world, goodbye world!"
            utils.asyncwritefile("test.txt", content, function(err, bytes)
                assert_true(err == nil)
                assert_eq(bytes, #content)
            end)
        end)
    end)
end)
