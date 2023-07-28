local log = require("fzfx.log")
local utils = require("fzfx.utils")
local path = require("fzfx.path")

--- @type table<string, string|nil>
local Runtime = {
    --- @type string|nil
    current_header = nil,
    --- @type string|nil
    next_header = nil,
    --- @type string|nil
    swap_header = nil,
    --- @type string|nil
    current_provider = nil,
    --- @type string|nil
    next_provider = nil,
    --- @type string|nil
    swap_provider = nil,
}

--- @param query string
--- @param fullscreen boolean|integer
--- @param opts Config
local function files(query, fullscreen, opts)
    local switch_action = string.lower(opts.action.unrestricted_switch)

    -- header
    vim.fn.writefile({
        string.format(
            ":: Press %s to unrestricted mode",
            string.upper(switch_action)
        ),
    }, opts.unrestricted and Runtime.current_header or Runtime.next_header)
    vim.fn.writefile({
        string.format(
            ":: Press %s to restricted mode",
            string.upper(switch_action)
        ),
    }, opts.unrestricted and Runtime.next_header or Runtime.current_header)

    -- provider
    vim.fn.writefile(
        { opts.provider.unrestricted },
        opts.unrestricted and Runtime.current_provider or Runtime.next_provider
    )
    vim.fn.writefile(
        { opts.provider.restricted },
        opts.unrestricted and Runtime.next_provider or Runtime.current_provider
    )

    -- query command, both initial query + reload query
    local query_command = string.format(
        "nvim %s --headless -l %s%sfiles_provider.lua || true",
        opts.debug and "-V1" or "",
        path.plugin_bin(),
        path.separator()
    )
    log.debug(
        "|fzfx.files - files| query_command:%s",
        vim.inspect(query_command)
    )

    local spec = {
        source = query_command,
        options = {
            "--ansi",
            "--query",
            query,
            "--bind",
            -- unrestricted switch action: swap header, swap provider, then change header + reload
            string.format(
                "%s:unbind(%s)+execute-silent(mv %s %s && mv %s %s && mv %s %s)+execute-silent(mv %s %s && mv %s %s && mv %s %s)+rebind(%s)+transform-header(cat %s)+reload(%s)",
                switch_action,
                switch_action,
                Runtime.current_header,
                Runtime.swap_header,
                Runtime.next_header,
                Runtime.current_header,
                Runtime.swap_header,
                Runtime.next_header,
                Runtime.current_provider,
                Runtime.swap_provider,
                Runtime.next_provider,
                Runtime.current_provider,
                Runtime.swap_provider,
                Runtime.next_provider,
                switch_action,
                Runtime.current_header,
                query_command
            ),
            "--header",
            opts.unrestricted and string.format(
                ":: Press %s to restricted mode",
                string.upper(switch_action)
            ) or string.format(
                ":: Press %s to unrestricted mode",
                string.upper(switch_action)
            ),
        },
    }
    spec = vim.fn["fzf#vim#with_preview"](spec)
    log.debug("|fzfx.files - files| spec:%s", vim.inspect(spec))
    return vim.fn["fzf#vim#files"]("", spec, fullscreen)
end

--- @param files_configs Config
local function setup(files_configs)
    log.debug(
        "|fzfx.files - setup| plugin_bin:%s, files_configs:%s",
        vim.inspect(path.plugin_bin()),
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

    -- runtime
    if files_configs.debug then
        Runtime.current_header = string.format(
            "%s/fzfx.nvim/files_current_header",
            vim.fn.stdpath("data")
        )
        Runtime.next_header = string.format(
            "%s/fzfx.nvim/files_next_header",
            vim.fn.stdpath("data")
        )
        Runtime.swap_header = string.format(
            "%s/fzfx.nvim/files_swap_header",
            vim.fn.stdpath("data")
        )
        Runtime.current_provider = string.format(
            "%s/fzfx.nvim/files_current_provider",
            vim.fn.stdpath("data")
        )
        Runtime.next_provider = string.format(
            "%s/fzfx.nvim/files_next_provider",
            vim.fn.stdpath("data")
        )
        Runtime.swap_provider = string.format(
            "%s/fzfx.nvim/files_swap_provider",
            vim.fn.stdpath("data")
        )
    else
        Runtime.current_header = path.tempname()
        Runtime.next_header = path.tempname()
        Runtime.swap_header = path.tempname()
        Runtime.current_provider = path.tempname()
        Runtime.next_provider = path.tempname()
        Runtime.swap_provider = path.tempname()
    end
    vim.env._FZFX_FILES_PROVIDER = Runtime.current_provider
    log.debug("|fzfx.files - setup| Runtime:%s", vim.inspect(Runtime))
end

local M = {
    files = files,
    setup = setup,
}

return M
