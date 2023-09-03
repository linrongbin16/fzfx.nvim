-- :lua MiniTest.run_file()

local new_set = MiniTest.new_set
local expect = MiniTest.expect
local add_note = MiniTest.add_note
local child = MiniTest.new_child_neovim()

local T = new_set({
    hooks = {
        pre_once = function()
            child.restart({ "-u", "lua/tests/minimal_termguicolors_init.lua" })
            child.lua(
                [[ ProviderConfig = require('fzfx.schema').ProviderConfig ]]
            )
        end,
        post_once = child.stop,
    },
})

T["provider_config"] = new_set()

T["provider_config"]["simple"] = function()
    do
        local pc_type = child.lua(string.format([[
        local pc = ProviderConfig:make({
            key = "ctrl-u",
            provider = "fd . -tf",
        })
        return type(pc)
        ]]))
        add_note(string.format("pc_type (%s) == 'table'", pc_type))
        expect.equality(pc_type, "table")
    end
    do
        local pc_key = child.lua(string.format([[
        local pc = ProviderConfig:make({
            key = "ctrl-u",
            provider = "fd . -tf",
        })
        return pc.key
        ]]))
        add_note(string.format("pc.key (%s) == 'ctrl-u'", pc_key.key))
        expect.equality(pc_key.key, "ctrl-u")
    end
    do
        local pc_provider = child.lua(string.format([[
        local pc = ProviderConfig:make({
            key = "ctrl-u",
            provider = "fd . -tf",
        })
        return pc.provider
        ]]))
        add_note(string.format("pc.provider (%s) == 'fd . -tf'", pc_provider))
        expect.equality(pc_provider, "fd . -tf")
    end
    do
        local pc_provider_type = child.lua(string.format([[
        local pc = ProviderConfig:make({
            key = "ctrl-u",
            provider = "fd . -tf",
        })
        return pc.provider_type
        ]]))
        add_note(
            string.format("pc.provider_type (%s) == 'plain'", pc_provider_type)
        )
        expect.equality(pc_provider_type, "plain")
    end
end

return T
