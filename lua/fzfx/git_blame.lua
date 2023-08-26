local function setup()
    local conf = require("fzfx.config")
    local general = require("fzfx.general")

    general.setup(conf.get_config().git_blame)
end

local M = {
    setup = setup,
}

return M
