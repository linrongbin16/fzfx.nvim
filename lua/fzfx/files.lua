local log = require("fzfx.log")
local utils = require("fzfx.utils")
local path = require("fzfx.path")
local legacy = require("fzfx.legacy")

--- @param query string
--- @param fullscreen boolean|integer
--- @param opts Config
local function files(query, fullscreen, opts)
    -- action
    local switch_action = string.lower(opts.action.unrestricted_switch)

    -- header
    local restricted_header = string.format(
        ":: Press %s to restricted search",
        legacy.magenta(string.upper(switch_action))
    )
    local unrestricted_header = string.format(
        ":: Press %s to unrestricted search",
        legacy.magenta(string.upper(switch_action))
    )

    --- @type table<string, SwapableFile>
    local runtime = {
        --- @type SwapableFile
        header = path.new_swapable_file(
            "files_header",
            { opts.unrestricted and restricted_header or unrestricted_header },
            { opts.unrestricted and unrestricted_header or restricted_header },
            opts.debug
        ),
        --- @type SwapableFile
        provider = path.new_swapable_file("files_provider", {
            opts.unrestricted and opts.provider.unrestricted
                or opts.provider.restricted,
        }, {
            opts.unrestricted and opts.provider.restricted
                or opts.provider.unrestricted,
        }, opts.debug),
    }
    log.debug("|fzfx.files - files| runtime:%s", vim.inspect(runtime))

    -- query command, both initial query + reload query
    local query_command = string.format(
        "nvim --headless -l %sfiles_provider.lua %s || true",
        path.plugin_bin(),
        runtime.provider.current
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
                "%s:unbind(%s)+execute-silent(%s)+execute-silent(%s)+rebind(%s)+transform-header(cat %s)+reload(%s)",
                switch_action,
                switch_action,
                runtime.header:swap_by_shell(),
                runtime.provider:swap_by_shell(),
                switch_action,
                runtime.header.current,
                query_command
            ),
            "--header",
            opts.unrestricted and restricted_header or unrestricted_header,
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
end

local M = {
    setup = setup,
}

return M
