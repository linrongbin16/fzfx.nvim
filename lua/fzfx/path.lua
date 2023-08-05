local constants = require("fzfx.constants")

local Context = {
    base_dir = nil,
    sep = nil,
}

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

--- @return string
local function tempname()
    return vim.fn.tempname()
end

--- @return string
local function windows_named_pipe()
    assert(
        constants.is_windows,
        string.format("error! must be windows to get the windows named pipe")
    )
    return string.format("\\\\%.\\pipe\\nvim-%s", os.clock())
end

local M = {
    -- path
    normalize = normalize,
    sep = sep,
    join = join,

    -- plugin dir
    base_dir = base_dir,

    -- temp file
    tempname = tempname,

    -- windows named pipe
    windows_named_pipe = windows_named_pipe,
}

return M
