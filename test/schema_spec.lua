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
                line_type = "file",
                line_delimiter = ":",
                line_pos = 1,
            })
            assert_eq(type(command), "table")
            assert_true(Clazz:instanceof(command, schema.ProviderConfig))
            assert_eq(command.key, command_key)
            assert_eq(type(command.provider), "function")
            assert_eq(command.provider(), command_provider())
            assert_eq(command.provider_type, command_provider_type)
            assert_eq(command.line_type, "file")
            assert_eq(command.line_delimiter, ":")
            assert_eq(command.line_pos, 1)
        end)
    end)
    describe("[PreviewerConfig]", function()
        it("makes a command previewer", function()
            local command_previewer = function(line)
                return string.format("cat %s", line)
            end
            local command_previewer_type = "command"
            local command = schema.PreviewerConfig:make({
                previewer = command_previewer,
                previewer_type = command_previewer_type,
            })
            assert_eq(type(command), "table")
            assert_true(Clazz:instanceof(command, schema.PreviewerConfig))
            assert_eq(type(command.previewer), "function")
            assert_eq(command.previewer(), command_previewer())
            assert_eq(command.previewer_type, command_previewer_type)
        end)
    end)
    describe("[CommandConfig]", function()
        it("makes a command", function()
            local command = schema.CommandConfig:make({
                name = "command",
                feed = "args",
                opts = { range = true },
            })
            assert_eq(type(command), "table")
            assert_true(Clazz:instanceof(command, schema.CommandConfig))
            assert_eq(command.name, "command")
        end)
    end)
    describe("[InteractionConfig]", function()
        it("makes an interaction", function()
            local interact = function(line)
                return "interact"
            end
            local interaction = schema.InteractionConfig:make({
                key = "key",
                interaction = interact,
                reload_after_execute = true,
            })
            assert_eq(type(interaction), "table")
            assert_true(Clazz:instanceof(interaction, schema.InteractionConfig))
            assert_eq(interaction.key, "key")
            assert_eq(type(interaction.interaction), "function")
            assert_eq(interaction.interaction(), "interact")
            assert_eq(interaction.reload_after_execute, true)
        end)
    end)
end)
