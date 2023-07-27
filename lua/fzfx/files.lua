local log = require("fzfx.log")

--- @param query string
--- @param fullscreen boolean|integer
--- @param opts Option
local function files(query, fullscreen, opts)
    local provider = opts.unrestricted and opts.provider.unrestricted
        or opts.provider.restricted
    local initial_command = provider .. " || true"
    local spec = {
        source = initial_command,
        options = {
            "--ansi",
            "--query",
            query ~= nil and query or "",
        },
    }
    spec = vim.fn["fzf#vim#with_preview"](spec)
    log.debug("|fzfx.files - files| spec:%s", vim.inspect(spec))
    return vim.fn["fzf#vim#files"]("", spec, fullscreen)
end

local function setup(files_configs)
    log.debug(
        "|fzfx.files - setup| files_configs:%s",
        vim.inspect(files_configs)
    )
    local restricted_opts = vim.tbl_deep_extend(
        "force",
        vim.deepcopy(files_configs),
        { unrestricted = false }
    )
    local unrestricted_opts = vim.tbl_deep_extend(
        "force",
        vim.deepcopy(files_configs),
        { unrestricted = true }
    )

    -- user commands opts
    local user_command_opts = {
        normal = {
            bang = true,
            nargs = "?",
            complete = "dir",
        },
        unrestricted = {
            bang = true,
            nargs = "?",
            complete = "dir",
        },
        visual = {
            bang = true,
            range = true,
        },
        unrestricted_visual = {
            bang = true,
            range = true,
        },
        cword = {
            bang = true,
        },
        unrestricted_cword = {
            bang = true,
        },
    }

    for key, val in pairs(files_configs.command) do
        local command_opts = user_command_opts[key]
        local files_opts = string.find(key, "unrestricted") ~= nil
                and unrestricted_opts
            or restricted_opts
        log.debug(
            "|fzfx.files - setup| key:%s, val:%s, command_opts:%s, files_opts:%s",
            vim.inspect(key),
            vim.inspect(val),
            vim.inspect(command_opts),
            vim.inspect(files_opts)
        )
        vim.api.nvim_create_user_command(
            val.name,
            --- @param opts Option
            function(opts)
                log.debug(
                    "|fzfx.files - setup| %s opts:%s",
                    key,
                    vim.inspect(opts)
                )
                return files(opts.args, opts.bang, files_opts)
            end,
            command_opts
        )
    end
end

local M = {
    files = files,
    setup = setup,
}

return M
