local log = require("fzfx.log")
local conf = require("fzfx.config")
-- local Popup = require("fzfx.popup").Popup
-- local shell = require("fzfx.shell")
-- local helpers = require("fzfx.helpers")
-- local server = require("fzfx.server")
local utils = require("fzfx.utils")
local general = require("fzfx.general")
local PreviewerTypeEnum = require("fzfx.meta").PreviewerTypeEnum

-- local Context = {
--     --- @type string?
--     all_key = nil,
--     --- @type string?
--     buffer_key = nil,
--     --- @type string?
--     all_header = nil,
--     --- @type string?
--     buffer_header = nil,
-- }
--
-- --- @alias GitCommitsOptKey "default_provider"
-- --- @alias GitCommitsOptValue "all_commits"|"buffer_commits"
-- --- @alias GitCommitsOpts table<GitCommitsOptKey, GitCommitsOptValue>
--
-- --- @param query string
-- --- @param bang boolean
-- --- @param opts GitCommitsOpts
-- --- @return Popup
-- local function git_commits(query, bang, opts)
--     local git_commits_configs = conf.get_config().git_commits
--
--     local current_bufnr = vim.api.nvim_get_current_buf()
--     local current_bufname = vim.api.nvim_buf_get_name(current_bufnr)
--     local current_buf_valid = utils.is_buf_valid(current_bufnr)
--     if opts.default_provider == "buffer_commits" and not current_buf_valid then
--         log.throw(
--             "error! invalid current buffer (%s): %s",
--             current_bufnr,
--             vim.inspect(current_bufname)
--         )
--     end
--     local buffer_only_provider = utils.is_buf_valid(current_bufnr)
--             and string.format(
--                 "%s -- %s",
--                 git_commits_configs.providers.buffer_commits[2],
--                 current_bufname
--             )
--         or git_commits_configs.providers.all_commits[2]
--     log.debug(
--         "|fzfx.git_commits - git_commits| buffer_only_provider:%s, current_bufnr (valid:%s):%s, current_bufname:%s",
--         buffer_only_provider,
--         utils.is_buf_valid(current_bufnr),
--         current_bufnr,
--         current_bufname
--     )
--     local provider_switch = helpers.Switch:new(
--         "git_commits_provider",
--         opts.default_provider == "all_commits"
--                 and git_commits_configs.providers.all_commits[2]
--             or buffer_only_provider,
--         opts.default_provider == "all_commits" and buffer_only_provider
--             or git_commits_configs.providers.all_commits[2]
--     )
--
--     -- rpc callback
--     local function switch_provider_rpc_callback()
--         log.debug(
--             "|fzfx.git_commits - git_commits.switch_provider_rpc_callback|"
--         )
--         provider_switch:switch()
--     end
--     local switch_provider_rpc_callback_id =
--         server.get_global_rpc_server():register(switch_provider_rpc_callback)
--
--     -- query command, both initial query + reload query
--     local query_command = string.format(
--         "%s %s",
--         shell.make_lua_command("git_commits", "provider.lua"),
--         provider_switch.tempfile
--     )
--     local git_show_command = git_commits_configs.previewers
--     local temp = vim.fn.tempname()
--     vim.fn.writefile({ git_show_command }, temp, "b")
--     local preview_command = string.format(
--         "%s %s {}",
--         shell.make_lua_command("git_commits", "previewer.lua"),
--         temp
--     )
--     local call_switch_provider_rpc_command = string.format(
--         "%s %s",
--         shell.make_lua_command("rpc", "client.lua"),
--         switch_provider_rpc_callback_id
--     )
--     log.debug(
--         "|fzfx.git_commits - git_commits| query_command:%s, preview_command:%s, call_switch_provider_rpc_command:%s",
--         vim.inspect(query_command),
--         vim.inspect(preview_command),
--         vim.inspect(call_switch_provider_rpc_command)
--     )
--
--     local fzf_opts =
--         {
--             { "--query", query },
--             (opts.default_provider ~= "all_commits" or current_buf_valid) and {
--                 "--header",
--                 opts.default_provider == "all_commits"
--                         and Context.buffer_header
--                     or Context.all_header,
--             } or nil,
--             {
--                 "--bind",
--                 string.format(
--                     "start:unbind(%s)",
--                     opts.default_provider == "all_commits" and Context.all_key
--                         or Context.buffer_key
--                 ),
--             },
--             current_buf_valid
--                     and {
--                         -- buffer key: swap provider, change rmode header, rebind rmode action, reload query
--                         "--bind",
--                         string.format(
--                             "%s:unbind(%s)+execute-silent(%s)+change-header(%s)+rebind(%s)+reload(%s)",
--                             Context.buffer_key,
--                             Context.buffer_key,
--                             call_switch_provider_rpc_command,
--                             Context.all_header,
--                             Context.all_key,
--                             query_command
--                         ),
--                     }
--                 or nil,
--             {
--                 -- all key: swap provider, change umode header, rebind umode action, reload query
--                 "--bind",
--                 string.format(
--                     "%s:unbind(%s)+execute-silent(%s)+change-header(%s)+rebind(%s)+reload(%s)",
--                     Context.all_key,
--                     Context.all_key,
--                     call_switch_provider_rpc_command,
--                     Context.buffer_header,
--                     Context.buffer_key,
--                     query_command
--                 ),
--             },
--             {
--                 "--preview",
--                 preview_command,
--             },
--         }
--
--     fzf_opts =
--         vim.list_extend(fzf_opts, vim.deepcopy(git_commits_configs.fzf_opts))
--     fzf_opts = helpers.preprocess_fzf_opts(fzf_opts)
--     local actions = git_commits_configs.actions
--     local p = Popup:new(
--         bang and { height = 1, width = 1, row = 0, col = 0 } or nil,
--         query_command,
--         fzf_opts,
--         actions
--     )
--     return p
-- end

local function setup()
    local git_commits_configs = conf.get_config().git_commits
    if not git_commits_configs then
        return
    end

    for provider_name, provider_opts in pairs(git_commits_configs.providers) do
        if
            #provider_opts >= 2
            or type(provider_opts[1]) == "string"
            or type(provider_opts[2]) == "string"
        then
            log.warn(
                "warning! deprecated 'FzfxGCommits' configs, please migrate to latest config schema!"
            )
            --- @type ActionKey
            provider_opts.key = provider_opts[1]
            if provider_name == "buffer_commits" then
                --- @param query string?
                --- @param context PipelineContext?
                --- @return string
                local function buffer_provider(query, context)
                    assert(
                        context,
                        "|fzfx.git_commits - setup| error! 'FzfxGCommits' commands cannot have nil pipeline context!"
                    )
                    if not utils.is_buf_valid(context.bufnr) then
                        error(
                            string.format(
                                "error! 'FzfxGCommits' commands (buffer only) cannot run on an invalid buffer (%s)!",
                                vim.inspect(context.bufnr)
                            )
                        )
                    end
                    return string.format(
                        "%s -- %s",
                        provider_opts[2],
                        vim.api.nvim_buf_get_name(context.bufnr)
                    )
                end
                --- @type CommandProvider
                provider_opts.provider = buffer_provider
            else
                --- @type PlainProvider
                provider_opts.provider = provider_opts[2]
            end
        end
    end
    if type(git_commits_configs.previewers) == "string" then
        log.warn(
            "warning! deprecated 'FzfxGCommits' configs, please migrate to latest config schema!"
        )
        local old_previewer = git_commits_configs.previewers
        git_commits_configs.previewers = {}
        for provider_name, _ in pairs(git_commits_configs.providers) do
            git_commits_configs.previewers[provider_name] = {
                previewer = function(line)
                    local commit = vim.fn.split(line)[1]
                    return string.format("%s %s", old_previewer, commit)
                end,
                previewer_type = PreviewerTypeEnum.COMMAND,
            }
        end
    end

    general.setup("git_commits", git_commits_configs)
end

local M = {
    setup = setup,
}

return M
