local cwd = vim.fn.getcwd()

describe("actions", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        require("fzfx.config").setup()
        vim.api.nvim_command("cd " .. cwd)
        vim.opt.swapfile = false
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
    describe("[_make_commands_for_find]", function()
        it("edit file without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
            }
            local actual = actions._make_edit_find_commands(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, 5)
            for i, line in ipairs(lines) do
                local expect = string.format(
                    "edit %s",
                    vim.fn.expand(path.normalize(line))
                )
                assert_eq(actual[i], expect)
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
            local actual = actions._make_edit_find_commands(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, 5)
            for i, line in ipairs(lines) do
                local first_space_pos = utils.string_find(line, " ")
                local expect = string.format(
                    "edit %s",
                    vim.fn.expand(path.normalize(line:sub(first_space_pos + 1)))
                )
                assert_eq(actual[i], expect)
            end
        end)
        it("run edit file command without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "README.md:17",
                "lua/fzfx.lua:30:17",
                "lua/fzfx/config.lua:37:hello world",
                "lua/fzfx/test/goodbye world/goodbye.lua",
                "lua/fzfx/test/goodbye world/world.txt",
                "lua/fzfx/test/hello world.txt",
            }
            actions.edit_find(lines)
            assert_true(true)
        end)
        it("run edit file command with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " README.md",
                "󰢱 lua/fzfx.lua",
                "󰢱 lua/fzfx/config.lua",
                "󰢱 lua/fzfx/test/goodbye world/goodbye.lua",
                "󰢱 lua/fzfx/test/goodbye world/world.txt",
                "󰢱 lua/fzfx/test/hello world.txt",
            }
            actions.edit_find(lines)
            assert_true(true)
        end)
    end)
    describe("[_make_edit_grep_commands]", function()
        it("edit file without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:hello world",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:12:81: goodbye",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:81:72:9129",
            }
            local actual = actions._make_edit_grep_commands(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, 6)
            for i, act in ipairs(actual) do
                if i <= #lines then
                    local expect = string.format(
                        "edit %s",
                        vim.fn.expand(
                            path.normalize(utils.string_split(lines[i], ":")[1])
                        )
                    )
                    assert_eq(act, expect)
                else
                    assert_eq(act, "call setpos('.', [0, 81, 1])")
                end
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
            local actual = actions._make_edit_grep_commands(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, 5)
            for i, line in ipairs(lines) do
                local first_space_pos = utils.string_find(line, " ")
                local expect = string.format(
                    "edit %s",
                    vim.fn.expand(path.normalize(line:sub(first_space_pos + 1)))
                )
                assert_eq(actual[i], expect)
            end
        end)
        it("run edit file command without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "README.md",
                "lua/fzfx.lua",
                "lua/fzfx/config.lua",
                "lua/fzfx/test/goodbye world/goodbye.lua",
                "lua/fzfx/test/goodbye world/world.txt",
                "lua/fzfx/test/hello world.txt",
            }
            actions.edit_find(lines)
            assert_true(true)
        end)
        it("run edit file command with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " README.md",
                "󰢱 lua/fzfx.lua",
                "󰢱 lua/fzfx/config.lua",
                "󰢱 lua/fzfx/test/goodbye world/goodbye.lua",
                "󰢱 lua/fzfx/test/goodbye world/world.txt",
                "󰢱 lua/fzfx/test/hello world.txt",
            }
            actions.edit_find(lines)
            assert_true(true)
        end)
    end)
    describe("[_make_edit_rg_commands]", function()
        it("edit file without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:hello world",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:12:81: goodbye",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:81:71:9129",
            }
            local actual = actions._make_edit_rg_commands(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, 6)
            for i, act in ipairs(actual) do
                if i <= #lines then
                    local expect = string.format(
                        "edit %s",
                        vim.fn.expand(
                            path.normalize(utils.string_split(lines[i], ":")[1])
                        )
                    )
                    assert_eq(act, expect)
                else
                    assert_eq(act, "call setpos('.', [0, 81, 71])")
                end
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
            local actual = actions._make_edit_rg_commands(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, 5)
            for i, line in ipairs(lines) do
                local first_space_pos = utils.string_find(line, " ")
                local expect = string.format(
                    "edit %s",
                    vim.fn.expand(path.normalize(line:sub(first_space_pos + 1)))
                )
                assert_eq(actual[i], expect)
            end
        end)
        it("run edit file command without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "README.md",
                "lua/fzfx.lua",
                "lua/fzfx/config.lua",
                "lua/fzfx/test/goodbye world/goodbye.lua",
                "lua/fzfx/test/goodbye world/world.txt",
                "lua/fzfx/test/hello world.txt",
            }
            actions.edit_find(lines)
            assert_true(true)
        end)
        it("run edit file command with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " README.md",
                "󰢱 lua/fzfx.lua",
                "󰢱 lua/fzfx/config.lua",
                "󰢱 lua/fzfx/test/goodbye world/goodbye.lua",
                "󰢱 lua/fzfx/test/goodbye world/world.txt",
                "󰢱 lua/fzfx/test/hello world.txt",
            }
            actions.edit_find(lines)
            assert_true(true)
        end)
    end)
    describe("[feed_vim_command]", function()
        it("feedkeys", function()
            local actual = actions.feed_vim_command({
                ":FzfxCommands    Y | N | N/A  ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:215",
            })
            assert_true(actual == nil)
        end)
    end)
end)
