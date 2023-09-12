local log = require("fzfx.log")
local LogLevel = require("fzfx.log").LogLevel
local conf = require("fzfx.config")
local ProviderConfig = require("fzfx.schema").ProviderConfig
local PreviewerConfig = require("fzfx.schema").PreviewerConfig
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local env = require("fzfx.env")
local general = require("fzfx.general")

local function setup()
    local git_files_configs = conf.get_config().git_files
    if not git_files_configs then
        return
    end

    local deprecated = false
    if
        type(git_files_configs.providers) == "string"
        ---@diagnostic disable-next-line: param-type-mismatch
        and string.len(git_files_configs.providers) > 0
    then
        git_files_configs.providers = ProviderConfig:make({
            key = "ctrl-u",
            provider = git_files_configs.providers,
        })
        deprecated = true
    end
    if type(git_files_configs.previewers) ~= "table" then
        git_files_configs.previewers = PreviewerConfig:make({
            previewer = function(line)
                local filename = env.icon_enable() and vim.fn.split(line)[2]
                    or line
                return string.format("cat %s", filename)
            end,
            previewer_type = PreviewerTypeEnum.COMMAND,
        })
        deprecated = true
    end
    general.setup("git_files", git_files_configs)
    if deprecated then
        local function deprecated_notification()
            log.echo(
                LogLevel.WARN,
                "deprecated 'FzfxGFiles' configs, please migrate to latest config schema!"
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
