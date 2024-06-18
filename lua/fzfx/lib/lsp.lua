local version = require("fzfx.commons.version")

local M = {}

---@diagnostic disable-next-line: deprecated
M.get_clients = version.ge("0.10") and vim.lsp.get_clients or vim.lsp.get_active_clients

return M
