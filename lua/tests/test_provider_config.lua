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
        add_note(string.format("pc_key (%s) == 'ctrl-u'", pc_key))
        expect.equality(pc_key, "ctrl-u")
    end
end

return T
