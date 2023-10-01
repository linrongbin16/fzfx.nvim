local cwd = vim.fn.getcwd()

describe("line_helpers", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local line_helpers = require("fzfx.line_helpers")
    local utils = require("fzfx.utils")
    local DEVICONS_PATH =
    "~/github/linrongbin16/.config/nvim/lazy/nvim-web-devicons"
    describe("[parse_find]", function()
        it("parse filename without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local expect = "~/github/linrongbin16/fzfx.nvim/README.md"
            local actual1 = line_helpers.parse_find(expect)
            assert_eq(expect, actual1)
            local actual2 = line_helpers.parse_find(expect, { no_icon = true })
            assert_eq(expect, actual2)
        end)
        it("parse filename with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local input = " ~/github/linrongbin16/fzfx.nvim/README.md"
            local actual = line_helpers.parse_find(input)
            print(
                string.format("parse find with icon:%s\n", vim.inspect(actual))
            )
            assert_eq("~/github/linrongbin16/fzfx.nvim/README.md", actual)
        end)
    end)
    describe("[parse_grep]", function()
        it("parse grep without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
            }
            for _, line in ipairs(lines) do
                local actual = line_helpers.parse_grep(line)
                assert_eq(type(actual), "table")
                assert_eq(type(actual.filename), "string")
                assert_true(actual.lineno == nil)
                assert_true(actual.column == nil)
                assert_eq(actual.filename, line)
            end
        end)
        it("parse grep with lineno, without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md:12",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:13:",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:13: hello world",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:3",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:3: ok ok",
            }
            for _, line in ipairs(lines) do
                local actual = line_helpers.parse_grep(line)
                assert_eq(type(actual), "table")
                assert_eq(type(actual.filename), "string")
                assert_eq(actual.filename, utils.string_split(line, ":")[1])
                assert_eq(
                    tostring(actual.lineno),
                    utils.string_split(line, ":")[2]
                )
                assert_true(
                    actual.column == nil
                    or (
                        type(actual.column) == "number"
                        and tostring(actual.column)
                        == utils.string_split(line, ":")[3]
                    )
                )
                local actual1 =
                    line_helpers.parse_grep(line, { no_icon = true })
                assert_eq(actual.filename, actual1.filename)
            end
        end)
        it("parse path with lineno, with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " ~/github/linrongbin16/fzfx.nvim/README.md:12",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:15",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:15:",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:70",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:4:71: ok ko",
            }
            for _, line in ipairs(lines) do
                local actual = line_helpers.parse_grep(line)
                assert_eq(type(actual), "table")
                assert_eq(type(actual.filename), "string")
                assert_eq(
                    actual.filename,
                    utils.string_split(utils.string_split(line, ":")[1], " ")[2]
                )
                assert_eq(type(actual.lineno), "number")
                assert_eq(
                    tostring(actual.lineno),
                    utils.string_split(line, ":")[2]
                )
                assert_true(
                    actual.column == nil
                    or (
                        type(actual.column) == "number"
                        and tostring(actual.column)
                        == utils.string_split(line, ":")[3]
                    )
                )
            end
        end)
        it("parse path with lineno/column, without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md:12:30",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:13:1:",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:13:2: hello world",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:3",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:3: ok ok",
            }
            for _, line in ipairs(lines) do
                local actual = line_helpers.parse_grep(line)
                assert_eq(type(actual), "table")
                assert_eq(type(actual.filename), "string")
                assert_eq(type(actual.lineno), "number")
                assert_eq(type(actual.column), "number")
                assert_eq(actual.filename, utils.string_split(line, ":")[1])
                assert_eq(
                    tostring(actual.lineno),
                    utils.string_split(line, ":")[2]
                )
                assert_eq(
                    tostring(actual.column),
                    utils.string_split(line, ":")[3]
                )
                local actual1 =
                    line_helpers.parse_grep(line, { no_icon = true })
                assert_eq(actual.filename, actual1.filename)
            end
        end)
        it("parse grep with lineno/column, with icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " ~/github/linrongbin16/fzfx.nvim/README.md:12:30",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:15:98",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:15:82:",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:70",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:4:71: ok ko",
            }
            for _, line in ipairs(lines) do
                local actual = line_helpers.parse_grep(line)
                assert_eq(type(actual), "table")
                assert_eq(type(actual.filename), "string")
                assert_eq(type(actual.lineno), "number")
                assert_eq(type(actual.column), "number")
                assert_eq(
                    actual.filename,
                    utils.string_split(utils.string_split(line, ":")[1], " ")[2]
                )
                assert_eq(
                    tostring(actual.lineno),
                    utils.string_split(line, ":")[2]
                )
                assert_eq(
                    tostring(actual.column),
                    utils.string_split(line, ":")[3]
                )
            end
        end)
    end)
    describe("[parse_ls]", function()
        it("parse ls -lh", function()
            local lines = {
                "-rw-r--r--   1 linrongbin Administrators 1.1K Jul  9 14:35 LICENSE",
                "-rw-r--r--   1 linrongbin Administrators 6.2K Sep 28 22:26 README.md",
                "drwxr-xr-x   2 linrongbin Administrators 4.0K Sep 30 21:55 deps",
                "-rw-r--r--   1 linrongbin Administrators  585 Jul 22 14:26 init.vim",
            }
            local actual1 = line_helpers.parse_ls(lines[1], 8)
            print(string.format("parse ls-1:%s\n", vim.inspect(actual1)))
            assert_eq("LICENSE", actual1)
            local actual2 = line_helpers.parse_ls(lines[2], 8)
            print(string.format("parse ls-2:%s\n", vim.inspect(actual2)))
            assert_eq("README.md", actual2)
            local actual3 = line_helpers.parse_ls(lines[3], 8)
            print(string.format("parse ls-3:%s\n", vim.inspect(actual3)))
            assert_eq("deps", actual3)
            local actual4 = line_helpers.parse_ls(lines[4], 8)
            print(string.format("parse ls-4:%s\n", vim.inspect(actual4)))
            assert_eq("init.vim", actual4)
        end)
    end)
end)
