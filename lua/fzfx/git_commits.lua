local log = require("fzfx.log")
local conf = require("fzfx.config")
local utils = require("fzfx.utils")
local general = require("fzfx.general")
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum

local function setup()
    local git_commits_configs = conf.get_config().git_commits
    if not git_commits_configs then
        return
    end

    local deprecated = false
    for provider_name, provider_opts in pairs(git_commits_configs.providers) do
        if
            #provider_opts >= 2
            or type(provider_opts[1]) == "string"
            or type(provider_opts[2]) == "string"
        then
            --- @type ActionKey
            provider_opts.key = provider_opts[1]
            if provider_name == "buffer_commits" then
                --- @param query string?
                --- @param context PipelineContext
                --- @return string?
                local function buffer_provider(query, context)
                    if not utils.is_buf_valid(context.bufnr) then
                        log.warn(
                            string.format(
                                "'FzfxGCommits' commands (buffer only) cannot run on an invalid buffer (%s)!",
                                vim.inspect(context.bufnr)
                            )
                        )
                        return nil
                    end
                    return string.format(
                        "%s -- %s",
                        provider_opts[2],
                        vim.api.nvim_buf_get_name(context.bufnr)
                    )
                end
                --- @type CommandProvider
                provider_opts.provider = buffer_provider
                provider_opts.provider_type = ProviderTypeEnum.COMMAND
            else
                --- @type PlainProvider
                provider_opts.provider = provider_opts[2]
                provider_opts.provider_type = ProviderTypeEnum.PLAIN
            end
            deprecated = true
        end
    end
    if type(git_commits_configs.previewers) == "string" then
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
        deprecated = true
    end
    general.setup("git_commits", git_commits_configs)
    if deprecated then
        local function deprecated_notification()
            log.warn(
                "deprecated 'FzfxGCommits' previewer configs, please migrate to latest config schema!"
            )
        end
        local delay = 3 * 1000
        vim.defer_fn(deprecated_notification, delay)
        vim.api.nvim_create_autocmd("VimEnter", {
            pattern = { "*" },
            callback = function()
                vim.defer_fn(deprecated_notification, delay)
            end,
        })
    end
end

local M = {
    setup = setup,
}

return M
