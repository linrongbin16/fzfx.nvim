---@diagnostic disable: undefined-doc-name
---@mod micro-async.lsp

local wrap = require("fzfx.commons.micro-async").wrap

---Async wrapper for LSP requests
local lsp = {}

---Async wrapper around `vim.lsp.buf_request`.
---@type async fun(bufnr: integer, method: string, params: table?): error: lsp.ResponseError?, result: table, context: lsp.HandlerContext, config: table?
lsp.buf_request = wrap(vim.lsp.buf_request, 4)

---Async wrapper around `vim.lsp.buf_request_all`.
---@type async fun(bufnr: integer, method: string, params: table?): table<integer, { error: lsp.ResponseError, result: table }>
lsp.buf_request_all = wrap(vim.lsp.buf_request_all, 4)

lsp.request = {}

lsp.request.references = function(buf, params)
  return lsp.buf_request(buf, "textDocument/references", params)
end

lsp.request.definition = function(buf, params)
  return lsp.buf_request(buf, "textDocument/definition", params)
end

lsp.request.type_definition = function(buf, params)
  return lsp.buf_request(buf, "textDocument/typeDefinition", params)
end

lsp.request.implementation = function(buf, params)
  return lsp.buf_request(buf, "textDocument/implementation", params)
end

lsp.request.rename = function(buf, params)
  return lsp.buf_request(buf, "textDocument/rename", params)
end

lsp.request.signature_help = function(buf, params)
  return lsp.buf_request(buf, "textDocument/signatureHelp", params)
end

lsp.request.document_symbols = function(buf, params)
  return lsp.buf_request(buf, "textDocument/documentSymbol", params)
end

lsp.request.hover = function(buf, params)
  return lsp.buf_request(buf, "textDocument/hover", params)
end

lsp.request.inlay_hint = function(buf, params)
  return lsp.buf_request(buf, "textDocument/inlayHint", params)
end

lsp.request.code_actions = function(buf, params)
  return lsp.buf_request(buf, "textDocument/codeAction", params)
end

return lsp
