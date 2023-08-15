local log = require("fzfx.log")

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

--- @param options Config
local function setup(options)
    -- debug
    vim.env._FZFX_NVIM_DEBUG_ENABLE = options.debug.enable and 1 or 0

    -- icon
    if options.icon.enable then
        local devicon_path =
            search_module_path("nvim-web-devicons", "nvim%-web%-devicons")
        log.debug("|fzfx.env - setup| devicon path:%s", devicon_path)
        if type(devicon_path) ~= "string" or string.len(devicon_path) == 0 then
            log.warn(
                "error! you have configured 'icon.enable=true' while cannot find 'nvim-web-devicons' plugin!"
            )
        else
            vim.env._FZFX_NVIM_DEVICON_PATH = devicon_path
            vim.env._FZFX_NVIM_UNKNOWN_FILE_ICON = options.icon.unknown_file
            vim.env._FZFX_NVIM_DIRECTORY_ICON = options.icon.directory
            vim.env._FZFX_NVIM_DIRECTORY_OPEN_ICON = options.icon.directory_open
        end
    end

    -- self
    local self_path = search_module_path("fzfx", "fzfx%.nvim")
    log.debug("|fzfx.env - setup| self path:%s", self_path)
    log.ensure(
        type(self_path) == "string" and string.len(self_path) > 0,
        "|fzfx.env - setup| error! failed to find 'fzfx' plugin!"
    )
    vim.env._FZFX_NVIM_SELF_PATH = self_path
end

local M = {
    setup = setup,
}

return M
