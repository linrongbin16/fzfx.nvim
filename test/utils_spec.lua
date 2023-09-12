local cwd = vim.fn.getcwd()

describe("utils", function()
    local assert_eq = assert.are.equal
    local assert_neq = assert.are_not.equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false
    local assert_truthy = assert.is.truthy
    local assert_falsy = assert.is.falsy

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local utils = require("fzfx.utils")
    describe("[list_isempty]", function()
        it("is true", function()
            assert_true(utils.list_isempty())
            assert_true(utils.list_isempty(nil))
            assert_true(utils.list_isempty({}))
            assert_true(utils.list_isempty({ a = 1, b = 2 }))
        end)
    end)
    describe("[list_filter]", function()
        it("filtered by positive number", function()
            local t = { 1, 2, 3, 4, -1, -2, 0 }
            local actual = utils.list_filter(t, function(i, v)
                return v > 0
            end)
            assert_eq(type(actual), "table")
            for k, v in pairs(actual) do
                assert_true(v > 0)
            end
        end)
        it("filtered by negative number", function()
            local t = { 1, 2, 3, 4, -1, -2, 0 }
            local actual = utils.list_filter(t, function(i, v)
                return v < 0
            end)
            assert_eq(type(actual), "table")
            for k, v in pairs(actual) do
                assert_true(v < 0)
            end
        end)
        it("filtered by index is 1/2/3", function()
            local t = { 1, 2, 3, 4, -1, -2, 0 }
            local actual = utils.list_filter(t, function(i, v)
                return i == "a" or i == "b" or i == "c"
            end)
            assert_eq(type(actual), "table")
            for k, v in pairs(actual) do
                assert_true(k == "a" or k == "b" or k == "c")
            end
        end)
        it("filter on table", function()
            local t = {
                a = -5,
                b = -4,
                c = -3,
                d = -2,
                e = -1,
                f = 0,
                g = 1,
                h = 2,
                i = 3,
                j = 4,
                k = 5,
                l = 6,
            }
            local actual = utils.list_filter(t, function(i, v)
                return v > 0
            end)
            print(string.format("filtered list:%s\n", vim.inspect(actual)))
            assert_eq(type(actual), "table")
            assert_true(utils.list_isempty(actual))
        end)
    end)
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
            assert_false(utils.is_buf_valid(0))
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
end)
