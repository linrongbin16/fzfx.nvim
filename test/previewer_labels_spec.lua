local cwd = vim.fn.getcwd()

describe("previewer_labels", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local utils = require("fzfx.utils")
    local previewer_labels = require("fzfx.previewer_labels")
    describe("[_make_find_previewer_label]", function()
        it("makes", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
            }
            for _, line in ipairs(lines) do
                local f = previewer_labels._make_find_previewer_label(line)
                local actual = f(line)
                assert_eq(type(actual), "string")
                assert_true(utils.string_endswith(line, actual))
            end
        end)
    end)
    describe("[find_previewer_label]", function()
        it("makes", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
            }
            for _, line in ipairs(lines) do
                local actual = previewer_labels.find_previewer_label(line)
                assert_eq(type(actual), "string")
                assert_true(utils.string_endswith(line, actual))
            end
        end)
    end)
end)
