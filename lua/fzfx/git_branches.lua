local log = require("fzfx.log")
local LogLevel = require("fzfx.log").LogLevel
local conf = require("fzfx.config")
local general = require("fzfx.general")
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum

local function setup()
    local git_branches_configs = conf.get_config().git_branches
    if not git_branches_configs then
        return
    end

    local deprecated = false
    for provider_name, provider_opts in pairs(git_branches_configs.providers) do
        if
            #provider_opts >= 2
            or type(provider_opts[1]) == "string"
            or type(provider_opts[2]) == "string"
        then
            --- @type ActionKey
            provider_opts.key = provider_opts[1]
            --- @type Provider
            provider_opts.provider = provider_opts[2]
            deprecated = true
        end
    end
    if type(git_branches_configs.previewers) == "string" then
        local old_previewer = git_branches_configs.previewers
        git_branches_configs.previewers = {}
        for provider_name, _ in pairs(git_branches_configs.providers) do
            git_branches_configs.previewers[provider_name] = {
                previewer = function(line)
                    local commit = vim.fn.split(line)[1]
                    return string.format("%s %s", old_previewer, commit)
                end,
                previewer_type = PreviewerTypeEnum.COMMAND,
            }
        end
        deprecated = true
    end
    general.setup("git_branches", git_branches_configs)
    if deprecated then
        local function deprecated_notification()
            log.echo(
                LogLevel.WARN,
                "deprecated 'FzfxGBranches' configs, please migrate to latest config schema!"
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
