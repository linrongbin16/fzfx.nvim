-- :lua MiniTest.run_file()

local new_set = MiniTest.new_set
local expect = MiniTest.expect
local add_note = MiniTest.add_note
local child = MiniTest.new_child_neovim()

local T = new_set({
    hooks = {
        pre_once = function()
            child.restart({ "-u", "lua/tests/minimal_termguicolors_init.lua" })
            child.lua([[ M = require('fzfx.shell') ]])
        end,
        post_once = child.stop,
    },
})

T["nvim_exec"] = new_set()

T["nvim_exec"]["default"] = function()
    local nvim_exec = child.lua_get([[ M.nvim_exec() ]])
    add_note(string.format("nvim_exec: %s", nvim_exec))
    expect.equality(vim.fn.executable(nvim_exec) > 0, true)
end

T["fzf_exec"] = new_set()

T["fzf_exec"]["default"] = function()
    local fzf_exec = child.lua_get([[ M.fzf_exec() ]])
    add_note(string.format("fzf_exec: %s", fzf_exec))
    child.type_keys("y<CR>")
    expect.equality(vim.fn.executable(fzf_exec) > 0, true)
end

return T
