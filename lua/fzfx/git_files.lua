local log = require("fzfx.log")
local LogLevels = require("fzfx.log").LogLevels
local conf = require("fzfx.config")
local ProviderConfig = require("fzfx.schema").ProviderConfig
local PreviewerConfig = require("fzfx.schema").PreviewerConfig
local ProviderLineTypeEnum = require("fzfx.schema").ProviderLineTypeEnum
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
        git_files_configs.providers = {
            ---@diagnostic disable-next-line: deprecated
            current_folder = ProviderConfig:make({
                key = "ctrl-u",
                provider = git_files_configs.providers,
                line_type = ProviderLineTypeEnum.FILE,
            }),
            ---@diagnostic disable-next-line: deprecated
            workspace = ProviderConfig:make({
                key = "ctrl-w",
                provider = git_files_configs.providers,
                line_type = ProviderLineTypeEnum.FILE,
            }),
        }
        deprecated = true
    end
    if git_files_configs.previewers == nil then
        git_files_configs["previewers"] = {
            current_folder = PreviewerConfig:make({
                previewer = function(line)
                    local filename = env.icon_enable() and vim.fn.split(line)[2]
                        or line
                    return string.format("cat %s", filename)
                end,
                previewer_type = PreviewerTypeEnum.COMMAND,
            }),
            workspace = PreviewerConfig:make({
                previewer = function(line)
                    local filename = env.icon_enable() and vim.fn.split(line)[2]
                        or line
                    return string.format("cat %s", filename)
                end,
                previewer_type = PreviewerTypeEnum.COMMAND,
            }),
        }
        deprecated = true
    end
    general.setup("git_files", git_files_configs)
    if deprecated then
        require("fzfx.deprecated").notify(
            "deprecated 'FzfxGFiles' configs, please migrate to new config schema!"
        )
    end
end

local M = {
    setup = setup,
}

return M
