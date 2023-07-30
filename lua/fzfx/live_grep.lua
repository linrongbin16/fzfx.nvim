local log = require("fzfx.log")
local utils = require("fzfx.utils")
local path = require("fzfx.path")

local Context = {
    --- @type string|nil
    unrestricted_mode_header = nil,
    --- @type string|nil
    restricted_mode_header = nil,
    --- @type Config|nil
    live_grep_configs = nil,
}

--- @param query string
--- @param fullscreen boolean|integer
--- @param opts Config
local function live_grep(query, fullscreen, opts)
    local action =
        string.lower(Context.live_grep_configs.action.unrestricted_mode)

    local runtime = {
        --- @type FileSwitch
        header = utils.new_file_switch("live_grep_header", {
            opts.unrestricted and Context.restricted_mode_header
                or Context.unrestricted_mode_header,
        }, {
            opts.unrestricted and Context.unrestricted_mode_header
                or Context.restricted_mode_header,
        }),
        --- @type FileSwitch
        provider = utils.new_file_switch("live_grep_provider", {
            opts.unrestricted
                    and Context.live_grep_configs.provider.unrestricted
                or Context.live_grep_configs.provider.restricted,
        }, {
            opts.unrestricted and Context.live_grep_configs.provider.restricted
                or Context.live_grep_configs.provider.unrestricted,
        }),
    }
    log.debug("|fzfx.live_grep - live_grep| runtime:%s", vim.inspect(runtime))

    local initial_command = string.format(
        "%s %s %s || true",
        utils.run_lua_script("live_grep_provider.lua"),
        runtime.provider.value,
        query
    )
    local reload_command = string.format(
        "%s %s {q} || true",
        utils.run_lua_script("live_grep_provider.lua"),
        runtime.provider.value
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
            opts.unrestricted and Context.restricted_mode_header
                or Context.unrestricted_mode_header,
            "--prompt",
            "Live Grep> ",
            "--bind",
            string.format("change:reload:%s", reload_command),
            "--bind",
            -- unrestricted action: swap header, swap provider, then change header + reload
            string.format(
                "%s:unbind(%s)+execute-silent(%s)+execute-silent(%s)+rebind(%s)+transform-header(cat %s)+reload(%s)",
                action,
                action,
                runtime.header:switch(),
                runtime.provider:switch(),
                action,
                runtime.header.value,
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

    local action = live_grep_configs.action.unrestricted_mode

    -- Context
    Context.live_grep_configs = vim.deepcopy(live_grep_configs)
    Context.unrestricted_mode_header = utils.unrestricted_mode_header(action)
    Context.restricted_mode_header = utils.restricted_mode_header(action)

    local restricted_opts = { unrestricted = false }
    local unrestricted_opts = { unrestricted = true }

    local normal_opts = {
        bang = true,
        nargs = "*",
    }
    -- FzfxLiveGrep
    utils.define_command(live_grep_configs.command.normal, function(opts)
        log.debug(
            "|fzfx.live_grep - setup| normal command opts:%s",
            vim.inspect(opts)
        )
        return live_grep(opts.args, opts.bang, restricted_opts)
    end, normal_opts)
    -- FzfxLiveGrepU
    utils.define_command(live_grep_configs.command.unrestricted, function(opts)
        log.debug(
            "|fzfx.live_grep - setup| unrestricted command opts:%s",
            vim.inspect(opts)
        )
        return live_grep(opts.args, opts.bang, unrestricted_opts)
    end, normal_opts)

    local visual_opts = {
        bang = true,
        range = true,
    }
    -- FzfxLiveGrepV
    utils.define_command(live_grep_configs.command.visual, function(opts)
        local visual_select = utils.visual_select()
        log.debug(
            "|fzfx.live_grep - setup| visual command select:%s, opts:%s",
            vim.inspect(visual_select),
            vim.inspect(opts)
        )
        return live_grep(visual_select, opts.bang, restricted_opts)
    end, visual_opts)
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
        visual_opts
    )

    local cword_opts = {
        bang = true,
    }
    -- FzfxLiveGrepW
    utils.define_command(live_grep_configs.command.cword, function(opts)
        local word = vim.fn.expand("<cword>")
        log.debug(
            "|fzfx.live_grep - setup| cword command word:%s, opts:%s",
            vim.inspect(word),
            vim.inspect(opts)
        )
        return live_grep(word, opts.bang, restricted_opts)
    end, cword_opts)
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
        cword_opts
    )
end

local M = {
    setup = setup,
}

return M
