local log = require("fzfx.log")
local path = require("fzfx.path")
local conf = require("fzfx.config")
local Popup = require("fzfx.popup").Popup
local Launch = require("fzfx.launch").Launch
local shell = require("fzfx.shell")
local helpers = require("fzfx.helpers")
local yank_history = require("fzfx.yank_history")

--- @return string
local function short_path()
    local cwd_path = vim.fn.fnamemodify(vim.fn.getcwd(), ":~:.")
    local shorten_path = vim.fn.pathshorten(cwd_path)
    return shorten_path
end

--- @param query string
--- @param bang boolean
--- @param opts Config?
--- @return Launch
local function git_files(query, bang, opts)
    local git_files_configs = conf.get_config().git_files

    -- query command, both initial query + reload query
    local provider_command = git_files_configs.providers.git_ls_files
    local temp = vim.fn.tempname()
    vim.fn.writefile({ provider_command }, temp, "b")
    local query_command = string.format(
        "%s %s",
        shell.make_lua_command("git_files", "provider.lua"),
        temp
    )
    local preview_command =
        string.format("%s {}", shell.make_lua_command("files", "previewer.lua"))
    log.debug(
        "|fzfx.git_files - git_files| query_command:%s, preview_command:%s",
        vim.inspect(query_command),
        vim.inspect(preview_command)
    )

    local fzf_opts = {
        { "--query", query },
        {
            "--prompt",
            short_path() .. " > ",
        },
        {
            "--preview",
            preview_command,
        },
    }
    fzf_opts =
        vim.list_extend(fzf_opts, vim.deepcopy(git_files_configs.fzf_opts))
    local actions = git_files_configs.actions.expect
    local ppp =
        Popup:new(bang and { height = 1, width = 1, row = 0, col = 0 } or nil)
    local launch = Launch:new(ppp, query_command, fzf_opts, actions)

    return launch
end

local function setup()
    local git_files_configs = conf.get_config().git_files
    log.debug(
        "|fzfx.git_files - setup| base_dir:%s, git_files_configs:%s",
        vim.inspect(path.base_dir()),
        vim.inspect(git_files_configs)
    )
    if not git_files_configs then
        return
    end

    -- User commands
    for _, command_configs in pairs(git_files_configs.commands.normal) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            log.debug(
                "|fzfx.git_files - setup| command:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(opts)
            )
            return git_files(opts.args, opts.bang)
        end, command_configs.opts)
    end
    for _, command_configs in pairs(git_files_configs.commands.visual) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            local selected = helpers.visual_select()
            log.debug(
                "|fzfx.git_files - setup| command:%s, selected:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(selected),
                vim.inspect(opts)
            )
            return git_files(selected, opts.bang)
        end, command_configs.opts)
    end
    for _, command_configs in pairs(git_files_configs.commands.cword) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            local word = vim.fn.expand("<cword>")
            log.debug(
                "|fzfx.git_files - setup| command:%s, word:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(word),
                vim.inspect(opts)
            )
            return git_files(word, opts.bang)
        end, command_configs.opts)
    end
    for _, command_configs in pairs(git_files_configs.commands.put) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            local yank = yank_history.get_yank()
            log.debug(
                "|fzfx.git_files - setup| command:%s, yank:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(yank),
                vim.inspect(opts)
            )
            return git_files(
                (yank ~= nil and type(yank.regtext) == "string")
                        and yank.regtext
                    or "",
                opts.bang
            )
        end, command_configs.opts)
    end
end

local M = {
    setup = setup,
}

return M
