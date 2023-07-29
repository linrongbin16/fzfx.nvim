local log = require("fzfx.log")
local utils = require("fzfx.utils")
local path = require("fzfx.path")

local Context = {
    --- @type string|nil
    restricted_mode_header = nil,
    --- @type string|nil
    unrestricted_mode_header = nil,
    --- @type Config|nil
    files_configs = nil,
}

--- @param query string
--- @param fullscreen boolean|integer
--- @param opts Config
local function files(query, fullscreen, opts)
    -- action
    local action = string.lower(Context.files_configs.action.unrestricted_mode)

    --- @type table<string, FileSwitch>
    local runtime = {
        --- @type FileSwitch
        header = utils.new_file_switch("files_header", {
            opts.unrestricted and Context.restricted_mode_header
                or Context.unrestricted_mode_header,
        }, {
            opts.unrestricted and Context.unrestricted_mode_header
                or Context.restricted_mode_header,
        }),
        --- @type FileSwitch
        provider = utils.new_file_switch("files_provider", {
            opts.unrestricted and Context.files_configs.provider.unrestricted
                or Context.files_configs.provider.restricted,
        }, {
            opts.unrestricted and Context.files_configs.provider.restricted
                or Context.files_configs.provider.unrestricted,
        }),
    }
    log.debug("|fzfx.files - files| runtime:%s", vim.inspect(runtime))

    -- query command, both initial query + reload query
    local query_command = string.format(
        "%s %s || true",
        utils.run_lua_script("files_provider.lua"),
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
            "--header",
            opts.unrestricted and Context.restricted_mode_header
                or Context.unrestricted_mode_header,
            "--bind",
            -- unrestricted switch action: swap header, swap provider, then change header + reload
            string.format(
                "%s:unbind(%s)+execute-silent(%s)+execute-silent(%s)+rebind(%s)+transform-header(cat %s)+reload(%s)",
                action,
                action,
                runtime.header:switch(),
                runtime.provider:switch(),
                action,
                runtime.header.current,
                query_command
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

    local action = files_configs.action.unrestricted_mode

    -- Context
    Context.files_configs = vim.deepcopy(files_configs)
    Context.restricted_mode_header = utils.unrestricted_mode_header(action)
    Context.unrestricted_mode_header = utils.restricted_mode_header(action)

    local restricted_opts = { unrestricted = false }
    local unrestricted_opts = { unrestricted = true }

    local normal_opts = {
        bang = true,
        nargs = "?",
        complete = "dir",
    }
    -- FzfxFiles
    utils.define_command(files_configs.command.normal, function(opts)
        log.debug(
            "|fzfx.files - setup| normal command opts:%s",
            vim.inspect(opts)
        )
        return files(opts.args, opts.bang, restricted_opts)
    end, normal_opts)
    -- FzfxFilesU
    utils.define_command(files_configs.command.unrestricted, function(opts)
        log.debug(
            "|fzfx.files - setup| unrestricted command opts:%s",
            vim.inspect(opts)
        )
        return files(opts.args, opts.bang, unrestricted_opts)
    end, normal_opts)

    local visual_opts = {
        bang = true,
        range = true,
    }
    -- FzfxFilesV
    utils.define_command(files_configs.command.visual, function(opts)
        local visual_select = utils.visual_select()
        log.debug(
            "|fzfx.files - setup| visual command select:%s, opts:%s",
            vim.inspect(visual_select),
            vim.inspect(opts)
        )
        return files(visual_select, opts.bang, restricted_opts)
    end, visual_opts)
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
        visual_opts
    )

    local cword_opts = {
        bang = true,
    }
    -- FzfxFilesW
    utils.define_command(files_configs.command.cword, function(opts)
        local word = vim.fn.expand("<cword>")
        log.debug(
            "|fzfx.files - setup| cword command word:%s, opts:%s",
            vim.inspect(word),
            vim.inspect(opts)
        )
        return files(word, opts.bang, restricted_opts)
    end, cword_opts)
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
        cword_opts
    )
end

local M = {
    setup = setup,
}

return M
