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
    local FileSyncReaderLineIterator =
        require("fzfx.utils").FileSyncReaderLineIterator
    local FileSyncReader = require("fzfx.utils").FileSyncReader
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
            local s = utils.get_win_option(0, "spell")
            print(string.format("spell get win option:%s\n", vim.inspect(s)))
            assert_eq(type(s), "boolean")
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
    describe("[string_split]", function()
        it("splits rg options-1", function()
            local actual = utils.string_split("-w -g *.md")
            local expect = { "-w", "-g", "*.md" }
            assert_eq(#actual, #expect)
            for i, v in ipairs(actual) do
                assert_eq(v, expect[i])
            end
        end)
        it("splits rg options-2", function()
            local actual = utils.string_split("  -w -g *.md  ")
            local expect = { "-w", "-g", "*.md" }
            assert_eq(#actual, #expect)
            for i, v in ipairs(actual) do
                assert_eq(v, expect[i])
            end
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
    describe("[FileSyncReaderLineIterator]", function()
        it("read README.md with batch=10", function()
            local i = 1
            local iter = FileSyncReaderLineIterator:make("README.md", 10) --[[@as FileSyncReaderLineIterator]]
            assert_eq(type(iter), "table")
            while iter:has_next() do
                local line = iter:next() --[[@as string]]
                print(string.format("[%d]%s\n", i, line))
                i = i + 1
                assert_eq(type(line), "string")
                assert_true(string.len(line) >= 0)
                if string.len(line) > 0 then
                    assert_true(line:sub(#line, #line) ~= "\n")
                end
            end
            iter:close()
        end)
        it("read lua/fzfx.lua", function()
            local i = 1
            local iter = FileSyncReaderLineIterator:make("lua/fzfx.lua", 100) --[[@as FileSyncReaderLineIterator]]
            assert_eq(type(iter), "table")
            while iter:has_next() do
                local line = iter:next() --[[@as string]]
                print(string.format("[%d]%s\n", i, line))
                i = i + 1
                assert_eq(type(line), "string")
                assert_true(string.len(line) >= 0)
                if string.len(line) > 0 then
                    assert_true(line:sub(#line, #line) ~= "\n")
                end
            end
            iter:close()
        end)
        it("read test/utils_spec.lua", function()
            local i = 1
            local iter =
                FileSyncReaderLineIterator:make("test/utils_spec.lua", 4096) --[[@as FileSyncReaderLineIterator]]
            assert_eq(type(iter), "table")
            while iter:has_next() do
                local line = iter:next() --[[@as string]]
                print(string.format("[%d]%s\n", i, line))
                i = i + 1
                assert_eq(type(line), "string")
                assert_true(string.len(line) >= 0)
                if string.len(line) > 0 then
                    assert_true(line:sub(#line, #line) ~= "\n")
                end
            end
            iter:close()
        end)
    end)
    describe("[FileSyncReader]", function()
        it("compares line by line and read all", function()
            local reader = FileSyncReader:open("README.md") --[[@as FileSyncReader]]
            local content = reader:read()
            local buffer = nil
            local iter = reader:line_iterator() --[[@as FileSyncReaderLineIterator]]
            assert_eq(type(iter), "table")
            while iter:has_next() do
                local line = iter:next() --[[@as string]]
                assert_eq(type(line), "string")
                assert_true(string.len(line) >= 0)
                buffer = buffer and (buffer .. line .. "\n") or (line .. "\n")
            end
            iter:close()
            assert_eq(utils.string_rtrim(buffer --[[@as string]]), content)
        end)
    end)
end)
