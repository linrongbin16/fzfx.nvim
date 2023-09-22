local cwd = vim.fn.getcwd()

describe("clazz", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local clazz = require("fzfx.clazz")
    local ProviderConfig = require("fzfx.schema").ProviderConfig
    describe("[instanceof]", function()
        it("defines an empty class", function()
            local obj = ProviderConfig:make({
                key = "a",
                provider = "ls",
            })
            local a = {
                key = "a",
                provider = "ls",
            }
            assert_true(clazz.instanceof(obj, ProviderConfig))
            assert_false(clazz.instanceof(a, ProviderConfig))
        end)
    end)
end)
