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

--- @param configs Configs
local function setup(configs)
    -- debug
    vim.env._FZFX_NVIM_DEBUG_ENABLE = configs.debug.enable and 1 or 0

    -- icon
    if type(configs.icons) == "table" then
        local devicons_path =
            search_module_path("nvim-web-devicons", "nvim%-web%-devicons")
        log.debug("|fzfx.module - setup| devicons path:%s", devicons_path)
        if
            type(devicons_path) ~= "string"
            or string.len(devicons_path) == 0
        then
            log.warn(
                "error! you have configured 'icons' while cannot find 'nvim-web-devicons' plugin!"
            )
        else
            vim.env._FZFX_NVIM_DEVICONS_PATH = devicons_path
            vim.env._FZFX_NVIM_UNKNOWN_FILE_ICON = configs.icons.unknown_file
            vim.env._FZFX_NVIM_FILE_FOLDER_ICON = configs.icons.folder
            vim.env._FZFX_NVIM_FILE_FOLDER_OPEN_ICON = configs.icons.folder_open
        end
    end

    -- self
    local self_path = search_module_path("fzfx", "fzfx%.nvim")
    log.debug("|fzfx.module - setup| self path:%s", self_path)
    log.ensure(
        type(self_path) == "string" and string.len(self_path) > 0,
        "|fzfx.module - setup| error! failed to find 'fzfx.nvim' plugin!"
    )
    vim.env._FZFX_NVIM_SELF_PATH = self_path
end

local M = {
    setup = setup,
}

return M
