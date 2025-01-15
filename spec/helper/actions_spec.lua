local cwd = vim.fn.getcwd()

describe("helper.actions", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
    vim.cmd("edit README.md")
  end)

  local DEVICONS_PATH = "~/github/linrongbin16/.config/nvim/lazy/nvim-web-devicons"

  local consts = require("fzfx.lib.constants")
  local str = require("fzfx.commons.str")
  local tbl = require("fzfx.commons.tbl")
  local path = require("fzfx.commons.path")
  local actions = require("fzfx.helper.actions")
  local parsers = require("fzfx.helper.parsers")

  --- @return fzfx.PipelineContext
  local function make_context()
    return {
      bufnr = vim.api.nvim_get_current_buf(),
      winnr = vim.api.nvim_get_current_win(),
      tabnr = vim.api.nvim_get_current_tabpage(),
    }
  end

  require("fzfx").setup({
    debug = {
      enable = true,
      file_log = true,
    },
  })

  describe("[nop]", function()
    it("test", function()
      local nop = actions.nop
      assert_eq(type(nop), "function")
      assert_true(nop({}) == nil)
    end)
  end)

  describe("[edit_find]", function()
    it("make without icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
      }
      local actual = actions._make_edit_find(lines)
      assert_eq(type(actual), "table")
      assert_eq(#actual, #lines)
      for i, line in ipairs(lines) do
        local expect = string.format(
          "edit! %s",
          path.normalize(line, { double_backslash = true, expand = true })
        )
        assert_eq(actual[i], expect)
      end
    end)
    it("make with icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
      local lines = {
        " ~/github/linrongbin16/fzfx.nvim/README.md",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
      }
      local actual = actions._make_edit_find(lines)
      assert_eq(type(actual), "table")
      assert_eq(#actual, #lines)
      for i, line in ipairs(lines) do
        local first_space_pos = str.find(line, " ")
        local expect = string.format(
          "edit! %s",
          path.normalize(line:sub(first_space_pos + 1), { double_backslash = true, expand = true })
        )
        assert_eq(actual[i], expect)
      end
    end)
    it("run without icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "README.md:17",
        "lua/fzfx.lua:30:17",
        "lua/fzfx/config.lua:37:hello world",
        "lua/fzfx/test/goodbye world/goodbye.lua",
        "lua/fzfx/test/goodbye world/world.txt",
        "lua/fzfx/test/hello world.txt",
      }
      actions.edit_find(lines, make_context())
      assert_true(true)
    end)
    it("run with icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
      local lines = {
        " README.md",
        "󰢱 lua/fzfx.lua",
        "󰢱 lua/fzfx/config.lua",
        "󰢱 lua/fzfx/test/goodbye world/goodbye.lua",
        "󰢱 lua/fzfx/test/goodbye world/world.txt",
        "󰢱 lua/fzfx/test/hello world.txt",
      }
      actions.edit_find(lines, make_context())
      assert_true(true)
    end)
  end)
  describe("[setqflist_find]", function()
    it("make without icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
      }
      local actual = actions._make_setqflist_find(lines)
      assert_eq(type(actual), "table")
      assert_eq(#actual, #lines)
      for i, act in ipairs(actual) do
        local line = lines[i]
        local expect = parsers.parse_find(line)
        assert_eq(type(act), "table")
        assert_eq(act.filename, expect.filename)
        assert_eq(act.lnum, 1)
        assert_eq(act.col, 1)
      end
    end)
    it("make with icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
      local lines = {
        " ~/github/linrongbin16/fzfx.nvim/README.md",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
      }
      local actual = actions._make_setqflist_find(lines)
      assert_eq(type(actual), "table")
      assert_eq(#actual, #lines)
      for i, act in ipairs(actual) do
        local line = lines[i]
        local expect = parsers.parse_find(line)
        assert_eq(type(act), "table")
        assert_eq(act.filename, expect.filename)
        assert_eq(act.lnum, 1)
        assert_eq(act.col, 1)
      end
    end)
    it("run without icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
      }
      actions.setqflist_find(lines)
      assert_true(true)
    end)
    it("run with icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
      local lines = {
        " ~/github/linrongbin16/fzfx.nvim/README.md",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
      }
      actions.setqflist_find(lines)
      assert_true(true)
    end)
  end)

  describe("[edit_grep]", function()
    it("make without icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md:73",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:hello world",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:12:81: goodbye",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:81:72:9129",
      }
      local actual = actions._make_edit_grep(lines)
      assert_eq(type(actual), "table")
      assert_eq(#actual.edits, #lines)
      assert_eq(#actual.moves, 2)
      for i, act in ipairs(actual.edits) do
        local expect = string.format(
          "edit! %s",
          path.normalize(str.split(lines[i], ":")[1], { double_backslash = true, expand = true })
        )
        assert_eq(act, expect)
      end
      assert_eq(actual.moves[1], "call cursor(81, 1)")
      assert_eq(actual.moves[2], 'execute "normal! zz"')
    end)
    it("make with icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
      local lines = {
        " ~/github/linrongbin16/fzfx.nvim/README.md:73",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:83: hello world",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:12:83 goodbye",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:83:82:71:world",
      }
      local actual = actions._make_edit_grep(lines)
      assert_eq(type(actual), "table")
      assert_eq(#actual.edits, #lines)
      assert_eq(#actual.moves, 2)
      for i = 1, 5 do
        local line = lines[i]
        local first_space_pos = str.find(line, " ")
        local expect = string.format(
          "edit! %s",
          path.normalize(
            line:sub(first_space_pos + 1, str.find(line, ":", first_space_pos + 1) - 1),
            { double_backslash = true, expand = true }
          )
        )
        assert_eq(actual.edits[i], expect)
      end
      assert_true(str.find(actual.moves[1], "cursor") > 0)
      assert_eq(actual.moves[2], 'execute "normal! zz"')
    end)
    it("run without icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md:38: this is fzfx",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:hello world",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:12:81: goodbye",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:81:72:9129",
      }
      actions.edit_grep(lines, make_context())
      assert_true(true)
    end)
    it("run with icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
      local lines = {
        " ~/github/linrongbin16/fzfx.nvim/README.md:73",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:83: hello world",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:12:83 goodbye",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:83:82:71:world",
      }
      actions.edit_grep(lines, make_context())
      assert_true(true)
    end)
  end)

  describe("[_make_set_cursor_grep_no_filename]", function()
    it("empty", function()
      local actual = actions._make_set_cursor_grep_no_filename({})
      assert_eq(actual, nil)
    end)
    it("make", function()
      local lines = {
        "73",
        "1",
        "1:hello world",
        "12:81: goodbye",
        "81:72:9129",
      }

      for i, line in ipairs(lines) do
        local actual = actions._make_set_cursor_grep_no_filename({ line })
        assert_eq(type(actual), "table")
        assert_eq(#actual, 2)
        assert_true(str.startswith(actual[1], "call cursor"))
        assert_eq(actual[2], 'execute "normal! zz"')
      end
    end)
  end)

  describe("[cursor_move_grep_bufnr]", function()
    it("run", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "38: this is fzfx",
        "1",
        "1:hello world",
        "12:81: goodbye",
        "81:72:9129",
      }
      actions.cursor_move_grep_bufnr(lines, make_context())
      assert_true(true)
    end)
  end)

  describe("[setqflist_grep]", function()
    it("make without icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md:1:hello world",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:10: ok ok",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:81: local query = 'hello'",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:4: print('goodbye world')",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:3: hello world",
      }
      local actual = actions._make_setqflist_grep(lines)
      assert_eq(type(actual), "table")
      assert_eq(#actual, #lines)
      for i, act in ipairs(actual) do
        local line = lines[i]
        local expect = parsers.parse_grep(line)
        assert_eq(type(act), "table")
        assert_eq(act.filename, expect.filename)
        assert_eq(act.lnum, expect.lineno)
        assert_eq(act.col, 1)
        assert_eq(act.text, line:sub(str.rfind(line, ":") + 1))
      end
    end)
    it("make with icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
      local lines = {
        " ~/github/linrongbin16/fzfx.nvim/README.md:1:hello world",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:10: ok ok",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:81: local query = 'hello'",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:4: print('goodbye world')",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:3: hello world",
      }
      local actual = actions._make_setqflist_grep(lines)
      assert_eq(type(actual), "table")
      assert_eq(#actual, #lines)
      for i, act in ipairs(actual) do
        local line = lines[i]
        local expect = parsers.parse_grep(line)
        assert_eq(type(act), "table")
        assert_eq(act.filename, expect.filename)
        assert_eq(act.lnum, expect.lineno)
        assert_eq(act.col, 1)
        assert_eq(act.text, line:sub(str.rfind(line, ":") + 1))
      end
    end)
    it("run without icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md:1:hello world",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:10: ok ok",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:81: local query = 'hello'",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:4: print('goodbye world')",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:3: hello world",
      }
      actions.setqflist_grep(lines)
      assert_true(true)
    end)
    it("run with icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
      local lines = {
        " ~/github/linrongbin16/fzfx.nvim/README.md:1:hello world",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:10: ok ok",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:81: local query = 'hello'",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:4: print('goodbye world')",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:3: hello world",
      }
      actions.setqflist_grep(lines)
      assert_true(true)
    end)
  end)

  describe("[setqflist_grep_bufnr]", function()
    it("make", function()
      local lines = {
        "1:hello world",
        "10: ok ok",
        "81: local query = 'hello'",
        "4: print('goodbye world')",
        "3: hello world",
      }
      local actual1 = actions._make_setqflist_grep_no_filename({}, make_context())
      assert_eq(#actual1, 0)
      local actual2 = actions._make_setqflist_grep_no_filename(lines, nil)
      assert_eq(actual2, nil)

      for i, line in ipairs(lines) do
        local ctx = make_context()
        local actual = actions._make_setqflist_grep_no_filename({ line }, ctx)
        assert_eq(type(actual), "table")
        assert_eq(#actual, 1)

        local filename = vim.api.nvim_buf_get_name(ctx.bufnr)
        filename = path.normalize(filename, { double_backslash = true, expand = true })

        local splits = str.split(line, ":")
        for _, act in ipairs(actual) do
          print(
            string.format(
              "setqflist_grep_no_filename-1 act:%s, splits:%s\n",
              vim.inspect(act),
              vim.inspect(splits)
            )
          )
          assert_eq(act.filename, filename)
          assert_eq(act.lnum, tonumber(splits[1]))
          assert_eq(act.col, 1)
          assert_eq(act.text, line:sub(str.find(line, ":") + 1))
        end
      end
    end)
    it("run", function()
      local lines = {
        "1:hello world",
        "10: ok ok",
        "81: local query = 'hello'",
        "4: print('goodbye world')",
        "3: hello world",
      }
      for i, line in ipairs(lines) do
        local ctx = make_context()
        actions.setqflist_grep_bufnr(lines, ctx)
        assert_true(true)
      end
    end)
  end)

  describe("[edit_rg]", function()
    it("make without icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md:1:1:ok",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1:2:hello",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:3:hello world",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:12:81: goodbye",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:81:71:9129",
      }
      local actual = actions._make_edit_rg(lines)
      assert_eq(type(actual), "table")
      assert_eq(#actual.edits, #lines)
      assert_eq(#actual.moves, 2)
      for i, act in ipairs(actual.edits) do
        local expect = string.format(
          "edit! %s",
          path.normalize(str.split(lines[i], ":")[1], { double_backslash = true, expand = true })
        )
        assert_eq(act, expect)
      end
      assert_eq(actual.moves[1], "call cursor(81, 71)")
      assert_eq(actual.moves[2], 'execute "normal! zz"')
    end)
    it("make rg with icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
      local lines = {
        " ~/github/linrongbin16/fzfx.nvim/README.md:7:18",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:38:72:fzfx",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:108:2:fzfx",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:12:81:goodbye",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:81:72:91:94",
      }
      local actual = actions._make_edit_rg(lines)
      assert_eq(type(actual), "table")
      assert_eq(#actual.edits, #lines)
      assert_eq(#actual.moves, 2)
      for i, act in ipairs(actual.edits) do
        local line = lines[i]
        local first_space_pos = str.find(line, " ")
        local expect = string.format(
          "edit! %s",
          path.normalize(
            line:sub(first_space_pos + 1, str.find(line, ":", first_space_pos + 1) - 1),
            { double_backslash = true, expand = true }
          )
        )
        assert_eq(act, expect)
      end
      assert_eq(actual.moves[1], "call cursor(81, 72)")
      assert_eq(actual.moves[2], 'execute "normal! zz"')
    end)
    it("run without icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md:1:1:ok",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:1:2:hello",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:1:3:hello world",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:12:81: goodbye",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:81:71:9129",
      }
      actions.edit_rg(lines, make_context())
      assert_true(true)
    end)
    it("run with icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
      local lines = {
        " ~/github/linrongbin16/fzfx.nvim/README.md:7:18",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:38:72:fzfx",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:108:2:fzfx",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:12:81:goodbye",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:81:72:91:94",
      }
      actions.edit_rg(lines, make_context())
      assert_true(true)
    end)
  end)
  describe("[_make_set_cursor_rg_no_filename]", function()
    it("empty", function()
      local actual = actions._make_cursor_move_rg_bufnr({})
      assert_eq(actual, nil)
    end)
    it("make", function()
      local lines = {
        "1:1:ok",
        "1:2:hello",
        "1:3:hello world",
        "12:81: goodbye",
        "81:71:9129",
      }
      for i, line in ipairs(lines) do
        local actual = actions._make_cursor_move_rg_bufnr({ line })
        print(
          string.format(
            "_make_set_cursor_rg_no_filename-%d, line:%s, actual:%s\n",
            i,
            vim.inspect(line),
            vim.inspect(actual)
          )
        )
        assert_eq(type(actual), "table")
        assert_eq(#actual, 2)

        assert_true(str.startswith(actual[1], "call cursor("))
        assert_eq(actual[2], 'execute "normal! zz"')
      end
    end)
  end)
  describe("[cursor_move_rg_bufnr]", function()
    it("run", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "1:1:ok",
        "1:2:hello",
        "1:3:hello world",
        "12:81: goodbye",
        "81:71:9129",
      }
      actions.cursor_move_rg_bufnr(lines, make_context())
      assert_true(true)
    end)
  end)

  describe("[setqflist_rg]", function()
    it("make without icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md:1:3:hello world",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:10:83: ok ok",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:81:3: local query = 'hello'",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:4:1: print('goodbye world')",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:3:10: hello world",
      }
      local actual = actions._make_setqflist_rg(lines)
      assert_eq(type(actual), "table")
      assert_eq(#actual, #lines)
      for i, act in ipairs(actual) do
        local line = lines[i]
        local expect = parsers.parse_rg(line)
        assert_eq(type(act), "table")
        assert_eq(act.filename, expect.filename)
        assert_eq(act.lnum, expect.lineno)
        assert_eq(act.col, expect.column)
        assert_eq(act.text, line:sub(str.rfind(line, ":") + 1))
      end
    end)
    it("make with icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
      local lines = {
        " ~/github/linrongbin16/fzfx.nvim/README.md:1:3:hello world",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:10:83: ok ok",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:81:3: local query = 'hello'",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:4:1: print('goodbye world')",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:3:10: hello world",
      }
      local actual = actions._make_setqflist_rg(lines)
      assert_eq(type(actual), "table")
      assert_eq(#actual, #lines)
      for i, act in ipairs(actual) do
        local line = lines[i]
        local expect = parsers.parse_rg(line)
        assert_eq(type(act), "table")
        assert_eq(act.filename, expect.filename)
        assert_eq(act.lnum, expect.lineno)
        assert_eq(act.col, expect.column)
        assert_eq(act.text, line:sub(str.rfind(line, ":") + 1))
      end
    end)
    it("run without icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md:1:3:hello world",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:10:83: ok ok",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:81:3: local query = 'hello'",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:4:1: print('goodbye world')",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:3:10: hello world",
      }
      actions.setqflist_rg(lines)
      assert_true(true)
    end)
    it("run with icon", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = DEVICONS_PATH
      local lines = {
        " ~/github/linrongbin16/fzfx.nvim/README.md:1:3:hello world",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:10:83: ok ok",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:81:3: local query = 'hello'",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:4:1: print('goodbye world')",
        "󰢱 ~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:3:10: hello world",
      }
      actions.setqflist_rg(lines)
      assert_true(true)
    end)
  end)

  describe("[setqflist_rg_bufnr]", function()
    it("make", function()
      local lines = {
        "1:3:hello world",
        "10:83: ok ok",
        "81:3: local query = 'hello'",
        "4:1: print('goodbye world')",
        "3:10: hello world",
      }
      local actual1 = actions._make_setqflist_rg_bufnr({}, make_context())
      assert_eq(#actual1, 0)
      local actual2 = actions._make_setqflist_rg_bufnr(lines, nil)
      assert_eq(actual2, nil)

      for i, line in ipairs(lines) do
        local ctx = make_context()
        local actual = actions._make_setqflist_rg_bufnr({ line }, ctx)
        assert_eq(type(actual), "table")
        assert_eq(#actual, 1)

        local filename = vim.api.nvim_buf_get_name(ctx.bufnr)
        filename = path.normalize(filename, { double_backslash = true, expand = true })

        for _, act in ipairs(actual) do
          local expect = parsers.parse_rg_no_filename(line)
          assert_eq(type(act), "table")
          assert_eq(act.filename, filename)
          assert_eq(act.lnum, expect.lineno)
          assert_eq(act.col, expect.column)
          assert_eq(act.text, line:sub(str.rfind(line, ":") + 1))
        end
      end
    end)
    it("run", function()
      local lines = {
        "1:3:hello world",
        "10:83: ok ok",
        "81:3: local query = 'hello'",
        "4:1: print('goodbye world')",
        "3:10: hello world",
      }
      for i, line in ipairs(lines) do
        actions.setqflist_rg_bufnr(lines, make_context())
        assert_true(true)
      end
    end)
  end)

  describe("[feed_vim_command]", function()
    --- @type fzfx.VimCommandsPipelineContext
    local CONTEXT = {
      name_column_width = 17,
      opts_column_width = 37,
    }
    it("make", function()
      local actual = actions._make_feed_vim_command({
        "FzfxCommands    Y | N | N/A  ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:215",
      }, CONTEXT)
      print(string.format("feed vim command:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      assert_true(str.startswith(actual.input, ":"))
      assert_eq(actual.mode, "n")
    end)
  end)

  describe("[feed_vim_historical_command]", function()
    it("make", function()
      local actual = actions._make_feed_vim_historical_command({
        " 998  FzfxCommands",
      }, nil)
      print(string.format("feed vim historical comman:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      assert_eq(actual.input, ":FzfxCommands")
      assert_eq(actual.mode, "n")
    end)
  end)

  describe("[feed_vim_key]", function()
    --- @type fzfx.VimKeyMapsPipelineContext
    local CONTEXT = {
      key_column_width = 44,
      opts_column_width = 26,
    }
    it("make normal keys", function()
      local parsed = actions._make_feed_vim_key({
        '<C-Tab>                                      n   |Y      |N     |N      "<C-C><C-W>w"',
      }, CONTEXT)
      -- print(
      --   string.format(
      --     "feed normal key:%s, %s, %s\n",
      --     vim.inspect(parsed.fn),
      --     vim.inspect(parsed.input),
      --     vim.inspect(parsed.mode)
      --   )
      -- )
      assert_eq(parsed.fn, "feedkeys")
      assert_eq(type(parsed.input), "string")
      assert_true(string.len(parsed.input) > 0)
      assert_eq(parsed.mode, "n")
    end)
    it("make operator-pending keys", function()
      -- local feedtype, input, mode = actions._make_feed_vim_key({
      local parsed = actions._make_feed_vim_key({
        '<C-Tab>                                      o   |Y      |N     |N      "<C-C><C-W>w"',
      }, CONTEXT)
      assert_eq(parsed, nil)
      -- print(
      --   string.format(
      --     "feed operator-pending key:%s, %s, %s\n",
      --     vim.inspect(parsed.fn),
      --     vim.inspect(parsed.input),
      --     vim.inspect(parsed.mode)
      --   )
      -- )
      -- assert_true(parsed.feedtype == nil)
      -- assert_true(parsed.input == nil)
      -- assert_true(parsed.mode == nil)
    end)
    it("<plug>", function()
      local parsed = actions._make_feed_vim_key({
        "<Plug>(YankyCycleBackward)                   n   |Y      |N     |Y      ~/.config/nvim/lazy/yanky.nvim/lua/yanky.lua:290",
      }, CONTEXT)
      print(string.format("feed_vim_key <plug>, parsed:%s\n", vim.inspect(parsed)))
      assert_eq(parsed.fn, "cmd")
      assert_eq(type(parsed.input), "string")
      assert_true(str.startswith(parsed.input, 'execute "normal '))
      assert_eq(parsed.mode, "n")
    end)
  end)

  describe("[git_checkout]", function()
    local CONTEXT = {
      remotes = { "origin" },
    }
    it("make local", function()
      local lines = {
        "main",
        "master",
        "my-plugin-dev",
        "test-config1",
      }
      for _, line in ipairs(lines) do
        assert_eq(
          string.format("!git checkout %s", line),
          actions._make_git_checkout({ line }, CONTEXT)
        )
      end
    end)
    it("make remote", function()
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
        if str.find(line, "origin/main") then
          local actual = actions._make_git_checkout({ line }, CONTEXT)
          print(string.format("git checkout remote[%d]:%s\n", i, actual))
          assert_eq(string.format("!git checkout main"), actual)
        else
          assert_eq(
            string.format("!git checkout %s", line:sub(string.len("origin/") + 1)),
            actions._make_git_checkout({ line }, CONTEXT)
          )
        end
      end
    end)
    it("make all", function()
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
        if str.find(line, "main") then
          local actual = actions._make_git_checkout({ line }, CONTEXT)
          print(
            string.format(
              "run git checkout, %s-line:%s, actual:%s\n",
              vim.inspect(i),
              vim.inspect(line),
              vim.inspect(actual)
            )
          )
          assert_eq(string.format("!git checkout main"), actual)
        else
          local actual = actions._make_git_checkout({ line }, CONTEXT)
          print(string.format("git checkout all[%d]:%s\n", i, actual))
          local split_pos = str.find(line, "remotes/origin/")
          if split_pos then
            assert_eq(
              string.format("!git checkout %s", line:sub(string.len("remotes/origin/") + 1)),
              actual
            )
          else
            assert_eq(string.format("!git checkout %s", line), actual)
          end
        end
      end
    end)
  end)

  describe("[yank_git_commit]", function()
    it("make", function()
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
          actions._make_yank_git_commit({ line })
        )
      end
    end)
  end)

  describe("[setqflist_git_status]", function()
    it("make", function()
      local lines = {
        " M fzfx/config.lua",
        " D fzfx/constants.lua",
        " M fzfx/line_helpers.lua",
        " M ../test/line_helpers_spec.lua",
        "?? ../hello",
      }
      local actual = actions._make_setqflist_git_status(lines)
      assert_eq(type(actual), "table")
      assert_eq(#actual, #lines)
      for i, act in ipairs(actual) do
        local line = lines[i]
        local parsed = parsers.parse_git_status(line)
        assert_eq(type(act), "table")
        assert_eq(act.filename, parsed.filename)
        assert_eq(act.lnum, 1)
        assert_eq(act.col, 1)
      end
    end)
  end)

  describe("[edit_git_status]", function()
    it("make", function()
      local lines = {
        " M fzfx/config.lua",
        " D fzfx/constants.lua",
        " M fzfx/line_helpers.lua",
        " M ../test/line_helpers_spec.lua",
        "?? ../hello",
      }
      local actual = actions._make_edit_git_status(lines)
      assert_eq(type(actual), "table")
      assert_eq(#actual, #lines)
      for i, act in ipairs(actual) do
        local line = lines[i]
        local parsed = parsers.parse_git_status(line)
        assert_eq(type(act), "string")
        assert_eq(act, string.format("edit! %s", parsed.filename))
      end
    end)
    it("run", function()
      local lines = {
        " M fzfx/config.lua",
        " D fzfx/constants.lua",
        " M fzfx/line_helpers.lua",
        " M ../test/line_helpers_spec.lua",
        "?? ../hello",
      }
      local actual = actions.edit_git_status(lines, make_context())
      assert_true(true)
    end)
  end)

  describe("[edit_vim_mark]", function()
    local CONTEXT = require("fzfx.cfg.vim_marks")._context_maker()
    it("make", function()
      local lines = tbl.List
        :copy(CONTEXT.marks)
        :filter(function(_, i)
          return i > 1
        end)
        :data()
      local actual = actions._make_edit_vim_mark(lines, CONTEXT)
      assert_eq(type(actual), "table")
      print(
        string.format(
          "edit_vim_mark, #actual:%s, #lines:%s\n",
          vim.inspect(#actual),
          vim.inspect(#lines)
        )
      )
      assert_true(#actual >= 2)
      for i, act in ipairs(actual) do
        if str.not_empty(act) then
          assert_true(
            str.startswith(act, "edit!")
              or str.startswith(act, "call cursor")
              or str.startswith(act, "execute")
          )
        else
          assert_eq(type(act), "function")
        end
      end
      local last1 = actual[#actual]
      local last2 = actual[#actual - 1]
      assert_true(str.startswith(last2, "call cursor"))
      assert_eq(last1, 'execute "normal! zz"')
    end)
    it("run", function()
      local lines = CONTEXT.marks
      actions.edit_vim_mark(lines, CONTEXT)
    end)
  end)

  describe("[setqflist_vim_mark]", function()
    local CONTEXT = require("fzfx.cfg.vim_marks")._context_maker()
    it("make", function()
      local lines = tbl.List
        :copy(CONTEXT.marks)
        :filter(function(_, i)
          return i > 1
        end)
        :data()
      local actual = actions._make_setqflist_vim_mark(lines, CONTEXT)
      assert_eq(type(actual), "table")
      print(
        string.format(
          "setqflist_vim_mark, #actual:%s, #lines:%s\n",
          vim.inspect(#actual),
          vim.inspect(#lines)
        )
      )
      assert_eq(#actual, #lines)
      for i, act in ipairs(actual) do
        assert_eq(type(act), "table")
        assert_eq(type(act.filename), "string")
        assert_eq(type(act.lnum), "number")
        assert_eq(type(act.col), "number")
        assert_eq(type(act.text), "string")
      end
    end)
    it("run", function()
      local lines = CONTEXT.marks
      actions.setqflist_vim_mark(lines, CONTEXT)
    end)
  end)

  describe("[_make_edit_ls]", function()
    local CONTEXT = require("fzfx.cfg.file_explorer")._context_maker()

    local LS_LINES = {
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
    local LS_EXPECTS = {
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
    local LSD_LINES = {
      "drwxr-xr-x  rlin staff 160 B  Wed Oct 25 16:59:44 2023 bin",
      ".rw-r--r--  rlin staff  54 KB Tue Oct 31 22:29:35 2023 CHANGELOG.md",
      ".rw-r--r--  rlin staff 120 B  Tue Oct 10 14:47:43 2023 codecov.yml",
      ".rw-r--r--  rlin staff 1.0 KB Mon Aug 28 12:39:24 2023 LICENSE",
      "drwxr-xr-x  rlin staff 128 B  Tue Oct 31 21:55:28 2023 lua",
      ".rw-r--r--  rlin staff  38 KB Wed Nov  1 10:29:19 2023 README.md",
      "drwxr-xr-x  rlin staff 992 B  Wed Nov  1 11:16:13 2023 test",
    }
    local LSD_EXPECTS = {
      "bin",
      "CHANGELOG.md",
      "codecov.yml",
      "LICENSE",
      "lua",
      "README.md",
      "test",
    }
    local EZA_LINES = {
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
    local EZA_EXPECTS = {
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

    it("make", function()
      if consts.HAS_LSD then
        for _, line in ipairs(LSD_LINES) do
          local actual = actions._make_edit_ls({ line }, CONTEXT)
          assert_eq(type(actual), "table")
          for _, a in ipairs(actual) do
            assert_true(str.startswith(a, "edit!"))
          end
        end
      elseif consts.HAS_EZA then
        for _, line in ipairs(EZA_LINES) do
          local actual = actions._make_edit_ls({ line }, CONTEXT)
          assert_eq(type(actual), "table")
          for _, a in ipairs(actual) do
            assert_true(str.startswith(a, "edit!"))
          end
        end
      else
        for _, line in ipairs(LS_LINES) do
          local actual = actions._make_edit_ls({ line }, CONTEXT)
          assert_eq(type(actual), "table")
          for _, a in ipairs(actual) do
            assert_true(str.startswith(a, "edit!"))
          end
        end
      end
    end)
  end)
end)
