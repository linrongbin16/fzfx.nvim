local log = require("fzfx.lib.log")
local config = require("fzfx.config")

local M = {}

--- @param plugin string
--- @param path string
--- @return string?
local function search_module_path(plugin, path)
  local ok, module_path_or_err = pcall(require, plugin)
  if not ok then
    -- log.debug(
    --     "|fzfx.module - search_module_path| failed to load lua module %s: %s",
    --     vim.inspect(plugin),
    --     vim.inspect(module_path_or_err)
    -- )
    return nil
  end
  local runtime_paths = vim.api.nvim_list_runtime_paths()
  for i, p in ipairs(runtime_paths) do
    -- log.debug("|fzfx.module - search_module_path| p[%d]:%s", i, p)
    if type(p) == "string" and string.match(p, path) then
      return p
    end
  end
  -- log.debug(
  --     "|fzfx.module - search_module_path| failed to find lua module %s on runtimepath: %s",
  --     vim.inspect(plugin),
  --     vim.inspect(runtime_paths)
  -- )
  return nil
end

M.setup = function()
  -- debug
  vim.env._FZFX_NVIM_DEBUG_ENABLE = config.get().debug.enable and 1 or 0

  -- icon
  if type(config.get().icons) == "table" then
    local devicons_path = search_module_path("nvim-web-devicons", "nvim%-web%-devicons")
    -- log.debug("|fzfx.module - setup| devicons path:%s", devicons_path)
    if type(devicons_path) == "string" and string.len(devicons_path) > 0 then
      vim.env._FZFX_NVIM_DEVICONS_PATH = devicons_path
      vim.env._FZFX_NVIM_UNKNOWN_FILE_ICON = config.get().icons.unknown_file
      vim.env._FZFX_NVIM_FILE_FOLDER_ICON = config.get().icons.folder
      vim.env._FZFX_NVIM_FILE_FOLDER_OPEN_ICON = config.get().icons.folder_open
      -- else
      -- log.debug(
      --     "|fzfx.module - setup| you have configured 'icons' while cannot find 'nvim-web-devicons' plugin!"
      -- )
    end
  end

  -- self
  local self_path = search_module_path("fzfx", "fzfx%.nvim")
  -- log.debug("|fzfx.module - setup| self path:%s", self_path)
  log.ensure(
    type(self_path) == "string" and string.len(self_path) > 0,
    "|setup| failed to find 'fzfx.nvim' plugin!"
  )
  vim.env._FZFX_NVIM_SELF_PATH = self_path
end

return M
