local cwd = vim.fn.getcwd()

describe("env", function()
    local assert_eq = assert.are.equal
    local assert_neq = assert.are_not.equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false
    local assert_truthy = assert.is.truthy
    local assert_falsy = assert.is.falsy

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    describe("[debug_enable]", function()
        it("is enabled", function()
            local env = require("fzfx.env")

            vim.env._FZFX_NVIM_DEBUG_ENABLE = 1
            assert_true(env.debug_enable())
        end)
        it("is disabled", function()
            local env = require("fzfx.env")

            vim.env._FZFX_NVIM_DEBUG_ENABLE = 0
            assert_false(env.debug_enable())
        end)
    end)

    describe("[icon_enable]", function()
        it("is enabled", function()
            local env = require("fzfx.env")

            vim.env._FZFX_NVIM_DEVICONS_PATH = "lazy/nvim-web-devicons"
            assert_true(env.icon_enable())
        end)
        it("is disabled", function()
            local env = require("fzfx.env")

            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            assert_false(env.icon_enable())
        end)
    end)
end)
