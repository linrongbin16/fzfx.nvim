local log = require("fzfx.log")
local LogLevel = require("fzfx.log").LogLevel
local conf = require("fzfx.config")
local utils = require("fzfx.utils")
local general = require("fzfx.general")
local ProviderConfig = require("fzfx.schema").ProviderConfig
local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local ProviderLineTypeEnum = require("fzfx.schema").ProviderLineTypeEnum

--- @param content string
--- @return string[]
local function parse_query(content)
    local flag = "--"
    local flag_pos = nil
    local query = ""
    local option = nil

    for i = 1, #content do
        if i + 1 <= #content and string.sub(content, i, i + 1) == flag then
            flag_pos = i
            break
        end
    end

    if flag_pos ~= nil and flag_pos > 0 then
        query = vim.trim(string.sub(content, 1, flag_pos - 1))
        option = vim.trim(string.sub(content, flag_pos + 2))
    else
        query = vim.trim(content)
    end

    return { query, option }
end

local function setup()
    local live_grep_configs = conf.get_config().live_grep
    if not live_grep_configs then
        return
    end

    local deprecated = false
    for provider_name, provider_opts in pairs(live_grep_configs.providers) do
        log.debug(
            "|fzfx.live_grep - setup| provider_name:%s, provider_opts:%s",
            vim.inspect(provider_name),
            vim.inspect(provider_opts)
        )
        if provider_name == "restricted" or provider_name == "unrestricted" then
            local action_key = provider_opts[1]
            local grep_cmd = provider_opts[2]
            live_grep_configs["restricted_mode"] = ProviderConfig:make({
                key = action_key,
                provider = function(query)
                    local parsed_query = parse_query(query or "")
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
                LogLevel.WARN,
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
