local cwd = vim.fn.getcwd()

describe("helper.provider_decorators._prepend_icon", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
  end)

  local str = require("fzfx.commons.str")
  local _prepend_icon = require("fzfx.helper.provider_decorators._prepend_icon")
  local HAS_DEVICONS = _prepend_icon.DEVICONS ~= nil

  describe("[_decorate]", function()
    it("test without delimiter/index", function()
      local input = "hello.txt"
      local actual = _prepend_icon._decorate(input)
      assert_eq(type(actual), "string")

      if HAS_DEVICONS then
        assert_true(actual ~= input)
        assert_true(str.endswith(actual, input))
      else
        assert_eq(actual, input)
      end
    end)
  end)
end)
