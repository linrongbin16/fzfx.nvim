local cwd = vim.fn.getcwd()

describe("schema", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local schema = require("fzfx.schema")
    local clazz = require("fzfx.clazz")
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
            assert_true(clazz.instanceof(command, schema.PreviewerConfig))
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
            assert_true(clazz.instanceof(command, schema.CommandConfig))
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
            assert_true(clazz.instanceof(interaction, schema.InteractionConfig))
            assert_eq(interaction.key, "key")
            assert_eq(type(interaction.interaction), "function")
            assert_eq(interaction.interaction(), "interact")
            assert_eq(interaction.reload_after_execute, true)
        end)
    end)
    describe("[GroupConfig]", function()
        it("makes a group", function()
            local group = schema.GroupConfig:make({
                commands = "commands",
                providers = "providers",
                previewers = "previewers",
            })
            assert_eq(type(group), "table")
            assert_true(clazz.instanceof(group, schema.GroupConfig))
            assert_eq(group.commands, "commands")
            assert_eq(group.providers, "providers")
            assert_eq(group.previewers, "previewers")
        end)
    end)
end)
