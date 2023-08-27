local log = require("fzfx.log")
local conf = require("fzfx.config")
local utils = require("fzfx.utils")
local general = require("fzfx.general")
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum

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
