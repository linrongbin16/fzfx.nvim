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
  local str = require("fzfx.commons.str")
  local tbl = require("fzfx.commons.tbl")
  local path = require("fzfx.commons.path")
  local actions = require("fzfx.helper.actions")
  local parsers = require("fzfx.helper.parsers")
  local contexts_helper = require("fzfx.helper.contexts")

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
      actions.edit_find(lines, contexts_helper.make_pipeline_context())
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
      actions.edit_find(lines, contexts_helper.make_pipeline_context())
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
      assert_eq(#actual, #lines + 2)
      for i, act in ipairs(actual) do
        if i <= #lines then
          local expect = string.format(
            "edit! %s",
            path.normalize(str.split(lines[i], ":")[1], { double_backslash = true, expand = true })
          )
          assert_eq(act, expect)
        elseif i == #lines + 1 then
          assert_eq(act, "call setpos('.', [0, 81, 1])")
        else
          assert_eq(act, 'execute "normal! zz"')
        end
      end
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
      assert_eq(#actual, #lines + 2)
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
        assert_eq(actual[i], expect)
      end
      assert_true(str.find(actual[6], "setpos") > 0)
      assert_eq(actual[7], 'execute "normal! zz"')
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
      actions.edit_grep(lines, contexts_helper.make_pipeline_context())
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
      actions.edit_grep(lines, contexts_helper.make_pipeline_context())
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
        assert_true(str.startswith(actual[1], "call setpos('.'"))
        assert_eq(actual[2], 'execute "normal! zz"')
      end
    end)
  end)

  describe("[set_cursor_grep_no_filename]", function()
    it("run", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "38: this is fzfx",
        "1",
        "1:hello world",
        "12:81: goodbye",
        "81:72:9129",
      }
      actions.set_cursor_grep_no_filename(lines, contexts_helper.make_pipeline_context())
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

  describe("[setqflist_grep_no_filename]", function()
    it("make", function()
      local lines = {
        "1:hello world",
        "10: ok ok",
        "81: local query = 'hello'",
        "4: print('goodbye world')",
        "3: hello world",
      }
      local actual1 =
        actions._make_setqflist_grep_no_filename({}, contexts_helper.make_pipeline_context())
      assert_eq(#actual1, 0)
      local actual2 = actions._make_setqflist_grep_no_filename(lines, nil)
      assert_eq(actual2, nil)

      for i, line in ipairs(lines) do
        local ctx = contexts_helper.make_pipeline_context()
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
        local ctx = contexts_helper.make_pipeline_context()
        actions.setqflist_grep_no_filename(lines, ctx)
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
      assert_eq(#actual, #lines + 2)
      for i, act in ipairs(actual) do
        if i <= #lines then
          local expect = string.format(
            "edit! %s",
            path.normalize(str.split(lines[i], ":")[1], { double_backslash = true, expand = true })
          )
          assert_eq(act, expect)
        elseif i == #lines + 1 then
          assert_eq(act, "call setpos('.', [0, 81, 71])")
        else
          assert_eq(act, 'execute "normal! zz"')
        end
      end
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
      assert_eq(#actual, #lines + 2)
      for i, act in ipairs(actual) do
        if i <= #lines then
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
        elseif i == #lines + 1 then
          assert_eq(act, "call setpos('.', [0, 81, 72])")
        else
          assert_eq(act, 'execute "normal! zz"')
        end
      end
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
      actions.edit_rg(lines, contexts_helper.make_pipeline_context())
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
      actions.edit_rg(lines, contexts_helper.make_pipeline_context())
      assert_true(true)
    end)
  end)
  describe("[_make_set_cursor_rg_no_filename]", function()
    it("empty", function()
      local actual = actions._make_set_cursor_rg_no_filename({})
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
        local actual = actions._make_set_cursor_rg_no_filename({ line })
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

        assert_true(str.startswith(actual[1], "call setpos('.'"))
        assert_eq(actual[2], 'execute "normal! zz"')
      end
    end)
  end)
  describe("[set_cursor_rg_no_filename]", function()
    it("run", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      local lines = {
        "1:1:ok",
        "1:2:hello",
        "1:3:hello world",
        "12:81: goodbye",
        "81:71:9129",
      }
      actions.set_cursor_rg_no_filename(lines, contexts_helper.make_pipeline_context())
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

  describe("[setqflist_rg_no_filename]", function()
    it("make", function()
      local lines = {
        "1:3:hello world",
        "10:83: ok ok",
        "81:3: local query = 'hello'",
        "4:1: print('goodbye world')",
        "3:10: hello world",
      }
      local actual1 =
        actions._make_setqflist_rg_no_filename({}, contexts_helper.make_pipeline_context())
      assert_eq(#actual1, 0)
      local actual2 = actions._make_setqflist_rg_no_filename(lines, nil)
      assert_eq(actual2, nil)

      for i, line in ipairs(lines) do
        local ctx = contexts_helper.make_pipeline_context()
        local actual = actions._make_setqflist_rg_no_filename({ line }, ctx)
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
        actions.setqflist_rg_no_filename(lines, contexts_helper.make_pipeline_context())
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
      local actual = actions.edit_git_status(lines, contexts_helper.make_pipeline_context())
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
              or str.startswith(act, "call setpos")
              or str.startswith(act, "execute")
          )
        else
          assert_eq(type(act), "function")
        end
      end
      local last1 = actual[#actual]
      local last2 = actual[#actual - 1]
      assert_true(str.startswith(last2, "call setpos('.', "))
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
end)
