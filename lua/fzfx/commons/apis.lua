local NVIM_VERSION_0_8 = false
local NVIM_VERSION_0_9 = false

do
  NVIM_VERSION_0_8 = require("fzfx.commons.versions").ge({ 0, 8 })
  NVIM_VERSION_0_9 = require("fzfx.commons.versions").ge({ 0, 9 })
end

local M = {}

-- buffer {

--- @param bufnr integer
--- @param name string
--- @return any
M.get_buf_option = function(bufnr, name)
  if NVIM_VERSION_0_8 then
    return vim.api.nvim_get_option_value(name, { buf = bufnr })
  else
    return vim.api.nvim_buf_get_option(bufnr, name)
  end
end

--- @param bufnr integer
--- @param name string
--- @param value any
M.set_buf_option = function(bufnr, name, value)
  if NVIM_VERSION_0_8 then
    return vim.api.nvim_set_option_value(name, value, { buf = bufnr })
  else
    return vim.api.nvim_buf_set_option(bufnr, name, value)
  end
end

-- buffer }

-- window {

--- @param winnr integer
--- @param name string
--- @return any
M.get_win_option = function(winnr, name)
  if NVIM_VERSION_0_8 then
    return vim.api.nvim_get_option_value(name, { win = winnr })
  else
    return vim.api.nvim_win_get_option(winnr, name)
  end
end

--- @param winnr integer
--- @param name string
--- @param value any
--- @return any
M.set_win_option = function(winnr, name, value)
  if NVIM_VERSION_0_8 then
    return vim.api.nvim_set_option_value(name, value, { win = winnr })
  else
    return vim.api.nvim_win_set_option(winnr, name, value)
  end
end

-- window }

-- highlight {

--- @param hl string
--- @return {fg:integer?,bg:integer?,ctermfg:integer?,ctermbg:integer?}
M.get_hl = function(hl)
  if NVIM_VERSION_0_9 then
    return vim.api.nvim_get_hl(0, { name = hl, link = false })
  else
    local rgb_hldef = vim.api.nvim_get_hl_by_name(hl, true)
    local cterm_hldef = vim.api.nvim_get_hl_by_name(hl, false)
    local result = vim.tbl_deep_extend("force", rgb_hldef, {
      ctermfg = cterm_hldef.foreground,
      ctermbg = cterm_hldef.background,
      cterm = cterm_hldef,
    })
    result.cterm.foreground = nil
    result.cterm.background = nil
    result.sp = result.special
    result.special = nil
    result.cterm.sp = result.cterm.special
    result.cterm.special = nil
    return result
  end
end

-- highlight }

return M
