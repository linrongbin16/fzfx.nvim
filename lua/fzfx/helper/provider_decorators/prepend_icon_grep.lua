-- Prepend file type icons at the beginning of a line.
-- Works for grep results (or other query results followed this pattern).
-- Such as `FzfxLiveGrep`, `FzfxGLiveGrep`, `FzfxLspDiagnostics` etc.

local _prepend_icon = require("fzfx.helper.provider_decorators._prepend_icon")

local M = {}

--- @param line string
--- @return string
M.decorate = function(line)
  return _prepend_icon._decorate(line, ":", 1)
end

return M
