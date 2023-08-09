local constants = require("fzfx.constants")

--- @param path string
--- @return string
local function normalize(path)
    local result = path
    if string.match(path, "\\") then
        result, _ = string.gsub(path, "\\", "/")
    end
    return vim.fn.trim(result)
end

local function sep()
    return (constants.is_windows and vim.o.shellslash) and "\\" or "/"
end

local function join(...)
    return table.concat({ ... }, sep())
end

--- @return string
local function base_dir()
    return vim.fn["fzfx#nvim#base_dir"]()
end

local M = {
    -- path
    normalize = normalize,
    sep = sep,
    join = join,

    -- plugin dir
    base_dir = base_dir,
}

return M
