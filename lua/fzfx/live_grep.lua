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

    local runtime = {
        --- @type SwapableFile
        header = path.new_swapable_file(
            "live_grep_unrestricted_header",
            {
                opts.unrestricted and restricted_header or unrestricted_header,
            },
            { opts.unrestricted and unrestricted_header or restricted_header },
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
    log.debug("|fzfx.live_grep - live_grep| runtime:%s", vim.inspect(runtime))

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
        "|fzfx.live_grep - live_grep| initial_command:%s, reload_command:%s",
        vim.inspect(initial_command),
        vim.inspect(reload_command)
    )

    local spec = {
        options = {
            "--ansi",
            "--disabled",
            "--query",
            query,
            "--header",
            opts.unrestricted and restricted_header or unrestricted_header,
            "--prompt",
            "Live Grep> ",
            "--bind",
            string.format("change:reload:%s", reload_command),
            "--bind",
            -- unrestricted switch action: swap header, swap provider, then change header + reload
            string.format(
                "%s:unbind(%s)+execute-silent(%s)+execute-silent(%s)+rebind(%s)+transform-header(cat %s)+reload(%s)",
                unrestricted_switch_action,
                unrestricted_switch_action,
                runtime.header:swap_by_shell(),
                runtime.provider:swap_by_shell(),
                unrestricted_switch_action,
                runtime.header.current,
                reload_command
            ),
        },
    }
    spec = vim.fn["fzf#vim#with_preview"](spec)
    log.debug("|fzfx.live_grep - live_grep| spec:%s", vim.inspect(spec))
    return vim.fn["fzf#vim#grep"](initial_command, spec, fullscreen)
end

--- @param live_grep_configs Config
local function setup(live_grep_configs)
    log.debug(
        "|fzfx.live_grep - setup| plugin_bin:%s, live_grep_configs:%s",
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
        nargs = "*",
    }
    local visual_command_opts = {
        bang = true,
        range = true,
    }
    local cword_command_opts = {
        bang = true,
    }

    -- FzfxLiveGrep
    utils.define_command(live_grep_configs.command.normal, function(opts)
        log.debug(
            "|fzfx.live_grep - setup| normal command opts:%s",
            vim.inspect(opts)
        )
        return live_grep(opts.args, opts.bang, restricted_opts)
    end, normal_command_opts)
    -- FzfxLiveGrepU
    utils.define_command(live_grep_configs.command.unrestricted, function(opts)
        log.debug(
            "|fzfx.live_grep - setup| unrestricted command opts:%s",
            vim.inspect(opts)
        )
        return live_grep(opts.args, opts.bang, unrestricted_opts)
    end, normal_command_opts)
    -- FzfxLiveGrepV
    utils.define_command(live_grep_configs.command.visual, function(opts)
        local visual_select = utils.visual_select()
        log.debug(
            "|fzfx.live_grep - setup| visual command select:%s, opts:%s",
            vim.inspect(visual_select),
            vim.inspect(opts)
        )
        return live_grep(visual_select, opts.bang, restricted_opts)
    end, visual_command_opts)
    -- FzfxLiveGrepUV
    utils.define_command(
        live_grep_configs.command.unrestricted_visual,
        function(opts)
            local visual_select = utils.visual_select()
            log.debug(
                "|fzfx.live_grep - setup| visual command select:%s, opts:%s",
                vim.inspect(visual_select),
                vim.inspect(opts)
            )
            return live_grep(visual_select, opts.bang, unrestricted_opts)
        end,
        visual_command_opts
    )
    -- FzfxLiveGrepW
    utils.define_command(live_grep_configs.command.cword, function(opts)
        local word = vim.fn.expand("<cword>")
        log.debug(
            "|fzfx.live_grep - setup| cword command word:%s, opts:%s",
            vim.inspect(word),
            vim.inspect(opts)
        )
        return live_grep(word, opts.bang, restricted_opts)
    end, cword_command_opts)
    -- FzfxLiveGrepUW
    utils.define_command(
        live_grep_configs.command.unrestricted_cword,
        function(opts)
            local word = vim.fn.expand("<cword>")
            log.debug(
                "|fzfx.live_grep - setup| cword command word:%s, opts:%s",
                vim.inspect(word),
                vim.inspect(opts)
            )
            return live_grep(word, opts.bang, unrestricted_opts)
        end,
        cword_command_opts
    )
end

local M = {
    setup = setup,
}

return M
