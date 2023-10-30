local cwd = vim.fn.getcwd()

describe("fzfx", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    describe("[setup]", function()
        it("is enabled", function()
            require("fzfx").setup()
            assert_true(true)
        end)
    end)
end)
