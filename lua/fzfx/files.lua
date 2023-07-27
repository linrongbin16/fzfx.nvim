local log = require("fzfx.log")
local infra = require("fzfx.infra")

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
        visual = {
            bang = true,
            range = true,
        },
        cword = {
            bang = true,
        },
    }

    -- FzfxFiles
    vim.api.nvim_create_user_command(
        files_configs.command.normal.name,
        --- @param opts Option
        function(opts)
            log.debug(
                "|fzfx.files - setup| normal command opts:%s",
                vim.inspect(opts)
            )
            return files(opts.args, opts.bang, restricted_opts)
        end,
        user_command_opts.normal
    )
    -- FzfxFilesU
    vim.api.nvim_create_user_command(
        files_configs.command.unrestricted.name,
        --- @param opts Option
        function(opts)
            log.debug(
                "|fzfx.files - setup| unrestricted command opts:%s",
                vim.inspect(opts)
            )
            return files(opts.args, opts.bang, unrestricted_opts)
        end,
        user_command_opts.normal
    )
    -- FzfxFilesV
    vim.api.nvim_create_user_command(
        files_configs.command.visual.name,
        --- @param opts Option
        function(opts)
            local visual_select = infra.visual_selected()
            log.debug(
                "|fzfx.files - setup| visual command select:%s, opts:%s",
                vim.insecpt(visual_select),
                vim.inspect(opts)
            )
            return files(visual_select, opts.bang, restricted_opts)
        end,
        user_command_opts.visual
    )
    -- FzfxFilesUV
    vim.api.nvim_create_user_command(
        files_configs.command.unrestricted_visual.name,
        --- @param opts Option
        function(opts)
            local visual_select = infra.visual_selected()
            log.debug(
                "|fzfx.files - setup| unrestricted visual command select:%s, opts:%s",
                vim.inspect(visual_select),
                vim.inspect(opts)
            )
            return files(visual_select, opts.bang, unrestricted_opts)
        end,
        user_command_opts.visual
    )
    -- FzfxFilesW
    vim.api.nvim_create_user_command(
        files_configs.command.cword.name,
        --- @param opts Option
        function(opts)
            local word = vim.fn.expand("<cword>")
            log.debug(
                "|fzfx.files - setup| cword command word:%s, opts:%s",
                vim.inspect(word),
                vim.inspect(opts)
            )
            return files(word, opts.bang, restricted_opts)
        end,
        user_command_opts.cword
    )
    -- FzfxFilesUV
    vim.api.nvim_create_user_command(
        files_configs.command.unrestricted_cword.name,
        --- @param opts Option
        function(opts)
            local word = vim.fn.expand("<cword>")
            log.debug(
                "|fzfx.files - setup| unrestricted cword command word:%s, opts:%s",
                vim.inspect(word),
                vim.inspect(opts)
            )
            return files(word, opts.bang, unrestricted_opts)
        end,
        user_command_opts.cword
    )
end

local M = {
    files = files,
    setup = setup,
}

return M
