local conf = require("fzfx.config")
local log = require("fzfx.log")

--- @return string|nil
local function search_path()
    local devicon_ok, devicon = pcall(require, "nvim-web-devicons")
    if not devicon_ok then
        log.throw(
            "error! failed to load lua module 'nvim-web-devicons': %s",
            vim.inspect(devicon)
        )
        return nil
    end
    local rtp = type(vim.o.runtimepath) == "string"
            and vim.fn.split(vim.o.runtimepath, ",")
        or {}
    for i, path in ipairs(rtp) do
        log.debug("|fzfx.icon - search_path| path[%d]:%s", i, path)
        if
            type(path) == "string" and string.match(path, "nvim%-web%-devicons")
        then
            return path
        end
    end
    log.throw(
        "error! failed to find lua module 'nvim-web-devicons' on runtimepath: %s",
        vim.inspect(rtp)
    )
    return nil
end

local function setup()
    local icon_enable = conf.get_config().icon.enable or false
    log.debug(
        "|fzfx.icon - setup| icon enable:%s",
        vim.inspect(conf.get_config().icon.enable)
    )
    if not icon_enable then
        return
    end

    local devicon_path = search_path()
    log.debug("|fzfx.icon - devicon| package path:%s", devicon_path)
    vim.env._FZFX_NVIM_ICON_PATH = devicon_path
end

local M = {
    setup = setup,
}

return M
