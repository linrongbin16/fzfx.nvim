-- :lua MiniTest.run_file()

local new_set = MiniTest.new_set
local expect = MiniTest.expect
local add_note = MiniTest.add_note
local child = MiniTest.new_child_neovim()

local T = new_set({
    hooks = {
        pre_once = function()
            child.restart({ "-u", "lua/tests/minimal_termguicolors_init.lua" })
            child.lua([[ require('fzfx').setup() ]])
        end,
        post_once = child.stop,
    },
})

T["commands"] = new_set()

T["commands"]["files"] = function()
    local global_commands =
        child.lua_get([[ vim.api.nvim_get_commands({builtin=false}) ]])
    expect.equality(type(global_commands), "table")
    -- add_note(
    --     string.format(
    --         "global commands(%s):%s",
    --         type(global_commands),
    --         vim.inspect(global_commands)
    --     )
    -- )
    local count = 0
    for name, opts in pairs(global_commands) do
        if name == "FzfxFiles" then
            count = count + 1
            expect.equality(type(opts), "table")
            expect.equality(opts["bang"], true)
            expect.equality(opts["nargs"], "?")
            expect.equality(opts["range"] == nil or not opts["range"], true)
            expect.equality(opts["complete"], "dir")
            expect.equality(opts["name"], name)
            add_note(string.format("command %s:%s", name, vim.inspect(opts)))
        end
        if name == "FzfxFilesU" then
            count = count + 1
            expect.equality(type(opts), "table")
            expect.equality(opts["bang"], true)
            expect.equality(opts["nargs"], "?")
            expect.equality(opts["range"] == nil or not opts["range"], true)
            expect.equality(opts["complete"], "dir")
            expect.equality(opts["name"], name)
            add_note(string.format("command %s:%s", name, vim.inspect(opts)))
        end
        if name == "FzfxFilesV" then
            count = count + 1
            expect.equality(type(opts), "table")
            expect.equality(opts["bang"], true)
            expect.equality(opts["range"], ".")
            expect.equality(opts["name"], name)
            add_note(string.format("command %s:%s", name, vim.inspect(opts)))
        end
        if name == "FzfxFilesUV" then
            count = count + 1
            expect.equality(type(opts), "table")
            expect.equality(opts["bang"], true)
            expect.equality(opts["range"], ".")
            expect.equality(opts["name"], name)
            add_note(string.format("command %s:%s", name, vim.inspect(opts)))
        end
        if name == "FzfxFilesW" then
            count = count + 1
            expect.equality(type(opts), "table")
            expect.equality(opts["bang"], true)
            expect.equality(opts["name"], name)
            add_note(string.format("command %s:%s", name, vim.inspect(opts)))
        end
        if name == "FzfxFilesUW" then
            count = count + 1
            expect.equality(type(opts), "table")
            expect.equality(opts["bang"], true)
            expect.equality(opts["name"], name)
            add_note(string.format("command %s:%s", name, vim.inspect(opts)))
        end
    end
    expect.equality(count, 6)
end

T["commands"]["live_grep"] = function()
    local global_commands =
        child.lua_get([[ vim.api.nvim_get_commands({builtin=false}) ]])
    expect.equality(type(global_commands), "table")
    -- add_note(
    --     string.format(
    --         "global commands(%s):%s",
    --         type(global_commands),
    --         vim.inspect(global_commands)
    --     )
    -- )
    local count = 0
    for name, opts in pairs(global_commands) do
        if name == "FzfxLiveGrep" then
            count = count + 1
            expect.equality(type(opts), "table")
            expect.equality(opts["bang"], true)
            expect.equality(opts["nargs"], "*")
            expect.equality(opts["range"] == nil or not opts["range"], true)
            expect.equality(opts["name"], name)
            add_note(string.format("command %s:%s", name, vim.inspect(opts)))
        end
        if name == "FzfxLiveGrepU" then
            count = count + 1
            expect.equality(type(opts), "table")
            expect.equality(opts["bang"], true)
            expect.equality(opts["nargs"], "*")
            expect.equality(opts["range"] == nil or not opts["range"], true)
            expect.equality(opts["name"], name)
            add_note(string.format("command %s:%s", name, vim.inspect(opts)))
        end
        if name == "FzfxLiveGrepV" then
            count = count + 1
            expect.equality(type(opts), "table")
            expect.equality(opts["bang"], true)
            expect.equality(opts["range"], ".")
            expect.equality(opts["name"], name)
            add_note(string.format("command %s:%s", name, vim.inspect(opts)))
        end
        if name == "FzfxLiveGrepUV" then
            count = count + 1
            expect.equality(type(opts), "table")
            expect.equality(opts["bang"], true)
            expect.equality(opts["range"], ".")
            expect.equality(opts["name"], name)
            add_note(string.format("command %s:%s", name, vim.inspect(opts)))
        end
        if name == "FzfxLiveGrepW" then
            count = count + 1
            expect.equality(type(opts), "table")
            expect.equality(opts["bang"], true)
            expect.equality(opts["name"], name)
            add_note(string.format("command %s:%s", name, vim.inspect(opts)))
        end
        if name == "FzfxLiveGrepUW" then
            count = count + 1
            expect.equality(type(opts), "table")
            expect.equality(opts["bang"], true)
            expect.equality(opts["name"], name)
            add_note(string.format("command %s:%s", name, vim.inspect(opts)))
        end
    end
    expect.equality(count, 6)
end

return T
