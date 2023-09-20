local cwd = vim.fn.getcwd()

describe("actions", function()
    local assert_eq = assert.are.equal
    local assert_neq = assert.are_not.equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false
    local assert_truthy = assert.is.truthy
    local assert_falsy = assert.is.falsy

    before_each(function()
        require("fzfx.config").setup()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local DEVICONS_PATH =
        "~/github/linrongbin16/.config/nvim/lazy/nvim-web-devicons"
    local actions = require("fzfx.actions")
    describe("[nop]", function()
        it("do nothing", function()
            local nop = actions.nop
            assert_eq(type(nop), "function")
            assert_true(nop({}) == nil)
        end)
    end)
    describe("[retrieve_filename]", function()
        it("retrieve filename without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local expect = "~/github/linrongbin16/fzfx.nvim/README.md"
            local actual = actions.retrieve_filename(expect)
            assert_eq(expect, actual)
        end)
        it("retrieve filename with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local input = " ~/github/linrongbin16/fzfx.nvim/README.md"
            local actual = actions.retrieve_filename(input, " ", 2)
            print(
                string.format(
                    "retrieve filename with prepend icon:%s\n",
                    vim.inspect(actual)
                )
            )
            assert_eq("~/github/linrongbin16/fzfx.nvim/README.md", actual)
        end)
    end)
    describe("[make_edit]", function()
        it("edit file without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local edit = actions.make_edit()
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
            }
            local actual = edit(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, 3)
            for i, line in ipairs(lines) do
                local expect = string.format("edit %s", vim.fn.expand(line))
                assert_eq(actual[i], expect)
            end
        end)
        it("edit file with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local edit = actions.make_edit()
            local lines = {
                " ~/github/linrongbin16/fzfx.nvim/README.md",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
            }
            local actual = edit(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, 3)
            for i, line in ipairs(lines) do
                local expect = string.format(
                    "edit %s",
                    vim.fn.expand(vim.fn.split(line)[2])
                )
                assert_eq(actual[i], expect)
            end
        end)
    end)
end)
