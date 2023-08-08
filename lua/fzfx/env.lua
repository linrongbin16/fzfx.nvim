local log = require("fzfx.log")

local function debug_enable()
    return tostring(vim.env._FZFX_NVIM_DEBUG_ENABLE):lower() == "1"
end

local function icon_enable()
    return tostring(vim.env._FZFX_NVIM_ICON_ENABLE):lower() == "1"
end

--- @return string|nil
local function search_module_path(plugin, path)
    local plugin_ok, plugin_module = pcall(require, plugin)
    if not plugin_ok then
        log.debug(
            "|fzfx.env - search_module_path| failed to load lua module %s: %s",
            vim.inspect(plugin),
            vim.inspect(plugin_module)
        )
        return nil
    end
    local rtp = type(vim.o.runtimepath) == "string"
            and vim.fn.split(vim.o.runtimepath, ",")
        or {}
    for i, p in ipairs(rtp) do
        log.debug("|fzfx.env - search_module_path| p[%d]:%s", i, p)
        if type(p) == "string" and string.match(p, path) then
            return p
        end
    end
    log.debug(
        "|fzfx.env - search_module_path| failed to find lua module %s on runtimepath: %s",
        vim.inspect(plugin),
        vim.inspect(rtp)
    )
    return nil
end

local function setup(options)
    vim.env._FZFX_NVIM_DEBUG_ENABLE = options.debug.enable and 1 or 0

    if options.icon.enable then
        local devicon_path =
            search_module_path("nvim-web-devicons", "nvim%-web%-devicons")
        log.debug("|fzfx.env - setup_devicon| devicon path:%s", devicon_path)
        if type(devicon_path) ~= "string" or string.len(devicon_path) == 0 then
            log.err(
                "error! you have configured 'icon.enable=true' while cannot find 'nvim-web-devicons' plugin!"
            )
        else
            vim.env._FZFX_NVIM_DEVICON_PATH = devicon_path
            vim.env._FZFX_NVIM_ICON_ENABLE = 1
        end
    end
end

local M = {
    debug_enable = debug_enable,
    icon_enable = icon_enable,
    setup = setup,
}

return M
