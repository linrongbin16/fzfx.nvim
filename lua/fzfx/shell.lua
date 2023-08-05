local log = require("fzfx.log")
local path = require("fzfx.path")
local conf = require("fzfx.config")

local Context = {
    --- @type string|nil
    nvim_path = nil,
    --- @type string|nil
    fzf_path = nil,
}

--- @return string|nil
local function nvim_exec()
    local exe_list = {}
    table.insert(exe_list, conf.get_config().env.nvim)
    table.insert(exe_list, vim.v.argv[1])
    table.insert(exe_list, vim.env.VIM)
    table.insert(exe_list, "nvim")
    for _, e in exe_list do
        if e ~= nil and vim.fn.executable(e) > 0 then
            return e
        end
    end
    log.throw("error! failed to found executable 'nvim' on path!")
    return nil
end

--- @return string|nil
local function fzf_exec()
    local exe_list = {}
    table.insert(exe_list, conf.get_config().env.fzf)
    table.insert(exe_list, vim.fn["fzf#fzf_exec"]())
    table.insert(exe_list, "fzf")
    for _, e in exe_list do
        if e ~= nil and vim.fn.executable(e) > 0 then
            return e
        end
    end
    log.throw("error! failed to found executable 'nvim' on path!")
    return nil
end

--- @return string
local function make_lua_command(...)
    local nvim_path = nvim_exec()
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
