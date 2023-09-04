local cwd = vim.fn.getcwd()

describe("clazz", function()
    local assert_eq = assert.are.equal
    local assert_neq = assert.are_not.equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false
    local assert_truthy = assert.is.truthy
    local assert_falsy = assert.is.falsy

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    describe("[Clazz]", function()
        it("defines an empty class", function()
            local Clazz = require("fzfx.clazz").Clazz

            local clz = Clazz:implement()
            assert_true(type(clz) == "table")
            assert_true(clz.__classname == "object")
            local obj = vim.tbl_deep_extend("force", vim.deepcopy(clz), {})
            assert_true(type(obj) == "table")
            assert_true(Clazz:instanceof(obj, clz))
            assert_true(obj.__classname == "object")
        end)
        it("defines a ProviderConfig class", function()
            local Clazz = require("fzfx.clazz").Clazz

            local ProviderConfigClass =
                Clazz:implement("test.clazz_spec.ProviderConfigClass", {
                    key = nil,
                    provider = nil,
                    provider_type = nil,
                    line_type = nil,
                    line_delimiter = nil,
                    line_pos = nil,
                })
            function ProviderConfigClass:make(opts)
                return vim.tbl_deep_extend(
                    "force",
                    vim.deepcopy(ProviderConfigClass),
                    opts or {}
                )
            end
            assert_true(type(ProviderConfigClass) == "table")
            assert_true(
                ProviderConfigClass.__classname
                    == "test.clazz_spec.ProviderConfigClass"
            )
            local provider = ProviderConfigClass:make({
                key = "key",
                provider = "provider",
                provider_type = "provider_type",
            })
            assert_true(type(provider) == "table")
            assert_true(Clazz:instanceof(provider, ProviderConfigClass))
            assert_eq(provider.key, "key")
            assert_eq(provider.provider, "provider")
            assert_eq(provider.provider_type, "provider_type")
            assert_eq(provider.line_type, nil)
            assert_eq(provider.line_delimiter, nil)
            assert_eq(provider.line_pos, nil)
        end)
    end)
end)
