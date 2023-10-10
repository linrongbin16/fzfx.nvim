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
            assert_true(utils.string_endswith(actual1, expect:sub(2)))
            local actual2 = line_helpers.parse_find(expect, { no_icon = true })
            assert_true(utils.string_endswith(actual2, expect:sub(2)))
        end)
        it("parse filename with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local input = " ~/github/linrongbin16/fzfx.nvim/README.md"
            local actual = line_helpers.parse_find(input)
            print(
                string.format("parse find with icon:%s\n", vim.inspect(actual))
            )
            assert_true(
                utils.string_endswith(
                    actual,
                    "/github/linrongbin16/fzfx.nvim/README.md"
                )
            )
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
                assert_true(utils.string_endswith(actual.filename, line:sub(2)))
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
                assert_true(
                    utils.string_endswith(
                        actual.filename,
                        utils.string_split(line, ":")[1]:sub(2)
                    )
                )
                assert_eq(
                    tostring(actual.lineno),
                    utils.string_split(line, ":")[2]
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
                assert_true(
                    utils.string_endswith(
                        actual.filename,
                        utils
                            .string_split(utils.string_split(line, ":")[1], " ")[2]
                            :sub(2)
                    )
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
    end)
    describe("[parse_rg]", function()
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
                local actual = line_helpers.parse_rg(line)
                assert_eq(type(actual), "table")
                assert_eq(type(actual.filename), "string")
                assert_eq(type(actual.lineno), "number")
                assert_eq(type(actual.column), "number")
                assert_true(
                    utils.string_endswith(
                        actual.filename,
                        utils.string_split(line, ":")[1]:sub(2)
                    )
                )
                assert_eq(
                    tostring(actual.lineno),
                    utils.string_split(line, ":")[2]
                )
                assert_eq(
                    tostring(actual.column),
                    utils.string_split(line, ":")[3]
                )
                local actual1 = line_helpers.parse_rg(line, { no_icon = true })
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
                local actual = line_helpers.parse_rg(line)
                assert_eq(type(actual), "table")
                assert_eq(type(actual.filename), "string")
                assert_eq(type(actual.lineno), "number")
                assert_eq(type(actual.column), "number")
                assert_true(
                    utils.string_endswith(
                        actual.filename,
                        utils
                            .string_split(utils.string_split(line, ":")[1], " ")[2]
                            :sub(2)
                    )
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
                "-rw-r--r--   1 linrongbin Administrators  585 Jul 22 14:26 'hello world.txt'",
                "-rw-r--r--   1 rlin  staff   1.0K Aug 28 12:39 LICENSE",
                "-rw-r--r--   1 rlin  staff    27K Oct  8 11:37 README.md",
                "drwxr-xr-x   3 rlin  staff    96B Aug 28 12:39 autoload",
                "drwxr-xr-x   4 rlin  staff   128B Sep 22 10:11 bin",
                "-rw-r--r--   1 rlin  staff   120B Sep  5 14:14 codecov.yml",
            }
            local expects = {
                "LICENSE",
                "README.md",
                "deps",
                "init.vim",
                "'hello world.txt'",
                "LICENSE",
                "README.md",
                "autoload",
                "bin",
                "codecov.yml",
            }
            for i, line in ipairs(lines) do
                local actual = line_helpers.parse_ls(line)
                local expect = expects[i]
                assert_eq(actual, expect)
            end
        end)
    end)
    describe("[parse_eza]", function()
        it("runs for windows", function()
            local lines = {
                -- Mode  Size Date Modified Name
                "d----    - 30 Sep 21:55  deps",
                "-a---  585 22 Jul 14:26  init.vim",
                "-a--- 6.4k 30 Sep 21:55  install.ps1",
                "-a--- 5.3k 23 Sep 13:43  install.sh",
            }
            local expects = {
                "deps",
                "init.vim",
                "install.ps1",
                "install.sh",
            }
            local parse_eza_on_windows = line_helpers.make_parse_ls(5)
            for i, line in ipairs(lines) do
                local actual = parse_eza_on_windows(line)
                local expect = expects[i]
                assert_eq(actual, expect)
            end
        end)
        it("runs for macOS/linux", function()
            local lines = {
                -- Permissions Size User Date Modified Name
                "drwxr-xr-x     - linrongbin 28 Aug 12:39  autoload",
                "drwxr-xr-x     - linrongbin 22 Sep 10:11  bin",
                ".rw-r--r--   120 linrongbin  5 Sep 14:14  codecov.yml",
                ".rw-r--r--  1.1k linrongbin 28 Aug 12:39  LICENSE",
                "drwxr-xr-x     - linrongbin  8 Oct 09:14  lua",
                ".rw-r--r--   28k linrongbin  8 Oct 11:37  README.md",
                "drwxr-xr-x     - linrongbin  8 Oct 11:44  test",
                ".rw-r--r--   28k linrongbin  8 Oct 12:10  test1-README.md",
                ".rw-r--r--   28k linrongbin  8 Oct 12:10  test2-README.md",
            }
            local expects = {
                "autoload",
                "bin",
                "codecov.yml",
                "LICENSE",
                "lua",
                "README.md",
                "test",
                "test1-README.md",
                "test2-README.md",
            }
            local parse_eza_on_macos_linux = line_helpers.make_parse_ls(6)
            for i, line in ipairs(lines) do
                local actual = parse_eza_on_macos_linux(line)
                local expect = expects[i]
                assert_eq(actual, expect)
            end
        end)
    end)
end)
