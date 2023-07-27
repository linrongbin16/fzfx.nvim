local log = require("fzfx.log")

--- @param query string
--- @param fullscreen boolean|integer
--- @param opts Option
local function files(query, fullscreen, opts)
    local source = opts.unrestricted and opts.command.unrestricted
        or opts.command.restricted
    local initial_command = source .. " || true"
    local spec = {
        source = initial_command,
        options = {
            "--ansi",
            "--query",
            query ~= nil and query or "",
        },
    }
    spec = vim.fn["fzf#vim#with_preview"](spec)
    log.debug("|fzfx.files.files| spec:%s", vim.inspect(spec))
    return vim.fn["fzf#vim#files"]("", spec, fullscreen)
end

local function setup(configs)
    local restricted_opts =
        vim.tbl_deep_extend("force", configs.files, { unrestricted = false })

    vim.api.nvim_create_user_command(
        "FzfxFiles",
        --- @param opts Option
        function(opts)
            return files(opts.args, opts.bang, restricted_opts)
        end,
        {
            bang = true,
            nargs = "?",
            complete = "dir",
        }
    )
end

local M = {
    files = files,
    setup = setup,
}

return M
