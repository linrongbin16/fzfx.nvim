local log = require("fzfx.log")
local LogLevels = require("fzfx.log").LogLevels
local conf = require("fzfx.config")
local general = require("fzfx.general")
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum

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
            provider_opts.provider = function(query, context)
                local cmd = require("fzfx.cmd")
                local git_root_cmd = cmd.GitRootCmd:run()
                if git_root_cmd:wrong() then
                    log.echo(LogLevels.INFO, "not in git repo.")
                    return nil
                end
                local git_current_branch_cmd = cmd.GitCurrentBranchCmd:run()
                if git_current_branch_cmd:wrong() then
                    log.echo(
                        LogLevels.WARN,
                        table.concat(git_current_branch_cmd.result.stderr, " ")
                    )
                    return nil
                end
                local branch_results = {}
                table.insert(
                    branch_results,
                    string.format("* %s", git_current_branch_cmd:value())
                )
                local git_branch_cmd = cmd.Cmd:run(provider_opts[2])
                if git_branch_cmd.result:wrong() then
                    log.echo(
                        LogLevels.WARN,
                        table.concat(git_current_branch_cmd.result.stderr, " ")
                    )
                    return nil
                end
                for _, line in ipairs(git_branch_cmd.result.stdout) do
                    if vim.trim(line):sub(1, 1) ~= "*" then
                        table.insert(
                            branch_results,
                            string.format("  %s", vim.trim(line))
                        )
                    end
                end

                return branch_results
            end
            provider_opts.provider_type = ProviderTypeEnum.LIST
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
        require("fzfx.deprecated").notify(
            "deprecated 'FzfxGBranches' configs, please migrate to new config schema!"
        )
    end
end

local M = {
    setup = setup,
}

return M
