---@diagnostic disable: undefined-field, unused-local, need-check-nil, param-type-mismatch
local cwd = vim.fn.getcwd()

describe("detail.yanks", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
  end)

  require("fzfx.config").setup()
  local yanks = require("fzfx.detail.yanks")

  describe("[Yank]", function()
    it("creates", function()
      local yk =
        yanks.Yank:new("regname", "regtext", "regtype", "filename", "filetype")
      assert_eq(type(yk), "table")
      assert_eq(yk.regname, "regname")
      assert_eq(yk.regtext, "regtext")
      assert_eq(yk.regtype, "regtype")
      assert_eq(yk.filename, "filename")
      assert_eq(yk.filetype, "filetype")
    end)
  end)
  describe("[YankHistory]", function()
    it("creates", function()
      local yk = yanks.YankHistory:new(10)
      assert_eq(type(yk), "table")
    end)
    it("loop", function()
      local yk = yanks.YankHistory:new(10)
      assert_eq(type(yk), "table")
      for i = 1, 10 do
        yk:push(i)
      end
      local p = yk:begin()
      while p do
        local actual = yk:get(p)
        assert_eq(actual, p)
        p = yk:next(p)
      end
      yk = yanks.YankHistory:new(10)
      for i = 1, 15 do
        yk:push(i)
      end
      p = yk:begin()
      while p do
        local actual = yk:get(p)
        if p <= 5 then
          assert_eq(actual, p + 10)
        else
          assert_eq(actual, p)
        end
        p = yk:next(p)
      end
      yk = yanks.YankHistory:new(10)
      for i = 1, 20 do
        yk:push(i)
      end
      p = yk:begin()
      while p do
        local actual = yk:get(p)
        assert_eq(actual, p + 10)
        p = yk:next(p)
      end
    end)
    it("get latest", function()
      local yk = yanks.YankHistory:new(10)
      for i = 1, 50 do
        yk:push(i)
        assert_eq(yk:get(), i)
      end
      local p = yk:begin()
      print(string.format("|yank_history_spec| begin, p:%s\n", vim.inspect(p)))
      while p do
        local actual = yk:get(p)
        print(
          string.format(
            "|yank_history_spec| get, p:%s, actual:%s\n",
            vim.inspect(p),
            vim.inspect(actual)
          )
        )
        assert_eq(actual, p + 40)
        p = yk:next(p)
        print(string.format("|yank_history_spec| next, p:%s\n", vim.inspect(p)))
      end
      p = yk:rbegin()
      print(
        string.format(
          "|yank_history_spec| rbegin, p:%s, yk:%s\n",
          vim.inspect(p),
          vim.inspect(yk)
        )
      )
      while p do
        local actual = yk:get(p)
        print(
          string.format(
            "|yank_history_spec| rget, p:%s, actual:%s, yk:%s\n",
            vim.inspect(p),
            vim.inspect(actual),
            vim.inspect(yk)
          )
        )
        assert_eq(actual, p + 40)
        p = yk:rnext(p)
        print(
          string.format(
            "|yank_history_spec| rnext, p:%s, yk:%s\n",
            vim.inspect(p),
            vim.inspect(yk)
          )
        )
      end
    end)
  end)
  describe("[setup]", function()
    it("setup", function()
      yanks.setup()
      assert_eq(type(yanks._get_yank_history_instance()), "table")
    end)
  end)
  describe("[_get_register_info]", function()
    it("_get_register_info", function()
      yanks.setup()
      vim.cmd([[
            edit README.md
            call feedkeys('V', 'n')
            ]])
      local actual = yanks._get_register_info("+")
      print(string.format("register info:%s\n", vim.inspect(actual)))
      assert_eq(actual.regname, "+")
      assert_eq(type(actual.regtext), "string")
      assert_true(string.len(actual.regtext) >= 0)
      assert_eq(type(actual.regtype), "string")
      assert_true(string.len(actual.regtype) >= 0)
      yanks.save_yank()
      local y = yanks.get_yank()
      print(string.format("yank:%s\n", vim.inspect(y)))
      assert_eq(type(y), "table")
      assert_eq(type(y.timestamp), "number")
      assert_true(y.timestamp >= 0)
    end)
  end)
end)
