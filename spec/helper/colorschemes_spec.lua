local cwd = vim.fn.getcwd()

describe("helper.colorschemes_helper", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
    vim.cmd("noautocmd colorscheme darkblue")
  end)

  local colorschemes_helper = require("fzfx.helper.colorschemes")
  require("fzfx").setup()

  describe("[color name cache]", function()
    it("get_color_name", function()
      assert_true(
        type(colorschemes_helper.get_color_name()) == "string"
          or colorschemes_helper.get_color_name() == nil
      )
    end)
    it("dump_color_name", function()
      colorschemes_helper.dump_color_name(vim.g.colors_name)
    end)
  end)
end)
