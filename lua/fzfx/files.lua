local log = require("fzfx.log")
local utils = require("fzfx.utils")
local path = require("fzfx.path")

--- @type table<string, string|nil>
local Runtime = {
    --- @type string|nil
    header = nil,
    --- @type string|nil
    provider = nil,
}

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
    local u_query = path.tempname()
    local r_query = path.tempname()

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
                "%s:unbind(%s)+rebind(%s)+reload(%s || true)+transform-query(echo {q}>%s && cat %s)",
                u_action,
                u_action,
                r_action,
                u_provider,
                r_query,
                u_query
            ),
            "--bind",
            -- unrestricted mode: press ctrl-r, rebind ctrl-u
            string.format(
                "%s:unbind(%s)+rebind(%s)+reload(%s || true)+transform-query(echo {q}>%s && cat %s)",
                r_action,
                r_action,
                u_action,
                r_provider,
                u_query,
                r_query
            ),
            "--header",
            header,
        },
    }
    spec = vim.fn["fzf#vim#with_preview"](spec)
    log.debug("|fzfx.files - files| spec:%s", vim.inspect(spec))
    return vim.fn["fzf#vim#files"]("", spec, fullscreen)
end

--- @param files_configs Config
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
    local cword_command_opts = {
        bang = true,
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
        local visual_select = utils.visual_select()
        log.debug(
            "|fzfx.files - setup| visual command select:%s, opts:%s",
            vim.inspect(visual_select),
            vim.inspect(opts)
        )
        return files(visual_select, opts.bang, restricted_opts)
    end, visual_command_opts)
    -- FzfxFilesUV
    utils.define_command(
        files_configs.command.unrestricted_visual,
        function(opts)
            local visual_select = utils.visual_select()
            log.debug(
                "|fzfx.files - setup| visual command select:%s, opts:%s",
                vim.inspect(visual_select),
                vim.inspect(opts)
            )
            return files(visual_select, opts.bang, unrestricted_opts)
        end,
        visual_command_opts
    )
    -- FzfxFilesW
    utils.define_command(files_configs.command.cword, function(opts)
        local word = vim.fn.expand("<cword>")
        log.debug(
            "|fzfx.files - setup| cword command word:%s, opts:%s",
            vim.inspect(word),
            vim.inspect(opts)
        )
        return files(word, opts.bang, restricted_opts)
    end, cword_command_opts)
    -- FzfxFilesUW
    utils.define_command(
        files_configs.command.unrestricted_cword,
        function(opts)
            local word = vim.fn.expand("<cword>")
            log.debug(
                "|fzfx.files - setup| cword command word:%s, opts:%s",
                vim.inspect(word),
                vim.inspect(opts)
            )
            return files(word, opts.bang, unrestricted_opts)
        end,
        cword_command_opts
    )
end

local M = {
    files = files,
    setup = setup,
}

return M
