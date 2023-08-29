local log = require("fzfx.log")
local conf = require("fzfx.config")
local general = require("fzfx.general")
local InteractionConfig = require("fzfx.config").InteractionConfig

local function setup()
    local buffers_configs = conf.get_config().buffers
    if not buffers_configs then
        return
    end

    local deprecated = false
    -- interactions
    if
        type(buffers_configs.interactions) == "table"
        and #buffers_configs.interactions == 2
        and type(buffers_configs.interactions[1]) == "string"
        and type(buffers_configs.interactions[2]) == "function"
        and buffers_configs.interactions["delete_buffer"] == nil
    then
        buffers_configs.interactions.delete_buffer = InteractionConfig:make({
            key = buffers_configs.interactions[1],
            interaction = buffers_configs.interactions[2],
        })
        deprecated = true
    end
    -- other_opts
    if
        type(buffers_configs["other_opts"]) == "table"
        and type(buffers_configs["other_opts"]["exclude_filetypes"])
            == "table"
    then
        deprecated = true
    end

    general.setup("buffers", buffers_configs)
    if deprecated then
        log.info(
            "deprecated 'FzfxGCommits' previewer configs, please migrate to latest config schema!"
        )
    end
end

local M = {
    setup = setup,
}

return M
