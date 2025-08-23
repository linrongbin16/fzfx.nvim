local cwd = vim.fn.getcwd()

describe("detail.module", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local str = require("fzfx.commons.str")
  local conf = require("fzfx.config")
  local module = require("fzfx.detail.module")
  conf.setup()
  module.setup()

  describe("[module]", function()
    it("setup", function()
      conf.setup()
      module.setup()
      print(
        string.format("_FZFX_NVIM_DEBUG_ENABLE:%s\n", vim.inspect(vim.env._FZFX_NVIM_DEBUG_ENABLE))
      )
      print(
        string.format(
          "_FZFX_NVIM_DEVICONS_PATH:%s\n",
          vim.inspect(vim.env._FZFX_NVIM_DEVICONS_PATH)
        )
      )
      print(
        string.format(
          "_FZFX_NVIM_UNKNOWN_FILE_ICON:%s\n",
          vim.inspect(vim.env._FZFX_NVIM_UNKNOWN_FILE_ICON)
        )
      )
      print(
        string.format(
          "_FZFX_NVIM_FILE_FOLDER_ICON:%s\n",
          vim.inspect(vim.env._FZFX_NVIM_FILE_FOLDER_ICON)
        )
      )
      print(
        string.format(
          "_FZFX_NVIM_FILE_FOLDER_OPEN_ICON:%s\n",
          vim.inspect(vim.env._FZFX_NVIM_FILE_FOLDER_OPEN_ICON)
        )
      )
      assert_eq(vim.env._FZFX_NVIM_DEBUG_ENABLE, "0")
      assert_true(
        vim.env._FZFX_NVIM_DEVICONS_PATH == nil
          or (
            type(vim.env._FZFX_NVIM_DEVICONS_PATH) == "string"
            and type(str.find(vim.env._FZFX_NVIM_DEVICONS_PATH, "nvim-web-devicons")) == "number"
          )
      )
      assert_true(vim.env._FZFX_NVIM_UNKNOWN_FILE_ICON == nil)
      assert_true(vim.env._FZFX_NVIM_FILE_FOLDER_ICON == nil)
      assert_true(vim.env._FZFX_NVIM_FILE_FOLDER_OPEN_ICON == nil)
    end)
  end)
end)
