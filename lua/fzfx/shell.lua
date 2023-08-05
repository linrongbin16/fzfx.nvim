local log = require("fzfx.log")
local path = require("fzfx.path")

local Context = {
    nvim_path = nil,
}

--- @return string
local function make_lua_command(...)
    if Context.nvim_path == nil then
        Context.nvim_path = vim.v.argv[1]
    end
    local nvim_path = Context.nvim_path

    local conf = require("fzfx.config")
    local nvim_path_conf = conf.get_config().env.nvim
    if nvim_path_conf ~= nil and string.len(nvim_path_conf) > 0 then
        nvim_path = nvim_path_conf
    end

    local lua_path = path.join(path.base_dir(), "bin", ...)
    log.debug(
        "|fzfx.shell - make_lua_command| lua_path:%s",
        vim.inspect(lua_path)
    )
    return string.format("%s -n --clean --headless -l %s", nvim_path, lua_path)
end

local M = {
    make_lua_command = make_lua_command,
}

return M
