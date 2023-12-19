---@diagnostic disable: undefined-field, unused-local
local cwd = vim.fn.getcwd()

describe("lib.spawn", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  require("fzfx").setup()
  local strs = require("fzfx.lib.strings")
  local fs = require("fzfx.lib.filesystems")
  local spawn = require("fzfx.lib.spawn")

  local dummy = function() end

  describe("[blocking Spawn]", function()
    it("open", function()
      local sp = spawn.Spawn:make(
        { "cat", "README.md" },
        { on_stdout = dummy, blocking = true }
      )
      assert_eq(type(sp), "table")
      assert_eq(type(sp.cmds), "table")
      assert_eq(#sp.cmds, 2)
      assert_eq(sp.cmds[1], "cat")
      assert_eq(sp.cmds[2], "README.md")
      assert_eq(type(sp.out_pipe), "userdata")
      assert_eq(type(sp.err_pipe), "userdata")
    end)
    it("consume line", function()
      local content = fs.readfile("README.md") --[[@as string]]
      local lines = fs.readlines("README.md") --[[@as table]]

      local i = 1
      local function process_line(line)
        -- print(string.format("[%d]%s", i, line))
        assert_eq(type(line), "string")
        assert_eq(line, lines[i])
        i = i + 1
      end
      local sp = spawn.Spawn:make(
        { "cat", "README.md" },
        { on_stdout = process_line, blocking = true }
      )
      local pos = sp:_consume_line(content, process_line)
      if pos <= #content then
        local line = content:sub(pos, #content)
        process_line(line)
      end
    end)
    it("stdout on newline", function()
      local content = fs.readfile("README.md") --[[@as string]]
      local lines = fs.readlines("README.md") --[[@as table]]

      local i = 1
      local function process_line(line)
        -- print(string.format("[%d]%s\n", i, line))
        assert_eq(type(line), "string")
        assert_eq(line, lines[i])
        i = i + 1
      end
      local sp = spawn.Spawn:make(
        { "cat", "README.md" },
        { on_stdout = process_line, blocking = true }
      )
      local content_splits = strs.split(content, "\n", { trimempty = false })
      for j, splits in ipairs(content_splits) do
        sp:_on_stdout(nil, splits)
        if j < #content_splits then
          sp:_on_stdout(nil, "\n")
        end
      end
      sp:_on_stdout(nil, nil)
      assert_true(sp.out_pipe:is_closing())
    end)
    it("stdout on whitespace", function()
      local content = fs.readfile("README.md") --[[@as string]]
      local lines = fs.readlines("README.md") --[[@as table]]

      local i = 1
      local function process_line(line)
        -- print(string.format("[%d]%s\n", i, line))
        assert_eq(type(line), "string")
        assert_eq(line, lines[i])
        i = i + 1
      end
      local sp = spawn.Spawn:make(
        { "cat", "README.md" },
        { on_stdout = process_line, blocking = true }
      )
      local content_splits = strs.split(content, " ", { trimempty = false })
      for j, splits in ipairs(content_splits) do
        sp:_on_stdout(nil, splits)
        if j < #content_splits then
          sp:_on_stdout(nil, " ")
        end
      end
      sp:_on_stdout(nil, nil)
      assert_true(sp.out_pipe:is_closing())
    end)
    local delimiter_i = 0
    while delimiter_i <= 25 do
      -- lower case: a
      local lower_char = string.char(97 + delimiter_i)
      it(string.format("stdout on %s", lower_char), function()
        local content = fs.readfile("README.md") --[[@as string]]
        local lines = fs.readlines("README.md") --[[@as table]]

        local i = 1
        local function process_line(line)
          -- print(string.format("[%d]%s\n", i, line))
          assert_eq(type(line), "string")
          assert_eq(line, lines[i])
          i = i + 1
        end
        local sp = spawn.Spawn:make(
          { "cat", "README.md" },
          { on_stdout = process_line, on_stderr = dummy, blocking = true }
        )
        local content_splits =
          strs.split(content, lower_char, { trimempty = false })
        for j, splits in ipairs(content_splits) do
          sp:_on_stdout(nil, splits)
          if j < #content_splits then
            sp:_on_stdout(nil, lower_char)
          end
        end
        sp:_on_stdout(nil, nil)
        assert_true(sp.out_pipe:is_closing())
      end)
      -- upper case: A
      local upper_char = string.char(65 + delimiter_i)
      it(string.format("stdout on %s", upper_char), function()
        local content = fs.readfile("README.md") --[[@as string]]
        local lines = fs.readlines("README.md") --[[@as table]]

        local i = 1
        local function process_line(line)
          -- print(string.format("[%d]%s\n", i, line))
          assert_eq(type(line), "string")
          assert_eq(line, lines[i])
          i = i + 1
        end
        local sp = spawn.Spawn:make(
          { "cat", "README.md" },
          { on_stdout = process_line, on_stderr = dummy, blocking = true }
        )
        local content_splits =
          strs.split(content, upper_char, { trimempty = false })
        for j, splits in ipairs(content_splits) do
          sp:_on_stdout(nil, splits)
          if j < #content_splits then
            sp:_on_stdout(nil, upper_char)
          end
        end
        sp:_on_stdout(nil, nil)
        assert_true(sp.out_pipe:is_closing())
      end)
      delimiter_i = delimiter_i + math.random(1, 5)
    end
    it("stderr", function()
      local sp = spawn.Spawn:make(
        { "cat", "README.md" },
        { on_stdout = dummy, on_stderr = dummy, blocking = true }
      )
      sp:_on_stderr(nil, nil)
      assert_true(sp.err_pipe:is_closing())
    end)
    it("stderr2", function()
      local i = 1
      local function process_line(line)
        -- print(string.format("process[%d]:%s\n", i, line))
      end
      local sp = spawn.Spawn:make(
        { "cat", "non_exists.txt" },
        { on_stdout = process_line, on_stderr = process_line, blocking = true }
      )
      sp:run()
    end)
    it("iterate on README.md", function()
      local lines = fs.readlines("README.md") --[[@as table]]

      local i = 1
      local function process_line(line)
        -- print(string.format("[%d]%s\n", i, line))
        assert_eq(type(line), "string")
        assert_eq(lines[i], line)
        i = i + 1
      end

      local sp = spawn.Spawn:make(
        { "cat", "README.md" },
        { on_stdout = process_line, on_stderr = dummy, blocking = true }
      )
      sp:run()
    end)
    it("iterate on lua/fzfx/config.lua", function()
      local lines = fs.readlines("lua/fzfx/config.lua") --[[@as table]]

      local i = 1
      local function process_line(line)
        -- print(string.format("[%d]%s\n", i, line))
        assert_eq(type(line), "string")
        assert_eq(lines[i], line)
        i = i + 1
      end

      local sp = spawn.Spawn:make(
        { "cat", "lua/fzfx/config.lua" },
        { on_stdout = process_line, on_stderr = dummy, blocking = true }
      )
      sp:run()
    end)
    it("close handle", function()
      local sp = spawn.Spawn:make(
        { "cat", "lua/fzfx/config.lua" },
        { on_stdout = dummy, on_stderr = dummy, blocking = true }
      )
      sp:run()
      assert_true(sp.process_handle ~= nil)
      sp:_close_handle(sp.process_handle)
      assert_true(sp.process_handle:is_closing())
    end)
  end)
  describe("[nonblocking Spawn]", function()
    it("open", function()
      local sp = spawn.Spawn:make(
        { "cat", "README.md" },
        { on_stdout = dummy, blocking = false }
      )
      assert_eq(type(sp), "table")
      assert_eq(type(sp.cmds), "table")
      assert_eq(#sp.cmds, 2)
      assert_eq(sp.cmds[1], "cat")
      assert_eq(sp.cmds[2], "README.md")
      assert_eq(type(sp.out_pipe), "userdata")
      assert_eq(type(sp.err_pipe), "userdata")
    end)
    it("consume line", function()
      local content = fs.readfile("README.md") --[[@as string]]
      local lines = fs.readlines("README.md") --[[@as table]]

      local i = 1
      local function process_line(line)
        -- print(string.format("[%d]%s", i, line))
        assert_eq(type(line), "string")
        assert_eq(line, lines[i])
        i = i + 1
      end
      local sp = spawn.Spawn:make(
        { "cat", "README.md" },
        { on_stdout = process_line, blocking = false }
      )
      local pos = sp:_consume_line(content, process_line)
      if pos <= #content then
        local line = content:sub(pos, #content)
        process_line(line)
      end
    end)
    it("stdout on newline", function()
      local content = fs.readfile("README.md") --[[@as string]]
      local lines = fs.readlines("README.md") --[[@as table]]

      local i = 1
      local function process_line(line)
        -- print(string.format("[%d]%s\n", i, line))
        assert_eq(type(line), "string")
        assert_eq(line, lines[i])
        i = i + 1
      end
      local sp = spawn.Spawn:make(
        { "cat", "README.md" },
        { on_stdout = process_line, blocking = false }
      )
      local content_splits = strs.split(content, "\n", { trimempty = false })
      for j, splits in ipairs(content_splits) do
        sp:_on_stdout(nil, splits)
        if j < #content_splits then
          sp:_on_stdout(nil, "\n")
        end
      end
      sp:_on_stdout(nil, nil)
      assert_true(sp.out_pipe:is_closing())
    end)
    it("stdout on whitespace", function()
      local content = fs.readfile("README.md") --[[@as string]]
      local lines = fs.readlines("README.md") --[[@as table]]

      local i = 1
      local function process_line(line)
        -- print(string.format("[%d]%s\n", i, line))
        assert_eq(type(line), "string")
        assert_eq(line, lines[i])
        i = i + 1
      end
      local sp = spawn.Spawn:make(
        { "cat", "README.md" },
        { on_stdout = process_line, blocking = false }
      )
      local content_splits = strs.split(content, " ", { trimempty = false })
      for j, splits in ipairs(content_splits) do
        sp:_on_stdout(nil, splits)
        if j < #content_splits then
          sp:_on_stdout(nil, " ")
        end
      end
      sp:_on_stdout(nil, nil)
      assert_true(sp.out_pipe:is_closing())
    end)
    local delimiter_i = 0
    while delimiter_i <= 25 do
      -- lower case: a
      local lower_char = string.char(97 + delimiter_i)
      it(string.format("stdout on %s", lower_char), function()
        local content = fs.readfile("README.md") --[[@as string]]
        local lines = fs.readlines("README.md") --[[@as table]]

        local i = 1
        local function process_line(line)
          -- print(string.format("[%d]%s\n", i, line))
          assert_eq(type(line), "string")
          assert_eq(line, lines[i])
          i = i + 1
        end
        local sp = spawn.Spawn:make(
          { "cat", "README.md" },
          { on_stdout = process_line, on_stderr = dummy, blocking = false }
        )
        local content_splits =
          strs.split(content, lower_char, { trimempty = false })
        for j, splits in ipairs(content_splits) do
          sp:_on_stdout(nil, splits)
          if j < #content_splits then
            sp:_on_stdout(nil, lower_char)
          end
        end
        sp:_on_stdout(nil, nil)
        assert_true(sp.out_pipe:is_closing())
      end)
      -- upper case: A
      local upper_char = string.char(65 + delimiter_i)
      it(string.format("stdout on %s", upper_char), function()
        local content = fs.readfile("README.md") --[[@as string]]
        local lines = fs.readlines("README.md") --[[@as table]]

        local i = 1
        local function process_line(line)
          -- print(string.format("[%d]%s\n", i, line))
          assert_eq(type(line), "string")
          assert_eq(line, lines[i])
          i = i + 1
        end
        local sp = spawn.Spawn:make(
          { "cat", "README.md" },
          { on_stdout = process_line, on_stderr = dummy, blocking = false }
        )
        local content_splits =
          strs.split(content, upper_char, { trimempty = false })
        for j, splits in ipairs(content_splits) do
          sp:_on_stdout(nil, splits)
          if j < #content_splits then
            sp:_on_stdout(nil, upper_char)
          end
        end
        sp:_on_stdout(nil, nil)
        assert_true(sp.out_pipe:is_closing())
      end)
      delimiter_i = delimiter_i + math.random(1, 5)
    end
    it("stderr", function()
      local sp = spawn.Spawn:make(
        { "cat", "README.md" },
        { on_stdout = dummy, on_stderr = dummy, blocking = false }
      )
      sp:_on_stderr(nil, nil)
      assert_true(sp.err_pipe:is_closing())
    end)
    it("stderr2", function()
      local i = 1
      local function process_line(line)
        -- print(string.format("process[%d]:%s\n", i, line))
      end
      local sp = spawn.Spawn:make(
        { "cat", "non_exists.txt" },
        { on_stdout = process_line, on_stderr = process_line, blocking = false }
      )
      sp:run()
    end)
    it("iterate on README.md", function()
      local lines = fs.readlines("README.md") --[[@as table]]

      local i = 1
      local function process_line(line)
        -- print(string.format("[%d]%s\n", i, line))
        assert_eq(type(line), "string")
        assert_eq(lines[i], line)
        i = i + 1
      end

      local sp = spawn.Spawn:make(
        { "cat", "README.md" },
        { on_stdout = process_line, on_stderr = dummy, blocking = false }
      )
      sp:run()
    end)
    it("iterate on lua/fzfx/config.lua", function()
      local lines = fs.readlines("lua/fzfx/config.lua") --[[@as table]]

      local i = 1
      local function process_line(line)
        -- print(string.format("[%d]%s\n", i, line))
        assert_eq(type(line), "string")
        assert_eq(lines[i], line)
        i = i + 1
      end

      local sp = spawn.Spawn:make(
        { "cat", "lua/fzfx/config.lua" },
        { on_stdout = process_line, on_stderr = dummy, blocking = false }
      )
      sp:run()
    end)
    it("close handle", function()
      local sp = spawn.Spawn:make(
        { "cat", "lua/fzfx/config.lua" },
        { on_stdout = dummy, on_stderr = dummy, blocking = false }
      )
      sp:run()
      assert_true(sp.process_handle ~= nil)
      sp:_close_handle(sp.process_handle)
      assert_true(sp.process_handle:is_closing())
    end)
  end)
end)
