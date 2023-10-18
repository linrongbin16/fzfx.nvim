local cwd = vim.fn.getcwd()

describe("line_helpers", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local line_helpers = require("fzfx.line_helpers")
    local path = require("fzfx.path")
    local utils = require("fzfx.utils")
    local DEVICONS_PATH =
        "~/github/linrongbin16/.config/nvim/lazy/nvim-web-devicons"
    describe("[parse_find]", function()
        it("parse filename without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md",
                "~/github/linrongbin16/fzfx.nvim/LICENSE",
                "~/github/linrongbin16/fzfx.nvim/codecov.yml",
                "~/github/linrongbin16/fzfx.nvim/test/hello world.txt",
                "~/github/linrongbin16/fzfx.nvim/test/goodbye world/goodbye.lua",
            }
            for i, line in ipairs(lines) do
                local expect = path.normalize(vim.fn.expand(line))
                local actual1 = line_helpers.parse_find(expect)
                assert_eq(expect, actual1)
                local actual2 =
                    line_helpers.parse_find(expect, { no_icon = true })
                assert_eq(expect, actual2)
            end
        end)
        it("parse filename with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " ~/github/linrongbin16/fzfx.nvim/README.md",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua/test/hello world.txt",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/world.txt",
            }
            for i, line in ipairs(lines) do
                local first_space_pos = utils.string_find(line, " ")
                local expect = path.normalize(
                    vim.fn.expand(vim.trim(line:sub(first_space_pos + 1)))
                )
                local actual = line_helpers.parse_find(line)
                assert_eq(expect, actual)
            end
        end)
    end)
    describe("[parse_grep]", function()
        it("without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md:1",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1:2",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1: ok ok",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:2:3:hello",
            }
            for _, line in ipairs(lines) do
                local actual = line_helpers.parse_grep(line)
                assert_eq(type(actual), "table")
                assert_eq(type(actual.filename), "string")
                assert_eq(type(actual.lineno), "number")

                local line_splits = utils.string_split(line, ":")
                assert_eq(actual.lineno, tonumber(line_splits[2]))
                assert_eq(
                    actual.filename,
                    path.normalize(vim.fn.expand(line_splits[1]))
                )
            end
        end)
        it("with prepend icon", function()
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
                assert_eq(type(actual.lineno), "number")
                local line_splits = utils.string_split(line, ":")
                assert_eq(actual.lineno, tonumber(line_splits[2]))
                assert_eq(
                    actual.filename,
                    line_helpers.parse_find(line_splits[1])
                )
            end
        end)
    end)
    describe("[parse_rg]", function()
        it("without icon", function()
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
                local line_splits = utils.string_split(line, ":")
                assert_eq(
                    actual.filename,
                    line_helpers.parse_find(line_splits[1])
                )
                assert_eq(actual.lineno, tonumber(line_splits[2]))
                assert_eq(actual.column, tonumber(line_splits[3]))
            end
        end)
        it("with prepend icon", function()
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
                local line_splits = utils.string_split(line, ":")
                assert_eq(
                    actual.filename,
                    line_helpers.parse_find(line_splits[1])
                )
                assert_eq(actual.lineno, tonumber(line_splits[2]))
                assert_eq(actual.column, tonumber(line_splits[3]))
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
    describe("[parse_vim_commands]", function()
        local VIM_COMMANDS_HEADER =
            "Name              Bang|Bar|Nargs|Range|Complete         Desc/Location"
        local CONTEXT = {
            name_width = 17,
            opts_width = 37,
        }

        it("parse ex commands with locations", function()
            local lines = {
                ":                 N   |Y  |N/A  |N/A  |N/A              /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/doc/index.txt:1121",
                ":!                N   |Y  |N/A  |N/A  |N/A              /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/doc/index.txt:1122",
                ":Next             N   |Y  |N/A  |N/A  |N/A              /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/doc/index.txt:1124",
            }
            for _, line in ipairs(lines) do
                local last_space = utils.string_rfind(line, " ")
                local expect_splits =
                    utils.string_split(line:sub(last_space + 1), ":")
                local actual = line_helpers.parse_vim_commands(line, CONTEXT)
                assert_eq(type(actual), "table")
                assert_eq(
                    actual.filename,
                    vim.fn.expand(path.normalize(expect_splits[1]))
                )
                assert_eq(actual.lineno, tonumber(expect_splits[2]))
            end
        end)
        it("parse ex commands with description", function()
            local lines = {
                ':bdelete          N   |Y  |N/A  |N/A  |N/A              "delete buffer"',
            }
            for _, line in ipairs(lines) do
                local double_quote_before_last =
                    utils.string_rfind(line, '"', #line - 1)
                local expect = vim.trim(line:sub(double_quote_before_last))
                local actual = line_helpers.parse_vim_commands(line, CONTEXT)
                assert_eq(type(actual), "string")
                assert_eq(actual, expect)
            end
        end)
        it("parse user commands with location", function()
            local lines = {
                "FzfxCommands      Y   |Y  |N/A  |N/A  |N/A              ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:120",
                "FzfxFiles         Y   |Y  |N/A  |N/A  |N/A              ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:120",
                "Barbecue          Y   |Y  |N/A  |N/A  |N/A              ~/.config/nvim/lazy/barbecue/lua/barbecue.lua:73",
            }
            for _, line in ipairs(lines) do
                local last_space = utils.string_rfind(line, " ")
                local expect_splits =
                    utils.string_split(line:sub(last_space + 1), ":")
                local actual = line_helpers.parse_vim_commands(line, CONTEXT)
                assert_eq(type(actual), "table")
                assert_eq(
                    actual.filename,
                    vim.fn.expand(path.normalize(expect_splits[1]))
                )
                assert_eq(actual.lineno, tonumber(expect_splits[2]))
            end
        end)
        it("parse user commands with description", function()
            local lines = {
                'Bdelete           N   |Y  |N/A  |N/A  |N/A              "delete buffer"',
            }
            for _, line in ipairs(lines) do
                local double_quote_before_last =
                    utils.string_rfind(line, '"', #line - 1)
                local expect = vim.trim(line:sub(double_quote_before_last))
                local actual = line_helpers.parse_vim_commands(line, CONTEXT)
                assert_eq(type(actual), "string")
                assert_eq(actual, expect)
            end
        end)
    end)
end)
