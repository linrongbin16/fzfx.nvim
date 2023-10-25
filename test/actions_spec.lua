local cwd = vim.fn.getcwd()

describe("actions", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        require("fzfx.config").setup()
        vim.api.nvim_command("cd " .. cwd)
        vim.opt.swapfile = false
    end)

    local DEVICONS_PATH =
        "~/github/linrongbin16/.config/nvim/lazy/nvim-web-devicons"
    local actions = require("fzfx.actions")
    local utils = require("fzfx.utils")
    local path = require("fzfx.path")
    local line_helpers = require("fzfx.line_helpers")
    describe("[nop]", function()
        it("do nothing", function()
            local nop = actions.nop
            assert_eq(type(nop), "function")
            assert_true(nop({}) == nil)
        end)
    end)
    describe("[_make_commands_for_find]", function()
        it("edit file without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
            }
            local actual = actions._make_edit_find_commands(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, 5)
            for i, line in ipairs(lines) do
                local expect = string.format(
                    "edit %s",
                    vim.fn.expand(path.normalize(line))
                )
                assert_eq(actual[i], expect)
            end
        end)
        it("edit file with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " ~/github/linrongbin16/fzfx.nvim/README.md",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
            }
            local actual = actions._make_edit_find_commands(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, 5)
            for i, line in ipairs(lines) do
                local first_space_pos = utils.string_find(line, " ")
                local expect = string.format(
                    "edit %s",
                    vim.fn.expand(path.normalize(line:sub(first_space_pos + 1)))
                )
                assert_eq(actual[i], expect)
            end
        end)
        it("run edit file command without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "README.md:17",
                "lua/fzfx.lua:30:17",
                "lua/fzfx/config.lua:37:hello world",
                "lua/fzfx/test/goodbye world/goodbye.lua",
                "lua/fzfx/test/goodbye world/world.txt",
                "lua/fzfx/test/hello world.txt",
            }
            actions.edit_find(lines)
            assert_true(true)
        end)
        it("run edit file command with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " README.md",
                "󰢱 lua/fzfx.lua",
                "󰢱 lua/fzfx/config.lua",
                "󰢱 lua/fzfx/test/goodbye world/goodbye.lua",
                "󰢱 lua/fzfx/test/goodbye world/world.txt",
                "󰢱 lua/fzfx/test/hello world.txt",
            }
            actions.edit_find(lines)
            assert_true(true)
        end)
    end)
    describe("[_make_edit_grep_commands]", function()
        it("edit file without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:hello world",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:12:81: goodbye",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:81:72:9129",
            }
            local actual = actions._make_edit_grep_commands(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, 6)
            for i, act in ipairs(actual) do
                if i <= #lines then
                    local expect = string.format(
                        "edit %s",
                        vim.fn.expand(
                            path.normalize(utils.string_split(lines[i], ":")[1])
                        )
                    )
                    assert_eq(act, expect)
                else
                    assert_eq(act, "call setpos('.', [0, 81, 1])")
                end
            end
        end)
        it("edit file with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " ~/github/linrongbin16/fzfx.nvim/README.md",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
            }
            local actual = actions._make_edit_grep_commands(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, 5)
            for i, line in ipairs(lines) do
                local first_space_pos = utils.string_find(line, " ")
                local expect = string.format(
                    "edit %s",
                    vim.fn.expand(path.normalize(line:sub(first_space_pos + 1)))
                )
                assert_eq(actual[i], expect)
            end
        end)
        it("run edit file command without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "README.md",
                "lua/fzfx.lua",
                "lua/fzfx/config.lua",
                "lua/fzfx/test/goodbye world/goodbye.lua",
                "lua/fzfx/test/goodbye world/world.txt",
                "lua/fzfx/test/hello world.txt",
            }
            actions.edit_find(lines)
            assert_true(true)
        end)
        it("run edit file command with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " README.md",
                "󰢱 lua/fzfx.lua",
                "󰢱 lua/fzfx/config.lua",
                "󰢱 lua/fzfx/test/goodbye world/goodbye.lua",
                "󰢱 lua/fzfx/test/goodbye world/world.txt",
                "󰢱 lua/fzfx/test/hello world.txt",
            }
            actions.edit_find(lines)
            assert_true(true)
        end)
    end)
    describe("[_make_edit_rg_commands]", function()
        it("edit file without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:hello world",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:12:81: goodbye",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:81:71:9129",
            }
            local actual = actions._make_edit_rg_commands(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, 6)
            for i, act in ipairs(actual) do
                if i <= #lines then
                    local expect = string.format(
                        "edit %s",
                        vim.fn.expand(
                            path.normalize(utils.string_split(lines[i], ":")[1])
                        )
                    )
                    assert_eq(act, expect)
                else
                    assert_eq(act, "call setpos('.', [0, 81, 71])")
                end
            end
        end)
        it("edit file with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " ~/github/linrongbin16/fzfx.nvim/README.md",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
            }
            local actual = actions._make_edit_rg_commands(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, 5)
            for i, line in ipairs(lines) do
                local first_space_pos = utils.string_find(line, " ")
                local expect = string.format(
                    "edit %s",
                    vim.fn.expand(path.normalize(line:sub(first_space_pos + 1)))
                )
                assert_eq(actual[i], expect)
            end
        end)
        it("run edit file command without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "README.md",
                "lua/fzfx.lua",
                "lua/fzfx/config.lua",
                "lua/fzfx/test/goodbye world/goodbye.lua",
                "lua/fzfx/test/goodbye world/world.txt",
                "lua/fzfx/test/hello world.txt",
            }
            actions.edit_find(lines)
            assert_true(true)
        end)
        it("run edit file command with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " README.md",
                "󰢱 lua/fzfx.lua",
                "󰢱 lua/fzfx/config.lua",
                "󰢱 lua/fzfx/test/goodbye world/goodbye.lua",
                "󰢱 lua/fzfx/test/goodbye world/world.txt",
                "󰢱 lua/fzfx/test/hello world.txt",
            }
            actions.edit_find(lines)
            assert_true(true)
        end)
    end)
    describe("[_make_setqflist_find_items]", function()
        it("set files without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
            }
            local actual = actions._make_setqflist_find_items(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, #lines)
            for i, act in ipairs(actual) do
                local line = lines[i]
                local expect = line_helpers.parse_find(line)
                assert_eq(type(act), "table")
                assert_eq(act.filename, expect)
                assert_eq(act.lnum, 1)
                assert_eq(act.col, 1)
            end
        end)
        it("set files with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " ~/github/linrongbin16/fzfx.nvim/README.md",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
            }
            local actual = actions._make_setqflist_find_items(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, #lines)
            for i, act in ipairs(actual) do
                local line = lines[i]
                local expect = line_helpers.parse_find(line)
                assert_eq(type(act), "table")
                assert_eq(act.filename, expect)
                assert_eq(act.lnum, 1)
                assert_eq(act.col, 1)
            end
        end)
    end)
    describe("[_make_setqflist_rg_items]", function()
        it("set rg results without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md:1:3:hello world",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:10:83: ok ok",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:81:3: local query = 'hello'",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:4:1: print('goodbye world')",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:3:10: hello world",
            }
            local actual = actions._make_setqflist_rg_items(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, #lines)
            for i, act in ipairs(actual) do
                local line = lines[i]
                local expect = line_helpers.parse_rg(line)
                assert_eq(type(act), "table")
                assert_eq(act.filename, expect.filename)
                assert_eq(act.lnum, expect.lineno)
                assert_eq(act.col, expect.column)
                assert_eq(act.text, line:sub(utils.string_rfind(line, ":") + 1))
            end
        end)
        it("set rg results with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " ~/github/linrongbin16/fzfx.nvim/README.md:1:3:hello world",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:10:83: ok ok",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:81:3: local query = 'hello'",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:4:1: print('goodbye world')",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:3:10: hello world",
            }
            local actual = actions._make_setqflist_rg_items(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, #lines)
            for i, act in ipairs(actual) do
                local line = lines[i]
                local expect = line_helpers.parse_rg(line)
                assert_eq(type(act), "table")
                assert_eq(act.filename, expect.filename)
                assert_eq(act.lnum, expect.lineno)
                assert_eq(act.col, expect.column)
                assert_eq(act.text, line:sub(utils.string_rfind(line, ":") + 1))
            end
        end)
    end)
    describe("[_make_setqflist_grep_items]", function()
        it("set grep results without icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = nil
            local lines = {
                "~/github/linrongbin16/fzfx.nvim/README.md:1:hello world",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:10: ok ok",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:81: local query = 'hello'",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:4: print('goodbye world')",
                "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:3: hello world",
            }
            local actual = actions._make_setqflist_grep_items(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, #lines)
            for i, act in ipairs(actual) do
                local line = lines[i]
                local expect = line_helpers.parse_grep(line)
                assert_eq(type(act), "table")
                assert_eq(act.filename, expect.filename)
                assert_eq(act.lnum, expect.lineno)
                assert_eq(act.col, 1)
                assert_eq(act.text, line:sub(utils.string_rfind(line, ":") + 1))
            end
        end)
        it("set grep results with prepend icon", function()
            vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
            local lines = {
                " ~/github/linrongbin16/fzfx.nvim/README.md:1:hello world",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:10: ok ok",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:81: local query = 'hello'",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:4: print('goodbye world')",
                "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:3: hello world",
            }
            local actual = actions._make_setqflist_grep_items(lines)
            assert_eq(type(actual), "table")
            assert_eq(#actual, #lines)
            for i, act in ipairs(actual) do
                local line = lines[i]
                local expect = line_helpers.parse_grep(line)
                assert_eq(type(act), "table")
                assert_eq(act.filename, expect.filename)
                assert_eq(act.lnum, expect.lineno)
                assert_eq(act.col, 1)
                assert_eq(act.text, line:sub(utils.string_rfind(line, ":") + 1))
            end
        end)
    end)
    describe("[_make_feed_vim_command_params]", function()
        it("feedkeys", function()
            local actual = actions._make_feed_vim_command_params({
                "FzfxCommands    Y | N | N/A  ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:215",
            })
            print(string.format("feed vim command:%s\n", vim.inspect(actual)))
            -- assert_true(actual == nil)
        end)
    end)
    describe("[_make_feed_vim_key_params]", function()
        it("feed normal key", function()
            local feedtype, input, mode = actions._make_feed_vim_key_params({
                '<C-Tab>                                      n   |Y      |N     |N      "<C-C><C-W>w"',
            })
            print(
                string.format(
                    "feed normal key:%s, %s, %s\n",
                    vim.inspect(feedtype),
                    vim.inspect(input),
                    vim.inspect(mode)
                )
            )
            assert_eq(feedtype, "feedkeys")
            assert_eq(type(input), "string")
            assert_true(string.len(input --[[@as string]]) > 0)
            assert_eq(mode, "n")
        end)
        it("feed operator-pending key", function()
            local feedtype, input, mode = actions._make_feed_vim_key_params({
                '<C-Tab>                                      o   |Y      |N     |N      "<C-C><C-W>w"',
            })
            print(
                string.format(
                    "feed operator-pending key:%s, %s, %s\n",
                    vim.inspect(feedtype),
                    vim.inspect(input),
                    vim.inspect(mode)
                )
            )
            assert_true(feedtype == nil)
            assert_true(input == nil)
            assert_true(mode == nil)
        end)
        it("feed <plug>", function()
            local feedtype, input, mode = actions._make_feed_vim_key_params({
                "<Plug>(YankyCycleBackward)                   n   |Y      |N     |Y      ~/.config/nvim/lazy/yanky.nvim/lua/yanky.lua:290",
            })
            print(
                string.format(
                    "feed <plug> key:%s, %s, %s\n",
                    vim.inspect(feedtype),
                    vim.inspect(input),
                    vim.inspect(mode)
                )
            )
            assert_eq(feedtype, "cmd")
            assert_eq(type(input), "string")
            assert_true(utils.string_startswith(input, [[execute "normal \]]))
        end)
    end)
    describe("[_make_git_checkout_command]", function()
        it("checkout local git branch", function()
            local lines = {
                "main",
                "master",
                "my-plugin-dev",
                "test-config1",
            }
            for _, line in ipairs(lines) do
                assert_eq(
                    string.format("!git checkout %s", line),
                    actions._make_git_checkout_command({ line })
                )
            end
        end)
        it("checkout remote git branch", function()
            local lines = {
                "origin/HEAD -> origin/main",
                "origin/main",
                "origin/my-plugin-dev",
                "origin/ci-fix-create-tags",
                "origin/ci-verbose",
                "origin/docs-table",
                "origin/feat-setqflist",
                "origin/feat-vim-commands",
                "origin/main",
                "origin/release-please--branches--main--components--fzfx.nvim",
            }
            for i, line in ipairs(lines) do
                if utils.string_find(line, "origin/main") then
                    local actual = actions._make_git_checkout_command({ line })
                    print(
                        string.format("git checkout remote[%d]:%s\n", i, actual)
                    )
                    assert_eq(string.format("!git checkout main"), actual)
                else
                    assert_eq(
                        string.format(
                            "!git checkout %s",
                            line:sub(string.len("origin/") + 1)
                        ),
                        actions._make_git_checkout_command({ line })
                    )
                end
            end
        end)
        it("checkout all git branch", function()
            local lines = {
                "main",
                "my-plugin-dev",
                "remotes/origin/HEAD -> origin/main",
                "remotes/origin/main",
                "remotes/origin/my-plugin-dev",
                "remotes/origin/ci-fix-create-tags",
                "remotes/origin/ci-verbose",
            }
            for i, line in ipairs(lines) do
                if utils.string_find(line, "main") then
                    assert_eq(
                        string.format("!git checkout main"),
                        actions._make_git_checkout_command({ line })
                    )
                else
                    local actual = actions._make_git_checkout_command({ line })
                    print(string.format("git checkout all[%d]:%s\n", i, actual))
                    local split_pos = utils.string_find(line, "remotes/origin/")
                    if split_pos then
                        assert_eq(
                            string.format(
                                "!git checkout %s",
                                line:sub(string.len("remotes/origin/") + 1)
                            ),
                            actual
                        )
                    else
                        assert_eq(
                            string.format("!git checkout %s", line),
                            actual
                        )
                    end
                end
            end
        end)
    end)
    describe("[_make_yank_git_commit_command]", function()
        it("yank git commits", function()
            local lines = {
                "3c2e32c 2023-10-10 linrongbin16 perf(schema): deprecate 'ProviderConfig' & 'PreviewerConfig' (#268)",
                "2bdcef7 2023-10-10 linrongbin16 feat(schema): add 'PreviewerConfig' detection (#266)",
                "5cabd9b 2023-10-10 linrongbin16 refactor(schema): deprecate 'ProviderConfig' (#264)",
                "9eac0c0 2023-10-10 linrongbin16 fix(push): revert direct push to main branch",
                "78a195a 2023-10-10 linrongbin16 refactor(schema): deprecate 'ProviderConfig'",
            }
            for _, line in ipairs(lines) do
                assert_eq(
                    string.format("let @+ = '%s'", line:sub(1, 7)),
                    actions._make_yank_git_commit_command({ line })
                )
            end
        end)
    end)
end)
