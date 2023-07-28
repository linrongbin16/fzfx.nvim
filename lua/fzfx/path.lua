local Cache = {
    plugin_home = nil,
    plugin_bin = nil,
    separator = nil,
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

--- @return string
local function plugin_home()
    if Cache.plugin_home == nil then
        Cache.plugin_home = vim.fn["fzfx#nvim#plugin_home"]()
    end
    return Cache.plugin_home
end

--- @return string
local function plugin_bin()
    if Cache.plugin_bin == nil then
        Cache.plugin_bin = vim.fn["fzfx#nvim#plugin_bin"]()
    end
    return Cache.plugin_bin
end

local function separator()
    if Cache.separator == nil then
        Cache.separator = (vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0)
                and "\\"
            or "/"
    end
    return Cache.separator
end

--- @return string
local function tempname()
    return vim.fn.tempname()
end

--- @class SwapableFile
--- @field current string|nil
--- @field next string|nil
--- @field swap string|nil

--- @type SwapableFile
local SwapableFile = {
    current = nil,
    next = nil,
    swap = nil,
}

--- @return string
function SwapableFile:swap_by_shell()
    return string.format(
        "mv %s %s && mv %s %s && mv %s %s",
        self.current,
        self.swap,
        self.next,
        self.current,
        self.swap,
        self.next
    )
end

--- @param name string
--- @param current_text string[]
--- @param next_text string[]
--- @param debug boolean
--- @return SwapableFile
local function new_swapable_file(name, current_text, next_text, debug)
    local init = nil
    if debug then
        init = {
            current = string.format(
                "%s%sfzfx.nvim%s%s_current_swapable",
                vim.fn.stdpath("data"),
                separator(),
                separator(),
                name
            ),
            next = string.format(
                "%s%sfzfx.nvim%s%s_next_swapable",
                vim.fn.stdpath("data"),
                separator(),
                separator(),
                name
            ),
            swap = string.format(
                "%s%sfzfx.nvim%s%s_swap_swapable",
                vim.fn.stdpath("data"),
                separator(),
                separator(),
                name
            ),
        }
    else
        init({
            current = tempname(),
            next = tempname(),
            swap = tempname(),
        })
    end
    --- @type SwapableFile
    local sf = vim.tbl_deep_extend("force", vim.deepcopy(SwapableFile), init)
    vim.fn.writefile(current_text, sf.current)
    vim.fn.writefile(next_text, sf.next)
    return sf
end

local M = {
    -- path
    normalize = normalize,
    separator = separator,

    -- plugin dir
    plugin_home = plugin_home,
    plugin_bin = plugin_bin,

    -- temp file
    tempname = tempname,

    -- swapable file
    new_swapable_file = new_swapable_file,
}

return M
