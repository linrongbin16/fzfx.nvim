local log = require("fzfx.log")
local conf = require("fzfx.config")
local Popup = require("fzfx.popup").Popup
local shell = require("fzfx.shell")
local helpers = require("fzfx.helpers")
local utils = require("fzfx.utils")

--- @param query string
--- @param bang boolean
--- @param opts Configs?
--- @return Popup
local function git_blame(query, bang, opts)
    local git_blame_configs = conf.get_config().git_blame

    local current_bufnr = vim.api.nvim_get_current_buf()
    local current_bufname = vim.api.nvim_buf_get_name(current_bufnr)
    if not utils.is_buf_valid(current_bufnr) then
        log.throw(
            "error! invalid current buffer (%s): %s",
            current_bufnr,
            vim.inspect(current_bufname)
        )
    end

    -- query command, both initial query + reload query
    local git_blame_command =
        string.format("%s %s", git_blame_configs.providers, current_bufname)
    local git_blame_temp = vim.fn.tempname()
    vim.fn.writefile({ git_blame_command }, git_blame_temp, "b")
    local query_command = string.format(
        "%s %s",
        shell.make_lua_command("git_blame", "provider.lua"),
        git_blame_temp
    )
    local git_show_command = git_blame_configs.previewers
    local git_show_temp = vim.fn.tempname()
    vim.fn.writefile({ git_show_command }, git_show_temp, "b")
    local preview_command = string.format(
        "%s %s {}",
        shell.make_lua_command("git_commits", "previewer.lua"),
        git_show_temp
    )
    log.debug(
        "|fzfx.git_blame - git_blame| query_command:%s, preview_command:%s",
        vim.inspect(query_command),
        vim.inspect(preview_command)
    )

    local fzf_opts = {
        { "--query", query },
        {
            "--preview",
            preview_command,
        },
    }

    fzf_opts =
        vim.list_extend(fzf_opts, vim.deepcopy(git_blame_configs.fzf_opts))
    fzf_opts = helpers.preprocess_fzf_opts(fzf_opts)
    local actions = git_blame_configs.actions
    local p = Popup:new(
        bang and { height = 1, width = 1, row = 0, col = 0 } or nil,
        query_command,
        fzf_opts,
        actions
    )
    return p
end

local function setup()
    local git_blame_configs = conf.get_config().git_blame
    if not git_blame_configs then
        return
    end

    -- User commands
    for _, command_configs in pairs(git_blame_configs.commands) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            -- log.debug(
            --     "|fzfx.git_blame - setup| command:%s, opts:%s",
            --     vim.inspect(command_configs.name),
            --     vim.inspect(opts)
            -- )
            local query = helpers.get_command_feed(opts, command_configs.feed)
            return git_blame(query, opts.bang)
        end, command_configs.opts)
    end
end

local M = {
    setup = setup,
}

return M
