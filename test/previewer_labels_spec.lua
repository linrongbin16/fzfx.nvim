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
    describe("[_make_find_previewer_label/find_previewer_label]", function()
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
                local actual1 = f(line)
                assert_eq(type(actual1), "string")
                assert_true(utils.string_endswith(line, actual1))
                local actual2 = previewer_labels.find_previewer_label(line)
                assert_eq(type(actual2), "string")
                assert_true(utils.string_endswith(line, actual2))
                assert_eq(actual1, actual2)
            end
        end)
    end)
    describe("[_make_rg_previewer_label/rg_previewer_label]", function()
        it("makes", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md:1:1:ok",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1:2:hello",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:3:hello world",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:12:81: goodbye",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:81:71:9129",
            }
            for _, line in ipairs(lines) do
                local f = previewer_labels._make_rg_previewer_label(line)
                local actual1 = f(line)
                assert_eq(type(actual1), "string")
                assert_eq(type(utils.string_find(line, actual1)), "number")
                assert_true(utils.string_find(line, actual1) > 0)
                local actual2 = previewer_labels.rg_previewer_label(line)
                assert_eq(type(actual2), "string")
                assert_eq(type(utils.string_find(line, actual2)), "number")
                assert_true(utils.string_find(line, actual2) > 0)
                assert_eq(actual1, actual2)
                assert_eq(
                    utils.string_find(line, actual1),
                    utils.string_find(line, actual2)
                )
            end
        end)
    end)
    describe("[_make_grep_previewer_label/grep_previewer_label]", function()
        it("makes", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md:73",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:hello world",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:12:81: goodbye",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:81:72:9129",
            }
            for _, line in ipairs(lines) do
                local f = previewer_labels._make_grep_previewer_label(line)
                local actual1 = f(line)
                assert_eq(type(actual1), "string")
                assert_eq(type(utils.string_find(line, actual1)), "number")
                assert_true(utils.string_find(line, actual1) > 0)
                local actual2 = previewer_labels.grep_previewer_label(line)
                assert_eq(type(actual2), "string")
                assert_eq(type(utils.string_find(line, actual2)), "number")
                assert_true(utils.string_find(line, actual2) > 0)
                assert_eq(actual1, actual2)
                assert_eq(
                    utils.string_find(line, actual1),
                    utils.string_find(line, actual2)
                )
            end
        end)
    end)
end)
