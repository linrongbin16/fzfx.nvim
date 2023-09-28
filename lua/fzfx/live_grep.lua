local log = require("fzfx.log")
local LogLevels = require("fzfx.log").LogLevels
local conf = require("fzfx.config")
local utils = require("fzfx.utils")
local general = require("fzfx.general")
local ProviderConfig = require("fzfx.schema").ProviderConfig
local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local ProviderLineTypeEnum = require("fzfx.schema").ProviderLineTypeEnum

local function setup()
    local live_grep_configs = conf.get_config().live_grep
    if not live_grep_configs then
        return
    end

    local deprecated = false
    local new_providers = {}
    for provider_name, provider_opts in pairs(live_grep_configs.providers) do
        log.debug(
            "|fzfx.live_grep - setup| provider_name:%s, provider_opts:%s",
            vim.inspect(provider_name),
            vim.inspect(provider_opts)
        )
        if provider_name == "restricted" or provider_name == "unrestricted" then
            local action_key = provider_opts[1]
            local grep_cmd = provider_opts[2]
            new_providers[provider_name .. "_mode"] = ProviderConfig:make({
                key = action_key,
                provider = function(query)
                    local parsed_query = utils.parse_flag_query(query or "")
                    local content = parsed_query[1]
                    local option = parsed_query[2]
                    if type(option) == "string" and string.len(option) > 0 then
                        return string.format(
                            "%s %s -- %s",
                            grep_cmd,
                            option,
                            utils.shellescape(content)
                        )
                    else
                        return string.format(
                            "%s -- %s",
                            grep_cmd,
                            utils.shellescape(content)
                        )
                    end
                end,
                provider_type = ProviderTypeEnum.COMMAND,
                line_type = ProviderLineTypeEnum.FILE,
                line_delimiter = ":",
                line_pos = 1,
            })
            deprecated = true
        end
    end
    if not vim.tbl_isempty(new_providers) then
        live_grep_configs.providers = new_providers
    end
    if deprecated then
        for _, command_opts in ipairs(live_grep_configs.commands) do
            command_opts.default_provider = command_opts.default_provider
                .. "_mode"
        end
    end
    general.setup("live_grep", live_grep_configs)
    if deprecated then
        local function deprecated_notification()
            log.echo(
                LogLevels.WARN,
                "deprecated 'FzfxLiveGrep' configs, please migrate to latest config schema!"
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
