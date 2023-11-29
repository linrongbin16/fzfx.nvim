local actboy168_json = require("fzfx.lib.actboy168_json")

local M = {
  encode = (vim.fn.has("nvim-0.9") and vim.json ~= nil) and vim.json.encode
    or actboy168_json.encode,
  decode = (vim.fn.has("nvim-0.9") and vim.json ~= nil) and vim.json.decode
    or actboy168_json.decode,
}

return M
