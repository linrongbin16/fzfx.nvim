local cwd = vim.fn.getcwd()

describe("line_helpers", function()
    local assert_eq = assert.are.equal
    local assert_neq = assert.are_not.equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false
    local assert_truthy = assert.is.truthy
    local assert_falsy = assert.is.falsy

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local line_helpers = require("fzfx.line_helpers")
    local DEVICONS_PATH =
        "~/github/linrongbin16/.config/nvim/lazy/nvim-web-devicons"
    describe("[parse_filename]", function()
        it("parse filename without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local expect = "~/github/linrongbin16/fzfx.nvim/README.md"
            local actual = line_helpers.parse_filename(expect)
            assert_eq(expect, actual)
        end)
        it("parse filename with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local input = " ~/github/linrongbin16/fzfx.nvim/README.md"
            local actual = line_helpers.parse_filename(input)
            print(
                string.format(
                    "parse filename with prepend icon:%s\n",
                    vim.inspect(actual)
                )
            )
            assert_eq("~/github/linrongbin16/fzfx.nvim/README.md", actual)
        end)
    end)
end)
