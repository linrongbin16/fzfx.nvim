--- @param path string
--- @return string
local function normalize(path)
    local result = path
    if string.match(path, "\\") then
        result, _ = string.gsub(path, "\\", "/")
    end
    return vim.fn.trim(result)
end

--- @return string
local function tempfilename()
    return vim.fn.tempname()
end

local M = {
    normalize = normalize,
    tempfilename = tempfilename,
}

return M
