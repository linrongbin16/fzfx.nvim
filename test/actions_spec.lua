local cwd = vim.fn.getcwd()

describe("actions", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        require("fzfx.config").setup()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local DEVICONS_PATH =
        "~/github/linrongbin16/.config/nvim/lazy/nvim-web-devicons"
    local actions = require("fzfx.actions")
    local utils = require("fzfx.utils")
    local path = require("fzfx.path")
    describe("[nop]", function()
        it("do nothing", function()
            local nop = actions.nop
            assert_eq(type(nop), "function")
            assert_true(nop({}) == nil)
        end)
    end)
    describe("[make_edit_vim_commands]", function()
        it("edit file without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
            }
            local actual = actions.make_edit_vim_commands(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual.edit, 3)
            for i, line in ipairs(lines) do
                local expect = string.format("edit %s", vim.fn.expand(line))
                assert_eq(actual.edit[i], expect)
            end
        end)
        it("edit file with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " ~/github/linrongbin16/fzfx.nvim/README.md",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
            }
            local actual = actions.make_edit_vim_commands(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual.edit, 3)
            for i, line in ipairs(lines) do
                local expect = string.format(
                    "edit %s",
                    vim.fn.expand(vim.fn.split(line)[2])
                )
                assert_eq(actual.edit[i], expect)
            end
        end)
        it("edit file with delimiter, without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md:12",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:13:",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:13: hello world",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:3",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:3: ok ok",
            }
            local actual = actions.make_edit_vim_commands(lines, ":", 1)
            assert_eq(type(actual), "table")
            assert_eq(#actual.edit, 5)
            for i = 1, 5 do
                local line = lines[i]
                local expect = string.format(
                    "edit %s",
                    vim.fn.expand(utils.string_split(line, ":")[1])
                )
                assert_eq(actual.edit[i], expect)
            end
        end)
        it("edit file with delimiter, with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " ~/github/linrongbin16/fzfx.nvim/README.md:12",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:15",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:15:",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:70",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:4:71: ok ko",
            }
            local actual = actions.make_edit_vim_commands(lines, ":", 1)
            assert_eq(type(actual), "table")
            assert_eq(#actual.edit, 5)
            for i, line in ipairs(lines) do
                local expect = string.format(
                    "edit %s",
                    vim.fn.expand(
                        utils.string_split(
                            utils.string_split(line, ":")[1],
                            " "
                        )[2]
                    )
                )
                print(
                    string.format(
                        "expect line[%s]:%s\n",
                        vim.inspect(i),
                        vim.inspect(expect)
                    )
                )
                assert_eq(actual.edit[i], expect)
            end
        end)
        it("edit file/lineno without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md:12",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:13:",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:13: hello world",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:3",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:3: ok ok",
            }
            local actual = actions.make_edit_vim_commands(lines, ":", 1, 2)
            assert_eq(type(actual), "table")
            assert_eq(#actual.edit, 5)
            for i = 1, 5 do
                local line = lines[i]
                local expect = string.format(
                    "edit %s",
                    vim.fn.expand(utils.string_split(line, ":")[1])
                )
                assert_eq(actual.edit[i], expect)
            end
            assert_eq("call setpos('.', [0, 1, 1])", actual.setpos)
        end)
        it("edit file/lineno with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " ~/github/linrongbin16/fzfx.nvim/README.md:12",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:15",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:15:",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:70",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:4:71: ok ko",
            }
            local actual = actions.make_edit_vim_commands(lines, ":", 1, 2)
            assert_eq(type(actual), "table")
            assert_eq(#actual.edit, 5)
            for i, line in ipairs(lines) do
                local expect = string.format(
                    "edit %s",
                    vim.fn.expand(
                        utils.string_split(
                            utils.string_split(line, ":")[1],
                            " "
                        )[2]
                    )
                )
                print(
                    string.format(
                        "expect line[%s]:%s\n",
                        vim.inspect(i),
                        vim.inspect(expect)
                    )
                )
                assert_eq(actual.edit[i], expect)
            end
            assert_eq("call setpos('.', [0, 4, 1])", actual.setpos)
        end)
        it("edit file/lineno/col without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md:12:30",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:13:1:",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:13:2: hello world",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:3",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:3: ok ok",
            }
            local actual = actions.make_edit_vim_commands(lines, ":", 1, 2, 3)
            assert_eq(type(actual), "table")
            assert_eq(#actual.edit, 5)
            for i = 1, 5 do
                local line = lines[i]
                local expect = string.format(
                    "edit %s",
                    vim.fn.expand(utils.string_split(line, ":")[1])
                )
                assert_eq(actual.edit[i], expect)
            end
            assert_eq("call setpos('.', [0, 1, 3])", actual.setpos)
        end)
        it("edit file/lineno/col with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " ~/github/linrongbin16/fzfx.nvim/README.md:12:30",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:15:98",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:15:82:",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:70",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:4:71: ok ko",
            }
            local actual = actions.make_edit_vim_commands(lines, ":", 1, 2, 3)
            assert_eq(type(actual), "table")
            assert_eq(#actual.edit, 5)
            for i, line in ipairs(lines) do
                local expect = string.format(
                    "edit %s",
                    vim.fn.expand(
                        utils.string_split(
                            utils.string_split(line, ":")[1],
                            " "
                        )[2]
                    )
                )
                print(
                    string.format(
                        "expect line[%s]:%s\n",
                        vim.inspect(i),
                        vim.inspect(expect)
                    )
                )
                assert_eq(actual.edit[i], expect)
            end
            assert_eq("call setpos('.', [0, 4, 71])", actual.setpos)
        end)
    end)
    describe("[make_edit_find_commands]", function()
        it("edit file without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
            }
            local actual = actions.make_edit_find_commands(lines)
            assert_eq(type(actual), "table")
            assert_eq(type(actual.edit), "table")
            assert_eq(#actual.edit, 5)
            for i, line in ipairs(lines) do
                local expect = string.format(
                    "edit %s",
                    vim.fn.expand(path.normalize(line))
                )
                assert_eq(actual.edit[i], expect)
            end
        end)
        it("edit file with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " ~/github/linrongbin16/fzfx.nvim/README.md",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
            }
            local actual = actions.make_edit_find_commands(lines)
            assert_eq(type(actual), "table")
            assert_eq(type(actual.edit), "table")
            assert_eq(#actual.edit, 5)
            for i, line in ipairs(lines) do
                local first_space_pos = utils.string_find(line, " ")
                local expect = string.format(
                    "edit %s",
                    vim.fn.expand(path.normalize(line:sub(first_space_pos + 1)))
                )
                assert_eq(actual.edit[i], expect)
            end
        end)
    end)
end)
