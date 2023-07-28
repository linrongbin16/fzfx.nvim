local log = require("fzfx.log")
local utils = require("fzfx.utils")
local path = require("fzfx.path")
local legacy = require("fzfx.legacy")

--- @param query string
--- @param fullscreen boolean|integer
--- @param opts Config
local function live_grep(query, fullscreen, opts)
    local unrestricted_switch_action =
        string.lower(opts.action.unrestricted_switch)
    local fuzzy_switch_action = string.lower(opts.action.fuzzy_switch)

    -- header
    local unrestricted_header = string.format(
        ":: Press %s to unrestricted search",
        legacy.magenta(string.upper(unrestricted_switch_action))
    )
    local restricted_header = string.format(
        ":: Press %s to restricted search",
        legacy.magenta(string.upper(unrestricted_switch_action))
    )
    local fuzzy_header = string.format(
        ", %s to fuzzy search",
        legacy.magenta(string.upper(fuzzy_switch_action))
    )
    local regex_header = string.format(
        ", %s to regex search",
        legacy.magenta(string.upper(fuzzy_switch_action))
    )

    local runtime = {
        --- @type SwapableFile
        unrestricted_header = path.new_swapable_file(
            "live_grep_unrestricted_header",
            {
                opts.unrestricted and restricted_header or unrestricted_header,
            },
            { opts.unrestricted and unrestricted_header or restricted_header },
            opts.debug
        ),
        --- @type SwapableFile
        fuzzy_header = path.new_swapable_file(
            "live_grep_fuzzy_header",
            { fuzzy_header },
            { regex_header },
            opts.debug
        ),
        --- @type SwapableFile
        provider = path.new_swapable_file("live_grep_provider", {
            opts.unrestricted and opts.provider.unrestricted
                or opts.provider.restricted,
        }, {
            opts.unrestricted and opts.provider.restricted
                or opts.provider.unrestricted,
        }, opts.debug),
    }

    local command_fmt = string.format(
        "nvim --headless -l %slive_grep_provider.lua",
        path.plugin_bin()
    )
    local initial_command = string.format(
        "%s %s %s || true",
        command_fmt,
        runtime.provider.current,
        query
    )
    local reload_command = string.format(
        "%s %s {q} || true",
        command_fmt,
        runtime.provider.current
    )
    log.debug(
        "|fzfx.live_grep - files| initial_command:%s, reload_command:%s",
        vim.inspect(initial_command),
        vim.inspect(reload_command)
    )

    local spec = {
        source = initial_command,
        options = {
            "--ansi",
            "--query",
            query,
            "--bind",
            -- unrestricted switch action: swap header, swap provider, then change header + reload
            string.format(
                "%s:unbind(%s)+execute-silent(mv %s %s && mv %s %s && mv %s %s)+execute-silent(mv %s %s && mv %s %s && mv %s %s)+rebind(%s)+transform-header(cat %s)+reload(%s)",
                unrestricted_switch_action,
                unrestricted_switch_action,
                Runtime.current_fuzzy_header,
                Runtime.swap_fuzzy_header,
                Runtime.next_fuzzy_header,
                Runtime.current_fuzzy_header,
                Runtime.swap_fuzzy_header,
                Runtime.next_fuzzy_header,
                Runtime.current_provider,
                Runtime.swap_provider,
                Runtime.next_provider,
                Runtime.current_provider,
                Runtime.swap_provider,
                Runtime.next_provider,
                unrestricted_switch_action,
                Runtime.current_fuzzy_header,
                reload_command
            ),
            "--bind",
            -- fuzzy switch action: swap header, enable search, then change header + reload
            string.format(
                "%s:unbind(%s)+execute-silent(mv %s %s && mv %s %s && mv %s %s)+execute-silent(mv %s %s && mv %s %s && mv %s %s)+rebind(%s)+transform-header(cat %s)+reload(%s)",
                unrestricted_switch_action,
                unrestricted_switch_action,
                Runtime.current_fuzzy_header,
                Runtime.swap_fuzzy_header,
                Runtime.next_fuzzy_header,
                Runtime.current_fuzzy_header,
                Runtime.swap_fuzzy_header,
                Runtime.next_fuzzy_header,
                Runtime.current_provider,
                Runtime.swap_provider,
                Runtime.next_provider,
                Runtime.current_provider,
                Runtime.swap_provider,
                Runtime.next_provider,
                unrestricted_switch_action,
                Runtime.current_fuzzy_header,
                reload_command
            ),
            "--header",
            (opts.unrestricted and restricted_header or unrestricted_header)
                .. fuzzy_header,
        },
    }
    spec = vim.fn["fzf#vim#with_preview"](spec)
    log.debug("|fzfx.live_grep - files| spec:%s", vim.inspect(spec))
    return vim.fn["fzf#vim#files"]("", spec, fullscreen)
end

--- @param live_grep_configs Config
local function setup(live_grep_configs)
    log.debug(
        "|fzfx.live_grep - setup| plugin_bin:%s, files_configs:%s",
        vim.inspect(path.plugin_bin()),
        vim.inspect(live_grep_configs)
    )
    local restricted_opts = vim.tbl_deep_extend(
        "force",
        vim.deepcopy(live_grep_configs),
        { unrestricted = false }
    )
    local unrestricted_opts = vim.tbl_deep_extend(
        "force",
        vim.deepcopy(live_grep_configs),
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
    utils.define_command(live_grep_configs.command.normal, function(opts)
        log.debug(
            "|fzfx.live_grep - setup| normal command opts:%s",
            vim.inspect(opts)
        )
        return files(opts.args, opts.bang, restricted_opts)
    end, normal_command_opts)
    -- FzfxFilesU
    utils.define_command(live_grep_configs.command.unrestricted, function(opts)
        log.debug(
            "|fzfx.live_grep - setup| unrestricted command opts:%s",
            vim.inspect(opts)
        )
        return files(opts.args, opts.bang, unrestricted_opts)
    end, normal_command_opts)
    -- FzfxFilesV
    utils.define_command(live_grep_configs.command.visual, function(opts)
        local visual_select = utils.visual_select()
        log.debug(
            "|fzfx.live_grep - setup| visual command select:%s, opts:%s",
            vim.inspect(visual_select),
            vim.inspect(opts)
        )
        return files(visual_select, opts.bang, restricted_opts)
    end, visual_command_opts)
    -- FzfxFilesUV
    utils.define_command(
        live_grep_configs.command.unrestricted_visual,
        function(opts)
            local visual_select = utils.visual_select()
            log.debug(
                "|fzfx.live_grep - setup| visual command select:%s, opts:%s",
                vim.inspect(visual_select),
                vim.inspect(opts)
            )
            return files(visual_select, opts.bang, unrestricted_opts)
        end,
        visual_command_opts
    )
    -- FzfxFilesW
    utils.define_command(live_grep_configs.command.cword, function(opts)
        local word = vim.fn.expand("<cword>")
        log.debug(
            "|fzfx.live_grep - setup| cword command word:%s, opts:%s",
            vim.inspect(word),
            vim.inspect(opts)
        )
        return files(word, opts.bang, restricted_opts)
    end, cword_command_opts)
    -- FzfxFilesUW
    utils.define_command(
        live_grep_configs.command.unrestricted_cword,
        function(opts)
            local word = vim.fn.expand("<cword>")
            log.debug(
                "|fzfx.live_grep - setup| cword command word:%s, opts:%s",
                vim.inspect(word),
                vim.inspect(opts)
            )
            return files(word, opts.bang, unrestricted_opts)
        end,
        cword_command_opts
    )

    -- runtime
    if live_grep_configs.debug then
        Runtime.current_fuzzy_header = string.format(
            "%s/fzfx.nvim/live_grep_current_header",
            vim.fn.stdpath("data")
        )
        Runtime.next_fuzzy_header = string.format(
            "%s/fzfx.nvim/live_grep_next_header",
            vim.fn.stdpath("data")
        )
        Runtime.swap_fuzzy_header = string.format(
            "%s/fzfx.nvim/live_grep_swap_header",
            vim.fn.stdpath("data")
        )
        Runtime.current_provider = string.format(
            "%s/fzfx.nvim/live_grep_current_provider",
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
        Runtime.current_fuzzy_header = path.tempname()
        Runtime.next_fuzzy_header = path.tempname()
        Runtime.swap_fuzzy_header = path.tempname()
        Runtime.current_provider = path.tempname()
        Runtime.next_provider = path.tempname()
        Runtime.swap_provider = path.tempname()
    end
    vim.env._FZFX_FILES_PROVIDER = Runtime.current_provider
    log.debug("|fzfx.live_grep - setup| Runtime:%s", vim.inspect(Runtime))
end

local M = {
    setup = setup,
}

return M
