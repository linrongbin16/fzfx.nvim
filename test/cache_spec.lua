local cwd = vim.fn.getcwd()

describe("cache", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local cache = require("fzfx.cache")
    describe("[cache]", function()
        it("put/get/has", function()
            assert_false(cache.has("a"))
            assert_true(cache.get("a") == nil)
            assert_eq(cache.get("a", "b"), "b")
            assert_eq(cache.put("a", 1), 1)
            assert_true(cache.has("a"))
            assert_eq(cache.get("a"), 1)
            assert_eq(cache.get("a", "b"), 1)
        end)
    end)
end)
