local cwd = vim.fn.getcwd()

describe("schema", function()
    local assert_eq = assert.are.equal
    local assert_neq = assert.are_not.equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false
    local assert_truthy = assert.is.truthy
    local assert_falsy = assert.is.falsy

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local schema = require("fzfx.schema")
    local Clazz = require("fzfx.clazz").Clazz
    describe("[ProviderConfig]", function()
        it("makes a plain provider", function()
            local plain_key = "plain"
            local plain_provider = "ls -la"
            local plain_provider_type = "plain"
            local plain = schema.ProviderConfig:make({
                key = plain_key,
                provider = plain_provider,
                provider_type = plain_provider_type,
            })
            assert_eq(type(plain), "table")
            assert_true(Clazz:instanceof(plain, schema.ProviderConfig))
            assert_eq(plain.key, plain_key)
            assert_eq(plain.provider, plain_provider)
            assert_eq(plain.provider_type, plain_provider_type)
        end)
        it("makes a command provider", function()
            local command_key = "command"
            local command_provider = function()
                return "ls -la"
            end
            local command_provider_type = "command"
            local command = schema.ProviderConfig:make({
                key = command_key,
                provider = command_provider,
                provider_type = command_provider_type,
            })
            assert_eq(type(command), "table")
            assert_true(Clazz:instanceof(command, schema.ProviderConfig))
            assert_eq(command.key, command_key)
            assert_eq(type(command.provider), "function")
            assert_eq(command.provider(), command_provider())
            assert_eq(command.provider_type, command_provider_type)
        end)
    end)
end)
