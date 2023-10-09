local log = require("fzfx.log")
local conf = require("fzfx.config")
local general = require("fzfx.general")
local ProviderConfig = require("fzfx.schema").ProviderConfig
local ProviderLineTypeEnum = require("fzfx.schema").ProviderLineTypeEnum

local function setup()
    local files_configs = conf.get_config().files
    if not files_configs then
        return
    end

    local deprecated = false
    local new_providers = {}
    for provider_name, provider_opts in pairs(files_configs.providers) do
        log.debug(
            "|fzfx.files - setup| provider_name:%s, provider_opts:%s",
            vim.inspect(provider_name),
            vim.inspect(provider_opts)
        )
        if provider_name == "restricted" or provider_name == "unrestricted" then
            local action_key = provider_opts[1]
            local grep_cmd = provider_opts[2]
            new_providers[provider_name .. "_mode"] = ProviderConfig:make({
                key = action_key,
                provider = grep_cmd,
                line_type = ProviderLineTypeEnum.FILE,
            })
            deprecated = true
        end
    end
    if not vim.tbl_isempty(new_providers) then
        files_configs.providers = new_providers
    end
    if deprecated then
        for _, command_opts in ipairs(files_configs.commands) do
            command_opts.default_provider = command_opts.default_provider
                .. "_mode"
        end
    end
    general.setup("files", files_configs)
    if deprecated then
        require("fzfx.deprecated").notify(
            "deprecated 'FzfxFiles' configs, please migrate to new config schema!"
        )
    end
end

local M = {
    setup = setup,
}

return M
