---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("helper.parsers", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local strs = require("fzfx.lib.strings")
  local paths = require("fzfx.lib.paths")
  local fs = require("fzfx.lib.filesystems")
  local parsers_helper = require("fzfx.helper.parsers")

  local DEVICONS_PATH =
    "~/github/linrongbin16/.config/nvim/lazy/nvim-web-devicons"

  describe("[parse_find]", function()
    it("test without icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md",
        "~/github/linrongbin16/fzfx.nvim/LICENSE",
        "~/github/linrongbin16/fzfx.nvim/codecov.yml",
        "~/github/linrongbin16/fzfx.nvim/test/hello world.txt",
        "~/github/linrongbin16/fzfx.nvim/test/goodbye world/goodbye.lua",
      }
      for i, line in ipairs(lines) do
        local expect = paths.normalize(line, { expand = true })
        local actual = parsers_helper.parse_find(expect)
        assert_eq(type(actual), "table")
        assert_eq(expect, actual.filename)
      end
    end)
    it("test with icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
      local lines = {
        " ~/github/linrongbin16/fzfx.nvim/README.md",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua/test/hello world.txt",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/world.txt",
      }
      for i, line in ipairs(lines) do
        local first_space_pos = strs.find(line, " ")
        local expect = paths.normalize(
          vim.trim(line:sub(first_space_pos + 1)),
          { expand = true }
        )
        local actual = parsers_helper.parse_find(line)
        assert_eq(type(actual), "table")
        assert_eq(expect, actual.filename)
      end
    end)
  end)

  describe("[parse_grep]", function()
    it("test without icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md:1",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1:2",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1: ok ok",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:2:3:hello",
      }
      for _, line in ipairs(lines) do
        local actual = parsers_helper.parse_grep(line)
        -- print(
        --   string.format(
        --     "parse grep without icon, line:%s, parsed:%s\n",
        --     vim.inspect(line),
        --     vim.inspect(actual)
        --   )
        -- )
        assert_eq(type(actual), "table")
        assert_eq(type(actual.filename), "string")
        assert_eq(type(actual.lineno), "number")

        local line_splits = strs.split(line, ":")
        assert_eq(actual.lineno, tonumber(line_splits[2]))
        assert_eq(
          actual.filename,
          paths.normalize(line_splits[1], { expand = true })
        )
      end
    end)
    it("test with icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
      local lines = {
        " ~/github/linrongbin16/fzfx.nvim/README.md:12",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:15",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:15:",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:70",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:4:71: ok ko",
      }
      for _, line in ipairs(lines) do
        local actual = parsers_helper.parse_grep(line)
        assert_eq(type(actual), "table")
        assert_eq(type(actual.filename), "string")
        assert_eq(type(actual.lineno), "number")
        local line_splits = strs.split(line, ":")
        assert_eq(actual.lineno, tonumber(line_splits[2]))
        assert_eq(
          actual.filename,
          parsers_helper.parse_find(line_splits[1]).filename
        )
      end
    end)
  end)

  describe("[parse_rg]", function()
    it("test without icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md:12:30",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:13:1:",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:13:2: hello world",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:3",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:3: ok ok",
      }
      for _, line in ipairs(lines) do
        local actual = parsers_helper.parse_rg(line)
        assert_eq(type(actual), "table")
        assert_eq(type(actual.filename), "string")
        assert_eq(type(actual.lineno), "number")
        assert_eq(type(actual.column), "number")
        local line_splits = strs.split(line, ":")
        assert_eq(
          actual.filename,
          parsers_helper.parse_find(line_splits[1]).filename
        )
        assert_eq(actual.lineno, tonumber(line_splits[2]))
        assert_eq(actual.column, tonumber(line_splits[3]))
      end
    end)
    it("test with icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
      local lines = {
        " ~/github/linrongbin16/fzfx.nvim/README.md:12:30",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:15:98",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:15:82:",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:70",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:4:71: ok ko",
      }
      for _, line in ipairs(lines) do
        local actual = parsers_helper.parse_rg(line)
        assert_eq(type(actual), "table")
        assert_eq(type(actual.filename), "string")
        assert_eq(type(actual.lineno), "number")
        assert_eq(type(actual.column), "number")
        local line_splits = strs.split(line, ":")
        assert_eq(
          actual.filename,
          parsers_helper.parse_find(line_splits[1]).filename
        )
        assert_eq(actual.lineno, tonumber(line_splits[2]))
        assert_eq(actual.column, tonumber(line_splits[3]))
      end
    end)
  end)

  describe("[parse_ls/parse_lsd/parse_eza]", function()
    local cwdtmp = vim.fn.tempname()
    fs.writefile(cwdtmp, cwd)
    local CONTEXT = { cwd = cwdtmp }
    it("test ls", function()
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
        local expect = expects[i]
        local actual = parsers_helper.parse_ls(line, CONTEXT)
        print(
          string.format(
            "parse ls, line:%s, actual:%s\n",
            vim.inspect(line),
            vim.inspect(actual)
          )
        )
        assert_eq(type(actual), "table")
        assert_eq(actual.filename, paths.join(CONTEXT.cwd, expect))
      end
    end)
    it("test lsd", function()
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
        local actual = parsers_helper.parse_lsd(line, CONTEXT)
        local expect = expects[i]
        assert_eq(type(actual), "table")
        assert_eq(actual.filename, paths.join(CONTEXT.cwd, expect))
      end
    end)
    it("test eza for windows", function()
      local lines = {
        -- Mode  Size Date Modified Name
        "d----    - 30 Sep 21:55  deps",
        "-a---  585 22 Jul 14:26  init.vim",
        "-a--- 6.4k 30 Sep 21:55  install.ps1",
        "-a--- 5.3k 23 Sep 13:43  install.sh",
      }
      local expects = {
        "deps",
        "init.vim",
        "install.ps1",
        "install.sh",
      }
      local parse_eza_on_windows = parsers_helper._make_parse_ls(5)
      for i, line in ipairs(lines) do
        local actual = parse_eza_on_windows(line, CONTEXT)
        local expect = expects[i]
        assert_eq(actual, expect)
      end
    end)
    it("test eza for macOS/linux", function()
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
      local parse_eza_on_macos_linux = parsers_helper._make_parse_ls(6)
      for i, line in ipairs(lines) do
        local actual = parse_eza_on_macos_linux(line, CONTEXT)
        local expect = expects[i]
        assert_eq(actual, expect)
      end
    end)
  end)

  describe("[parse_vim_commands]", function()
    local VIM_COMMANDS_HEADER =
      "Name              Bang|Bar|Nargs|Range|Complete         Desc/Location"
    local CONTEXT = {
      name_width = 17,
      opts_width = 37,
    }

    it("parse ex commands with locations", function()
      local lines = {
        ":                 N   |Y  |N/A  |N/A  |N/A              /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/doc/index.txt:1121",
        ":!                N   |Y  |N/A  |N/A  |N/A              /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/doc/index.txt:1122",
        ":Next             N   |Y  |N/A  |N/A  |N/A              /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/doc/index.txt:1124",
      }
      for _, line in ipairs(lines) do
        local last_space = strs.rfind(line, " ")
        local expect_splits = strs.split(line:sub(last_space + 1), ":")
        local actual = parsers_helper.parse_vim_command(line, CONTEXT)
        assert_eq(type(actual), "table")
        assert_eq(
          actual.filename,
          paths.normalize(expect_splits[1], { expand = true })
        )
        assert_eq(actual.lineno, tonumber(expect_splits[2]))
      end
    end)
    it("parse ex commands with description", function()
      local lines = {
        ':bdelete          N   |Y  |N/A  |N/A  |N/A              "delete buffer"',
      }
      for _, line in ipairs(lines) do
        local double_quote_before_last = strs.rfind(line, '"', #line - 1)
        local expect =
          vim.trim(line:sub(double_quote_before_last + 1, #line - 1))
        local actual = parsers_helper.parse_vim_command(line, CONTEXT)
        assert_eq(type(actual), "string")
        assert_eq(actual, expect)
      end
    end)
    it("parse user commands with location", function()
      local lines = {
        "FzfxCommands      Y   |Y  |N/A  |N/A  |N/A              ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:120",
        "FzfxFiles         Y   |Y  |N/A  |N/A  |N/A              ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:120",
        "Barbecue          Y   |Y  |N/A  |N/A  |N/A              ~/.config/nvim/lazy/barbecue/lua/barbecue.lua:73",
      }
      for _, line in ipairs(lines) do
        local last_space = strs.rfind(line, " ")
        local expect_splits = strs.split(line:sub(last_space + 1), ":")
        local actual = parsers_helper.parse_vim_command(line, CONTEXT)
        assert_eq(type(actual), "table")
        assert_eq(
          actual.filename,
          paths.normalize(expect_splits[1], { expand = true })
        )
        assert_eq(actual.lineno, tonumber(expect_splits[2]))
      end
    end)
    it("parse user commands with description", function()
      local lines = {
        'Bdelete           N   |Y  |N/A  |N/A  |N/A              "delete buffer"',
      }
      for _, line in ipairs(lines) do
        local double_quote_before_last = strs.rfind(line, '"', #line - 1)
        local expect =
          vim.trim(line:sub(double_quote_before_last + 1, #line - 1))
        local actual = parsers_helper.parse_vim_command(line, CONTEXT)
        assert_eq(type(actual), "string")
        assert_eq(actual, expect)
      end
    end)
  end)
  describe("[parse_vim_keymap]", function()
    local VIM_COMMANDS_HEADER =
      "Lhs                                          Mode|Noremap|Nowait|Silent Rhs/Location"
    local CONTEXT = {
      key_width = 44,
      opts_width = 26,
    }
    it("parse ex map with locations", function()
      local lines = {
        "<C-F>                                            |N      |N     |N      ~/.config/nvim/lazy/nvim-cmp/lua/cmp/utils/keymap.lua:127",
        "<CR>                                             |N      |N     |N      ~/.config/nvim/lazy/nvim-cmp/lua/cmp/utils/keymap.lua:127",
        "<Plug>(YankyGPutAfterShiftRight)             n   |Y      |N     |Y      ~/.config/nvim/lazy/yanky.nvim/lua/yanky.lua:369",
      }
      for _, line in ipairs(lines) do
        local last_space = strs.rfind(line, " ")
        local expect_splits = strs.split(line:sub(last_space + 1), ":")
        local actual = parsers_helper.parse_vim_keymap(line, CONTEXT)
        assert_eq(type(actual), "table")
        assert_eq(
          actual.filename,
          paths.normalize(expect_splits[1], { expand = true })
        )
        assert_eq(actual.lineno, tonumber(expect_splits[2]))
      end
    end)
    it("parse ex commands with definition", function()
      local lines = {
        '%                                            n   |N      |N     |Y      "<Plug>(matchup-%)"',
        '&                                            n   |Y      |N     |N      ":&&<CR>"',
        '<2-LeftMouse>                                n   |N      |N     |Y      "<Plug>(matchup-double-click)"',
      }
      for _, line in ipairs(lines) do
        local double_quote_before_last = strs.rfind(line, '"', #line - 1)
        local expect =
          vim.trim(line:sub(double_quote_before_last + 1, #line - 1))
        local actual = parsers_helper.parse_vim_keymap(line, CONTEXT)
        assert_eq(type(actual), "string")
        assert_eq(actual, expect)
      end
    end)
  end)
  describe("[parse_git_status]", function()
    it("parse", function()
      local lines = {
        " M fzfx/config.lua",
        " D fzfx/constants.lua",
        " M fzfx/line_helpers.lua",
        " M ../test/line_helpers_spec.lua",
        "?? ../hello",
      }
      for _, line in ipairs(lines) do
        local actual = parsers_helper.parse_git_status(line)
        assert_eq(line:sub(4), actual)
      end
    end)
  end)
end)
