local cwd = vim.fn.getcwd()

describe("ui", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
        vim.o.swapfile = false
        vim.cmd([[edit README.md]])
    end)

    local ui = require("fzfx.ui")
    describe("[confirm_discard_buffer_modified]", function()
        it("confirm", function()
            vim.fn.feedkeys("i", "m")
            vim.fn.feedkeys("i", "m")
            vim.fn.feedkeys("i", "m")
            vim.fn.feedkeys("i", "m")
            ui.confirm_discard_buffer_modified(0, function()
                assert_true(true)
            end)
            vim.fn.feedkeys("y", "m")
        end)
        it("cancelled", function()
            vim.fn.feedkeys("i", "m")
            vim.fn.feedkeys("i", "m")
            vim.fn.feedkeys("i", "m")
            vim.fn.feedkeys("i", "m")
            ui.confirm_discard_buffer_modified(0, function()
                assert_true(true)
            end)
            vim.fn.feedkeys("n", "m")
        end)
    end)
end)
