local log = require("fzfx.log")
local infra = require("fzfx.infra")
local utils = require("fzfx.utils")
local fs = require("fzfx.fs")

--- @param query string
--- @param fullscreen boolean|integer
--- @param opts Config
local function files(query, fullscreen, opts)
    local u_action = string.lower(opts.action.unrestricted)
    local r_action = string.lower(opts.action.restricted)
    local u_provider = opts.provider.unrestricted
    local r_provider = opts.provider.restricted
    local provider = opts.unrestricted and u_provider or r_provider
    local initial_command = provider .. " || true"
    local header = string.format(
        ":: Press %s to unrestricted mode, %s to restricted mode",
        string.upper(u_action),
        string.upper(r_action)
    )
    -- local u_query = fs.tempfilename()
    -- local r_query = fs.tempfilename()

    local spec = {
        source = initial_command,
        options = {
            "--ansi",
            "--query",
            query,
            "--bind",
            string.format(
                "start:unbind(%s)",
                opts.unrestricted and u_action or r_action
            ),
            "--bind",
            -- restricted mode: press ctrl-u, rebind ctrl-r
            string.format(
                "%s:unbind(%s)+rebind(%s)+reload(%s || true)",
                u_action,
                u_action,
                r_action,
                u_provider
            ),
            "--bind",
            -- unrestricted mode: press ctrl-r, rebind ctrl-u
            string.format(
                "%s:unbind(%s)+rebind(%s)+reload(%s || true)",
                r_action,
                r_action,
                u_action,
                r_provider
            ),
            "--header",
            header,
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
    local normal_command_opts = {
        bang = true,
        nargs = "?",
        complete = "dir",
    }
    local visual_command_opts = {
        bang = true,
        range = true,
    }

    -- FzfxFiles
    utils.define_command(files_configs.command.normal, function(opts)
        log.debug(
            "|fzfx.files - setup| normal command opts:%s",
            vim.inspect(opts)
        )
        return files(opts.args, opts.bang, restricted_opts)
    end, normal_command_opts)
    -- FzfxFilesU
    utils.define_command(files_configs.command.unrestricted, function(opts)
        log.debug(
            "|fzfx.files - setup| unrestricted command opts:%s",
            vim.inspect(opts)
        )
        return files(opts.args, opts.bang, unrestricted_opts)
    end, normal_command_opts)
    -- FzfxFilesV
    utils.define_command(files_configs.command.visual, function(opts)
        local visual_select = infra.visual_selected()
        log.debug(
            "|fzfx.files - setup| visual command select:%s, opts:%s",
            vim.insecpt(visual_select),
            vim.inspect(opts)
        )
        return files(visual_select, opts.bang, restricted_opts)
    end, visual_command_opts)
    -- FzfxFilesUV
    utils.define_command(
        files_configs.command.unrestricted_visual,
        function(opts)
            local visual_select = infra.visual_selected()
            log.debug(
                "|fzfx.files - setup| visual command select:%s, opts:%s",
                vim.insecpt(visual_select),
                vim.inspect(opts)
            )
            return files(visual_select, opts.bang, unrestricted_opts)
        end,
        visual_command_opts
    )
end

local M = {
    files = files,
    setup = setup,
}

return M
