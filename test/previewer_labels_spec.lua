---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("previewer_labels", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local strs = require("fzfx.lib.strings")
  local line_helpers = require("fzfx.line_helpers")
  local previewer_labels = require("fzfx.previewer_labels")
  describe("[_make_find_previewer_label/find_previewer_label]", function()
    it("makes", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
      }
      for _, line in ipairs(lines) do
        local f = previewer_labels._make_find_previewer_label(line)
        local actual1 = f(line)
        assert_eq(type(actual1), "string")
        assert_true(strs.endswith(line, actual1))
        local actual2 = previewer_labels.find_previewer_label(line)
        assert_eq(type(actual2), "string")
        assert_true(strs.endswith(line, actual2))
        assert_eq(actual1, actual2)
      end
    end)
  end)
  describe("[_make_rg_previewer_label/rg_previewer_label]", function()
    it("makes", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md:1:1:ok",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1:2:hello",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:3:hello world",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:12:81: goodbye",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:81:71:9129",
      }
      for _, line in ipairs(lines) do
        local f = previewer_labels._make_rg_previewer_label(line)
        local actual1 = f(line)
        assert_eq(type(actual1), "string")
        assert_eq(type(strs.find(line, actual1)), "number")
        assert_true(strs.find(line, actual1) > 0)
        local actual2 = previewer_labels.rg_previewer_label(line)
        assert_eq(type(actual2), "string")
        assert_eq(type(strs.find(line, actual2)), "number")
        assert_true(strs.find(line, actual2) > 0)
        assert_eq(actual1, actual2)
        assert_eq(strs.find(line, actual1), strs.find(line, actual2))
      end
    end)
  end)
  describe("[_make_grep_previewer_label/grep_previewer_label]", function()
    it("makes", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md:73",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:hello world",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:12:81: goodbye",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:81:72:9129",
      }
      for _, line in ipairs(lines) do
        local f = previewer_labels._make_grep_previewer_label(line)
        local actual1 = f(line)
        assert_eq(type(actual1), "string")
        assert_eq(type(strs.find(line, actual1)), "number")
        assert_true(strs.find(line, actual1) > 0)
        local actual2 = previewer_labels.grep_previewer_label(line)
        assert_eq(type(actual2), "string")
        assert_eq(type(strs.find(line, actual2)), "number")
        assert_true(strs.find(line, actual2) > 0)
        assert_eq(actual1, actual2)
        assert_eq(strs.find(line, actual1), strs.find(line, actual2))
      end
    end)
  end)
  describe(
    "[vim_command_previewer_label/_make_vim_command_previewer_label]",
    function()
      local CONTEXT = {
        name_width = 17,
        opts_width = 37,
      }
      it("previews location", function()
        local lines = {
          ":                 N   |Y  |N/A  |N/A  |N/A              /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/doc/index.txt:1121",
          ":!                N   |Y  |N/A  |N/A  |N/A              /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/doc/index.txt:1122",
          ":Next             N   |Y  |N/A  |N/A  |N/A              /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/doc/index.txt:1124",
        }
        for _, line in ipairs(lines) do
          local actual =
            previewer_labels.vim_command_previewer_label(line, CONTEXT)
          assert_eq(type(actual), "string")
          local actual_splits = strs.split(actual, ":")
          assert_eq(#actual_splits, 2)
          assert_true(strs.find(line, actual_splits[1]) > 0)
          assert_true(strs.endswith(line, actual_splits[2]))

          local f = previewer_labels._make_vim_command_previewer_label(
            line_helpers.parse_vim_command,
            "Definition"
          )
          local actual2 = f(line, CONTEXT)
          assert_eq(actual, actual2)
        end
      end)
      it("previews description", function()
        local lines = {
          ':bdelete          N   |Y  |N/A  |N/A  |N/A              "delete buffer"',
        }
        for _, line in ipairs(lines) do
          local actual =
            previewer_labels.vim_command_previewer_label(line, CONTEXT)
          assert_eq(type(actual), "string")
          assert_eq(actual, "Definition")

          local f = previewer_labels._make_vim_command_previewer_label(
            line_helpers.parse_vim_command,
            "Definition"
          )
          local actual2 = f(line, CONTEXT)
          assert_eq(actual, actual2)
        end
      end)
    end
  )
  describe("[vim_keymap_previewer_label]", function()
    local CONTEXT = {
      key_width = 44,
      opts_width = 26,
    }
    it("previews location", function()
      local lines = {
        "<C-F>                                            |N      |N     |N      ~/.config/nvim/lazy/nvim-cmp/lua/cmp/utils/keymap.lua:127",
        "<CR>                                             |N      |N     |N      ~/.config/nvim/lazy/nvim-cmp/lua/cmp/utils/keymap.lua:127",
        "<Plug>(YankyGPutAfterShiftRight)             n   |Y      |N     |Y      ~/.config/nvim/lazy/yanky.nvim/lua/yanky.lua:369",
      }
      for _, line in ipairs(lines) do
        local actual =
          previewer_labels.vim_keymap_previewer_label(line, CONTEXT)
        assert_eq(type(actual), "string")
        local actual_splits = strs.split(actual, ":")
        assert_eq(#actual_splits, 2)
        assert_true(strs.find(line, actual_splits[1]) > 0)
        assert_true(strs.endswith(line, actual_splits[2]))

        local f = previewer_labels._make_vim_command_previewer_label(
          line_helpers.parse_vim_keymap,
          "Definition"
        )
        local actual2 = f(line, CONTEXT)
        assert_eq(actual, actual2)
      end
    end)
    it("previews definition", function()
      local lines = {
        '%                                            n   |N      |N     |Y      "<Plug>(matchup-%)"',
        '&                                            n   |Y      |N     |N      ":&&<CR>"',
        '<2-LeftMouse>                                n   |N      |N     |Y      "<Plug>(matchup-double-click)"',
      }
      for _, line in ipairs(lines) do
        local actual =
          previewer_labels.vim_keymap_previewer_label(line, CONTEXT)
        assert_eq(type(actual), "string")
        assert_eq(actual, "Definition")

        local f = previewer_labels._make_vim_command_previewer_label(
          line_helpers.parse_vim_keymap,
          "Definition"
        )
        local actual2 = f(line, CONTEXT)
        assert_eq(actual, actual2)
      end
    end)
  end)
  describe("[_make_file_explorer_previewer_label/ls/eza/lsd]", function()
    it("ls -lh", function()
      local lines = {
        "-rw-r--r--   1 linrongbin Administrators 1.1K Jul  9 14:35 LICENSE",
        "-rw-r--r--   1 linrongbin Administrators 6.2K Sep 28 22:26 README.md",
        "drwxr-xr-x   2 linrongbin Administrators 4.0K Sep 30 21:55 deps",
        "-rw-r--r--   1 linrongbin Administrators  585 Jul 22 14:26 init.vim",
        "-rw-r--r--   1 linrongbin Administrators  585 Jul 22 14:26 'hello world.txt'",
        "-rw-r--r--   1 rlin  staff   1.0K Aug 28 12:39 LICENSE",
        "-rw-r--r--   1 rlin  staff    27K Oct  8 11:37 README.md",
        "drwxr-xr-x   3 rlin  staff    96B Aug 28 12:39 autoload",
        "drwxr-xr-x   4 rlin  staff   128B Sep 22 10:11 bin",
        "-rw-r--r--   1 rlin  staff   120B Sep  5 14:14 codecov.yml",
      }
      local expects = {
        "LICENSE",
        "README.md",
        "deps",
        "init.vim",
        "hello world.txt",
        "LICENSE",
        "README.md",
        "autoload",
        "bin",
        "codecov.yml",
      }
      for i, line in ipairs(lines) do
        local actual1 = previewer_labels.ls_previewer_label(line)
        local expect = expects[i]
        assert_eq(actual1, expect)

        local f =
          previewer_labels._make_ls_previewer_label(line_helpers.parse_ls)
        local actual2 = f(line)
        assert_eq(actual1, actual2)
      end
    end)
    it("lsd -lh --header --icon=never", function()
      local lines = {
        "drwxr-xr-x  rlin staff 160 B  Wed Oct 25 16:59:44 2023 bin",
        ".rw-r--r--  rlin staff  54 KB Tue Oct 31 22:29:35 2023 CHANGELOG.md",
        ".rw-r--r--  rlin staff 120 B  Tue Oct 10 14:47:43 2023 codecov.yml",
        ".rw-r--r--  rlin staff 1.0 KB Mon Aug 28 12:39:24 2023 LICENSE",
        "drwxr-xr-x  rlin staff 128 B  Tue Oct 31 21:55:28 2023 lua",
        ".rw-r--r--  rlin staff  38 KB Wed Nov  1 10:29:19 2023 README.md",
        "drwxr-xr-x  rlin staff 992 B  Wed Nov  1 11:16:13 2023 test",
      }
      local expects = {
        "bin",
        "CHANGELOG.md",
        "codecov.yml",
        "LICENSE",
        "lua",
        "README.md",
        "test",
      }
      for i, line in ipairs(lines) do
        local actual1 = line_helpers.parse_lsd(line)
        local expect = expects[i]
        assert_eq(actual1, expect)

        local f =
          previewer_labels._make_ls_previewer_label(line_helpers.parse_lsd)
        local actual2 = f(line)
        assert_eq(actual1, actual2)
      end
    end)
    it("eza -lh for macOS/linux", function()
      local lines = {
        -- Permissions Size User Date Modified Name
        "drwxr-xr-x     - linrongbin 28 Aug 12:39  autoload",
        "drwxr-xr-x     - linrongbin 22 Sep 10:11  bin",
        ".rw-r--r--   120 linrongbin  5 Sep 14:14  codecov.yml",
        ".rw-r--r--  1.1k linrongbin 28 Aug 12:39  LICENSE",
        "drwxr-xr-x     - linrongbin  8 Oct 09:14  lua",
        ".rw-r--r--   28k linrongbin  8 Oct 11:37  README.md",
        "drwxr-xr-x     - linrongbin  8 Oct 11:44  test",
        ".rw-r--r--   28k linrongbin  8 Oct 12:10  test1-README.md",
        ".rw-r--r--   28k linrongbin  8 Oct 12:10  test2-README.md",
      }
      local expects = {
        "autoload",
        "bin",
        "codecov.yml",
        "LICENSE",
        "lua",
        "README.md",
        "test",
        "test1-README.md",
        "test2-README.md",
      }
      local parse_eza_on_macos_linux = line_helpers._make_parse_ls(6)
      for i, line in ipairs(lines) do
        local actual1 = parse_eza_on_macos_linux(line)
        local expect = expects[i]
        assert_eq(actual1, expect)

        local f =
          previewer_labels._make_ls_previewer_label(line_helpers.parse_eza)
        local actual2 = f(line)
        assert_eq(actual1, actual2)
      end
    end)
  end)
end)
