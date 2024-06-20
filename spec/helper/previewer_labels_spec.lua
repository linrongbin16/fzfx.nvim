---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("helper.previewer_labels", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local function make_context()
    return {
      bufnr = vim.api.nvim_get_current_buf(),
      winnr = vim.api.nvim_get_current_win(),
      tabnr = vim.api.nvim_get_current_tabpage(),
    }
  end

  local str = require("fzfx.commons.str")
  local fileio = require("fzfx.commons.fileio")

  local parsers = require("fzfx.helper.parsers")
  local labels = require("fzfx.helper.previewer_labels")

  require("fzfx").setup({
    debug = {
      enable = true,
      file_log = true,
    },
  })

  describe("[label_find]", function()
    it("test", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
      }
      for _, line in ipairs(lines) do
        local actual = labels.label_find(line)
        assert_eq(type(actual), "string")
        assert_true(str.endswith(line, actual))
      end
    end)
  end)

  describe("[label_rg]", function()
    it("test", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md:1:1:ok",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1:2:hello",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:3:hello world",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:12:81: goodbye",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:81:71:9129",
      }
      for _, line in ipairs(lines) do
        local actual = labels.label_rg(line)
        assert_eq(type(actual), "string")
        assert_eq(type(str.find(line, actual)), "number")
        assert_true(str.find(line, actual) > 0)
      end
    end)
  end)

  describe("[label_rg_no_filename]", function()
    it("test", function()
      local lines = {
        "1:1:ok",
        "1:2:hello",
        "1:3:hello world",
        "12:81: goodbye",
        "81:71:9129",
      }
      for _, line in ipairs(lines) do
        local ctx = make_context()
        local actual = labels.label_rg_no_filename(line, ctx)
        local splits = str.split(line, ":")
        assert_eq(type(actual), "string")
        assert_true(str.endswith(actual, string.format("%s:%s", splits[1], splits[2])))
        assert_true(
          str.find(actual, vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ctx.bufnr), ":t")) > 0
        )
      end
    end)
  end)

  describe("[label_grep]", function()
    it("test", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md:73",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:hello world",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:12:81: goodbye",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:81:72:9129",
      }
      for _, line in ipairs(lines) do
        local actual = labels.label_grep(line)
        assert_eq(type(actual), "string")
        assert_eq(type(str.find(line, actual)), "number")
        assert_true(str.find(line, actual) > 0)
      end
    end)
  end)

  describe("[label_grep_no_filename]", function()
    it("test", function()
      local lines = {
        "73",
        "1",
        "1:hello world",
        "12:81: goodbye",
        "81:72:9129",
      }
      for _, line in ipairs(lines) do
        local ctx = make_context()
        local actual = labels.label_grep_no_filename(line, ctx)
        local splits = str.split(line, ":")
        assert_eq(type(actual), "string")
        assert_true(str.endswith(actual, splits[1]))
        assert_true(
          str.find(actual, vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ctx.bufnr), ":t")) > 0
        )
      end
    end)
  end)

  describe("[label_vim_command]", function()
    --- @type fzfx.VimCommandsPipelineContext
    local CONTEXT = {
      name_column_width = 17,
      opts_column_width = 37,
    }
    it("test location", function()
      local lines = {
        ":                 N   |Y  |N/A  |N/A  |N/A              /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/doc/index.txt:1121",
        ":!                N   |Y  |N/A  |N/A  |N/A              /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/doc/index.txt:1122",
        ":Next             N   |Y  |N/A  |N/A  |N/A              /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/doc/index.txt:1124",
      }
      for _, line in ipairs(lines) do
        local actual = labels.label_vim_command(line, CONTEXT)
        assert_eq(type(actual), "string")
        local actual_splits = str.split(actual, ":")
        assert_eq(#actual_splits, 2)
        assert_true(str.find(line, actual_splits[1]) > 0)
        assert_true(str.endswith(line, actual_splits[2]))
      end
    end)
    it("test definition", function()
      local lines = {
        ':bdelete          N   |Y  |N/A  |N/A  |N/A              "delete buffer"',
      }
      for _, line in ipairs(lines) do
        local actual = labels.label_vim_command(line, CONTEXT)
        assert_eq(type(actual), "string")
        assert_eq(actual, "Definition")
      end
    end)
  end)

  describe("[label_vim_keymap]", function()
    --- @type fzfx.VimKeyMapsPipelineContext
    local CONTEXT = {
      key_column_width = 44,
      opts_column_width = 26,
    }
    it("test location", function()
      local lines = {
        "<C-F>                                            |N      |N     |N      ~/.config/nvim/lazy/nvim-cmp/lua/cmp/utils/keymap.lua:127",
        "<CR>                                             |N      |N     |N      ~/.config/nvim/lazy/nvim-cmp/lua/cmp/utils/keymap.lua:127",
        "<Plug>(YankyGPutAfterShiftRight)             n   |Y      |N     |Y      ~/.config/nvim/lazy/yanky.nvim/lua/yanky.lua:369",
      }
      for _, line in ipairs(lines) do
        local actual = labels.label_vim_keymap(line, CONTEXT)
        assert_eq(type(actual), "string")
        local actual_splits = str.split(actual, ":")
        assert_eq(#actual_splits, 2)
        assert_true(str.find(line, actual_splits[1]) > 0)
        assert_true(str.endswith(line, actual_splits[2]))
      end
    end)
    it("test definition", function()
      local lines = {
        '%                                            n   |N      |N     |Y      "<Plug>(matchup-%)"',
        '&                                            n   |Y      |N     |N      ":&&<CR>"',
        '<2-LeftMouse>                                n   |N      |N     |Y      "<Plug>(matchup-double-click)"',
      }
      for _, line in ipairs(lines) do
        local actual = labels.label_vim_keymap(line, CONTEXT)
        assert_eq(type(actual), "string")
        assert_eq(actual, "Definition")
      end
    end)
  end)

  describe("[label_ls/lsd/eza]", function()
    local TEMP = vim.fn.tempname()
    fileio.writefile(TEMP --[[@as string]], vim.fn.getcwd() --[[@as string]])
    local CONTEXT = {
      bufnr = vim.api.nvim_get_current_buf(),
      winnr = vim.api.nvim_get_current_win(),
      tabnr = vim.api.nvim_get_current_tabpage(),
      cwd = TEMP,
    }
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
        local actual = labels.label_ls(line, CONTEXT)
        local expect = expects[i]
        assert_true(str.endswith(actual, expect))
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
        local actual = labels.label_lsd(line, CONTEXT)
        local expect = expects[i]
        assert_true(str.endswith(actual, expect))
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
      for i, line in ipairs(lines) do
        local actual = labels.label_eza(line, CONTEXT)
        local expect = expects[i]
        assert_true(str.endswith(actual, expect))
      end
    end)
  end)

  describe("[label_vim_mark]", function()
    local CONTEXT = require("fzfx.cfg.vim_marks")._context_maker()
    it("test", function()
      local n = #CONTEXT.marks
      for i = 2, n do
        local line = CONTEXT.marks[i]
        local actual = labels.label_vim_mark(line, CONTEXT)
        local splits = str.split(actual, ":")
        print(
          string.format(
            "label_vim_mark [%s], line:%s, actual:%s, splits:%s\n",
            vim.inspect(i),
            vim.inspect(line),
            vim.inspect(actual),
            vim.inspect(splits)
          )
        )
        assert_eq(type(actual), "string")
        assert_true(#splits == 3 or #splits == 2)
        local pos1 = str.find(line, splits[1])
        print(string.format("label_vim_mark pos1:%s\n", vim.inspect(pos1)))
        if pos1 then
          assert_true(pos1 > 0)
          local pos2 = str.find(line, splits[2], pos1 + string.len(splits[1]))
          assert_true(pos2 > pos1)
          print(string.format("label_vim_mark pos2:%s\n", vim.inspect(pos2)))
          if #splits == 3 then
            local pos3 = str.find(line, splits[3], pos2 + string.len(splits[2]))
            print(string.format("label_vim_mark pos3:%s\n", vim.inspect(pos3)))
            assert_true(pos3 > pos2)
          end
        else
          local pos2 = str.find(line, splits[2])
          assert_true(pos2 > 1)
          print(string.format("label_vim_mark pos2:%s\n", vim.inspect(pos2)))
          if #splits == 3 then
            local pos3 = str.find(line, splits[3], pos2 + string.len(splits[2]))
            print(string.format("label_vim_mark pos3:%s\n", vim.inspect(pos3)))
            assert_true(pos3 > pos2)
          end
        end
      end
    end)
  end)
end)
