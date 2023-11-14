local rxi_json = require("fzfx.rxi_json")

local M = {
  encode = (vim.fn.has("nvim-0.9") and vim.json ~= nil) and vim.json.encode
    or rxi_json.encode,
  decode = (vim.fn.has("nvim-0.9") and vim.json ~= nil) and vim.json.decode
    or rxi_json.decode,
}

return M
