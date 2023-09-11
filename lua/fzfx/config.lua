local constants = require("fzfx.constants")
local utils = require("fzfx.utils")
local env = require("fzfx.env")
local log = require("fzfx.log")
local LogLevel = require("fzfx.log").LogLevel
local color = require("fzfx.color")
local path = require("fzfx.path")
local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum
local ProviderConfig = require("fzfx.schema").ProviderConfig
local ProviderLineTypeEnum = require("fzfx.schema").ProviderLineTypeEnum
local PreviewerConfig = require("fzfx.schema").PreviewerConfig
local CommandConfig = require("fzfx.schema").CommandConfig
local InteractionConfig = require("fzfx.schema").InteractionConfig
local GroupConfig = require("fzfx.schema").GroupConfig

-- gnu find
local default_restricted_gnu_find_exclude_hidden = [[*/.*]]
local default_restricted_gnu_find = string.format(
    [[%s -L . -type f -not -path %s]],
    constants.gnu_find,
    utils.shellescape(default_restricted_gnu_find_exclude_hidden)
)
local default_unrestricted_gnu_find = [[find -L . -type f]]

-- find
local default_restricted_find_exclude_hidden = [[*/.*]]
local default_restricted_find = string.format(
    [[find -L . -type f -not -path %s]],
    utils.shellescape(default_restricted_find_exclude_hidden)
)
local default_unrestricted_find = [[find -L . -type f]]

-- fd
local default_restricted_fd =
    string.format("%s . -cnever -tf -tl -L -i", constants.fd)
local default_unrestricted_fd =
    string.format("%s . -cnever -tf -tl -L -i -u", constants.fd)

-- gnu grep
local default_restricted_gnu_grep_exclude_hidden = [[.*]]
local default_restricted_gnu_grep = string.format(
    [[%s --color=always -n -H -r --exclude-dir=%s --exclude=%s]],
    constants.gnu_grep,
    utils.shellescape(default_restricted_gnu_grep_exclude_hidden),
    utils.shellescape(default_restricted_gnu_grep_exclude_hidden)
)
local default_unrestricted_gnu_grep = [[grep --color=always -n -H -r]]

-- grep
local default_restricted_grep_exclude_hidden = [[./.*]]
local default_restricted_grep = string.format(
    [[grep --color=always -n -H -r --exclude-dir=%s --exclude=%s]],
    utils.shellescape(default_restricted_grep_exclude_hidden),
    utils.shellescape(default_restricted_grep_exclude_hidden)
)
local default_unrestricted_grep = [[grep --color=always -n -H -r]]

-- rg
local default_restricted_rg =
    string.format("%s --column -n --no-heading --color=always -S", constants.rg)
local default_unrestricted_rg = string.format(
    "%s --column -n --no-heading --color=always -S -uu",
    constants.rg
)

--- @type table<string, FzfOpt>
local default_fzf_options = {
    multi = "--multi",
    toggle = "--bind=ctrl-e:toggle",
    toggle_all = "--bind=ctrl-a:toggle-all",
    toggle_preview = "--bind=alt-p:toggle-preview",
    preview_half_page_down = "--bind=ctrl-f:preview-half-page-down",
    preview_half_page_up = "--bind=ctrl-b:preview-half-page-up",
    no_multi = "--no-multi",
}

local default_git_log_pretty =
    "%C(yellow)%h %C(cyan)%cd %C(green)%aN%C(auto)%d %Creset%s"

-- file {

--- @param delimiter string?
--- @param filename_pos integer?
--- @param lineno_pos integer?
--- @return fun(line:string):string
local function make_file_previewer(delimiter, filename_pos, lineno_pos)
    --- @param line string
    --- @return string
    local function wrap(line)
        log.debug(
            "|fzfx.config - make_file_previewer| delimiter:%s, filename_pos:%s, lineno_pos:%s",
            vim.inspect(delimiter),
            vim.inspect(filename_pos),
            vim.inspect(lineno_pos)
        )
        log.debug(
            "|fzfx.config - make_file_previewer| line:%s",
            vim.inspect(line)
        )
        local filename = line
        local lineno = nil
        if
            type(delimiter) == "string"
            and string.len(delimiter) > 0
            and type(filename_pos) == "number"
            and filename_pos > 0
        then
            local line_splits = vim.fn.split(line, delimiter)
            filename = line_splits[filename_pos]
            lineno = line_splits[lineno_pos]
        end
        filename = env.icon_enable() and vim.fn.split(filename)[2] or filename
        if constants.has_bat then
            local style = "numbers,changes"
            if
                type(vim.env["BAT_STYLE"]) == "string"
                and string.len(vim.env["BAT_STYLE"]) > 0
            then
                style = vim.env["BAT_STYLE"]
            end
            return string.format(
                "%s --style=%s --color=always --pager=never %s -- %s",
                constants.bat,
                style,
                (lineno ~= nil and string.len(lineno) > 0)
                        and string.format("--highlight-line=%s", lineno)
                    or "",
                filename
            )
        else
            return string.format("cat %s", filename)
        end
    end
    return wrap
end

-- file }

-- lsp diagnostics {

--- @alias LspDiagnosticOpts {mode:"buffer_diagnostics"|"workspace_diagnostics",severity:integer?,bufnr:integer?}
--- @param opts LspDiagnosticOpts
--- @return string[]?
local function lsp_diagnostics_provider(opts)
    local active_lsp_clients = vim.lsp.get_active_clients()
    if utils.list_empty(active_lsp_clients) then
        log.echo(LogLevel.INFO, "no active lsp clients.")
        return nil
    end
    local signs = {
        [1] = {
            severity = 1,
            text = env.icon_enable() and "" or "E", -- nf-fa-times \uf00d
            texthl = vim.fn.hlexists("DiagnosticSignError") > 0
                    and "DiagnosticSignError"
                or (
                    vim.fn.hlexists("LspDiagnosticsSignError") > 0
                        and "LspDiagnosticsSignError"
                    or "ErrorMsg"
                ),
            textcolor = "red",
        },
        [2] = {
            severity = 2,
            text = env.icon_enable() and "" or "W", -- nf-fa-warning \uf071
            texthl = vim.fn.hlexists("DiagnosticSignWarn") > 0
                    and "DiagnosticSignWarn"
                or (
                    vim.fn.hlexists("LspDiagnosticsSignWarn") > 0
                        and "LspDiagnosticsSignWarn"
                    or "WarningMsg"
                ),
            textcolor = "yellow",
        },
        [3] = {
            severity = 3,
            text = env.icon_enable() and "" or "I", -- nf-fa-info_circle \uf05a
            texthl = vim.fn.hlexists("DiagnosticSignInfo") > 0
                    and "DiagnosticSignInfo"
                or (
                    vim.fn.hlexists("LspDiagnosticsSignInfo") > 0
                        and "LspDiagnosticsSignInfo"
                    or "None"
                ),
            textcolor = "blue",
        },
        [4] = {
            severity = 4,
            text = env.icon_enable() and "" or "H", -- nf-fa-bell \uf0f3
            texthl = vim.fn.hlexists("DiagnosticSignHint") > 0
                    and "DiagnosticSignHint"
                or (
                    vim.fn.hlexists("LspDiagnosticsSignHint") > 0
                        and "LspDiagnosticsSignHint"
                    or "Comment"
                ),
            textcolor = "cyan",
        },
    }
    for _, sign_opts in pairs(signs) do
        local sign_def = vim.fn.sign_getdefined(sign_opts.sign)
        if not utils.list_empty(sign_def) then
            sign_opts.text = vim.fn.trim(sign_def[1].text)
            sign_opts.texthl = sign_def[1].texthl
        end
    end

    local diag_results = vim.diagnostic.get(
        opts.mode == "buffer_diagnostics" and opts.bufnr or nil
    )
    -- descending: error, warn, info, hint
    table.sort(diag_results, function(a, b)
        return a.severity < b.severity
    end)
    if utils.list_empty(diag_results) then
        log.echo(LogLevel.INFO, "no lsp diagnostics found.")
        return nil
    end

    --- @alias DiagItem {bufnr:integer,filename:string,lnum:integer,col:integer,text:string,severity:integer}
    --- @return DiagItem?
    local function preprocess_diag_item(diag)
        if not vim.api.nvim_buf_is_valid(diag.bufnr) then
            return nil
        end
        local bufname = vim.api.nvim_buf_get_name(diag.bufnr)
        local bufpath = vim.fn.fnamemodify(bufname, ":~:.")
        local range_start = diag.range and diag.range["start"]
        local row = diag.lnum or range_start.line
        local col = diag.col or range_start.character
        return {
            bufnr = diag.bufnr,
            filename = bufpath,
            lnum = row + 1,
            col = col + 1,
            text = vim.fn.trim(diag.message:gsub("[\n]", "")),
            severity = diag.severity or 1,
        }
    end

    -- simulate rg's filepath color, see:
    -- * https://github.com/BurntSushi/ripgrep/discussions/2605#discussioncomment-6881383
    -- * https://github.com/BurntSushi/ripgrep/blob/d596f6ebd035560ee5706f7c0299c4692f112e54/crates/printer/src/color.rs#L14
    local filepath_color = constants.is_windows and color.cyan_8bit
        or color.magenta_8bit
    local diag_lines = {}
    for _, diag in ipairs(diag_results) do
        local d = preprocess_diag_item(diag)
        if d ~= nil then
            -- it looks like:
            -- `lua/fzfx/config.lua:10:13:local ProviderConfig = require("fzfx.schema").ProviderConfig`
            local dtext = ""
            if type(d.text) == "string" and string.len(d.text) > 0 then
                if type(signs[d.severity]) == "table" then
                    local sign_def = signs[d.severity]
                    local icon_color = color[sign_def.textcolor]
                    dtext = " " .. icon_color(sign_def.text, sign_def.texthl)
                end
                dtext = dtext .. " " .. d.text
            end
            local line = string.format(
                [[%s:%s:%s:%s]],
                filepath_color(d.filename),
                color.green_8bit(tostring(d.lnum)),
                tostring(d.col),
                dtext
            )
            table.insert(diag_lines, line)
        end
    end
    return diag_lines
end

-- lsp diagnostics }

-- lsp definitions {

--- @alias LspLocationRangeStart {line:integer,character:integer}
--- @alias LspLocationRangeEnd {line:integer,character:integer}
--- @alias LspLocationRange {start:LspLocationRangeStart,end:LspLocationRangeEnd}
--- @alias LspLocation {uri:string,range:LspLocationRange}
--- @alias LspLocationLink {originSelectionRange:LspLocationRange,targetUri:string,targetRange:LspLocationRange,targetSelectionRange:LspLocationRange}

--- @param r LspLocationRange?
--- @return boolean
local function is_lsp_range(r)
    return type(r) == "table"
        and type(r.start) == "table"
        and type(r.start.line) == "number"
        and type(r.start.character) == "number"
        and type(r["end"]) == "table"
        and type(r["end"].line) == "number"
        and type(r["end"].character) == "number"
end

--- @param loc LspLocation|LspLocationLink|nil
local function is_lsp_location(loc)
    return type(loc) == "table"
        and type(loc.uri) == "string"
        and is_lsp_range(loc.range)
end

--- @param loc LspLocation|LspLocationLink|nil
local function is_lsp_locationlink(loc)
    return type(loc) == "table"
        and type(loc.targetUri) == "string"
        and is_lsp_range(loc.originSelectionRange)
        and is_lsp_range(loc.targetRange)
        and is_lsp_range(loc.targetSelectionRange)
end

--- @param line string
--- @param range LspLocationRange
--- @param color_renderer fun(text:string):string
--- @return string?
local function lsp_location_render_line(line, range, color_renderer)
    log.debug(
        "|fzfx.config - lsp_location_render_line| range:%s, line:%s",
        vim.inspect(range),
        vim.inspect(line)
    )
    local line_start = range.start.character + 1
    local line_end = range["end"].line ~= range.start.line and #line
        or math.min(range["end"].character, #line)
    local p1 = ""
    if line_start > 1 then
        p1 = line:sub(1, line_start - 1)
    end
    local p2 = ""
    if line_start <= line_end then
        p2 = color_renderer(line:sub(line_start, line_end))
    end
    local p3 = ""
    if line_end + 1 <= #line then
        p3 = line:sub(line_end + 1, #line)
    end
    local result = vim.fn.trim(p1 .. p2 .. p3)
    return result
end

local function lsp_position_context_maker()
    --- @type PipelineContext
    local context = {
        bufnr = vim.api.nvim_get_current_buf(),
        winnr = vim.api.nvim_get_current_win(),
        tabnr = vim.api.nvim_get_current_tabpage(),
    }
    ---@diagnostic disable-next-line: inject-field
    context.position_params =
        vim.lsp.util.make_position_params(context.winnr, nil)
    context.position_params.context = {
        includeDeclaration = true,
    }
    return context
end

--- @alias LspMethod "textDocument/definition"|"textDocument/tyep_definition"|"textDocument/reference"|"textDocument/implementation"

--- @alias LspDefinitionOpts {method:LspMethod,bufnr:integer,timeout:integer?,position_params:any?}
--- @param opts LspDefinitionOpts
--- @return string[]?
local function lsp_definitions_provider(opts)
    local lsp_results, lsp_err = vim.lsp.buf_request_sync(
        opts.bufnr,
        opts.method,
        opts.position_params,
        opts.timeout or 5000
    )
    log.debug(
        "|fzfx.config - lsp_definitions_provider| opts:%s, lsp_results:%s, lsp_err:%s",
        vim.inspect(opts),
        vim.inspect(lsp_results),
        vim.inspect(lsp_err)
    )
    if lsp_err then
        log.echo(LogLevel.ERROR, lsp_err)
        return nil
    end
    if type(lsp_results) ~= "table" then
        log.echo(LogLevel.INFO, "no lsp definitions found.")
        return nil
    end

    local filepath_color = constants.is_windows and color.cyan_8bit
        or color.magenta_8bit

    --- @param loc LspLocation|LspLocationLink
    --- @return string?
    local function process_location(loc)
        --- @type string
        local filename = nil
        --- @type LspLocationRange
        local range = nil
        log.debug(
            "|fzfx.config - lsp_definitions_provider.process_location| loc:%s",
            vim.inspect(loc)
        )
        if is_lsp_location(loc) then
            filename = path.reduce(vim.uri_to_fname(loc.uri))
            range = loc.range
            log.debug(
                "|fzfx.config - lsp_definitions_provider.process_location| location filename:%s, range:%s",
                vim.inspect(filename),
                vim.inspect(range)
            )
        end
        if is_lsp_locationlink(loc) then
            filename = path.reduce(vim.uri_to_fname(loc.targetUri))
            range = loc.targetRange
            log.debug(
                "|fzfx.config - lsp_definitions_provider.process_location| locationlink filename:%s, range:%s",
                vim.inspect(filename),
                vim.inspect(range)
            )
        end
        if not is_lsp_range(range) then
            return nil
        end
        if type(filename) ~= "string" or vim.fn.filereadable(filename) <= 0 then
            return nil
        end
        local filelines = vim.fn.readfile(filename)
        if type(filelines) ~= "table" or #filelines < range.start.line + 1 then
            return nil
        end
        local loc_line = lsp_location_render_line(
            filelines[range.start.line + 1],
            range,
            color.red_8bit
        )
        log.debug(
            "|fzfx.config - lsp_definitions_provider.process_location| range:%s, loc_line:%s",
            vim.inspect(range),
            vim.inspect(loc_line)
        )
        local line = string.format(
            [[%s:%s:%s:%s]],
            filepath_color(vim.fn.fnamemodify(filename, ":~:.")),
            color.green_8bit(tostring(range.start.line + 1)),
            tostring(range.start.character + 1),
            loc_line
        )
        return line
    end

    local def_lines = {}

    for client_id, lsp_result in pairs(lsp_results) do
        if
            client_id == nil
            or type(lsp_result) ~= "table"
            or type(lsp_result.result) ~= "table"
        then
            break
        end
        local lsp_defs = lsp_result.result
        if is_lsp_location(lsp_defs) then
            local line = process_location(lsp_defs)
            if type(line) == "string" and string.len(line) > 0 then
                table.insert(def_lines, line)
            end
        else
            for _, def in ipairs(lsp_defs) do
                local line = process_location(def)
                if type(line) == "string" and string.len(line) > 0 then
                    table.insert(def_lines, line)
                end
            end
        end
    end

    if utils.list_empty(def_lines) then
        log.echo(LogLevel.INFO, "no lsp definitions found.")
        return nil
    end

    return def_lines
end

-- lsp definitions }

--- @alias Configs table<string, any>
--- @type Configs
local Defaults = {
    -- the 'Files' commands
    files = {
        --- @type CommandConfig[]
        commands = {
            -- normal
            {
                name = "FzfxFiles",
                feed = CommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "?",
                    complete = "dir",
                    desc = "Find files",
                },
                default_provider = "restricted",
            },
            {
                name = "FzfxFilesU",
                feed = CommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "?",
                    complete = "dir",
                    desc = "Find files",
                },
                default_provider = "unrestricted",
            },
            -- visual
            {
                name = "FzfxFilesV",
                feed = CommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Find files by visual select",
                },
                default_provider = "restricted",
            },
            {
                name = "FzfxFilesUV",
                feed = CommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Find files unrestricted by visual select",
                },
                default_provider = "unrestricted",
            },
            -- cword
            {
                name = "FzfxFilesW",
                feed = CommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Find files by cursor word",
                },
                default_provider = "restricted",
            },
            {
                name = "FzfxFilesUW",
                feed = CommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Find files unrestricted by cursor word",
                },
                default_provider = "unrestricted",
            },
            -- put
            {
                name = "FzfxFilesP",
                feed = CommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Find files by yank text",
                },
                default_provider = "restricted",
            },
            {
                name = "FzfxFilesUP",
                feed = CommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Find files unrestricted by yank text",
                },
                default_provider = "unrestricted",
            },
        },
        providers = {
            restricted = {
                "ctrl-r",
                constants.has_fd and default_restricted_fd
                    or (
                        constants.has_gnu_find
                            and default_restricted_gnu_find
                        or default_restricted_find
                    ),
            },
            unrestricted = {
                "ctrl-u",
                constants.has_fd and default_unrestricted_fd
                    or (
                        constants.has_gnu_find
                            and default_unrestricted_gnu_find
                        or default_unrestricted_find
                    ),
            },
        },
        actions = {
            ["esc"] = require("fzfx.actions").nop,
            ["enter"] = require("fzfx.actions").edit,
            ["double-click"] = require("fzfx.actions").edit,
        },
        fzf_opts = {
            default_fzf_options.multi,
            function()
                return {
                    "--prompt",
                    path.shorten() .. " > ",
                }
            end,
        },
    },

    -- the 'Live Grep' commands
    live_grep = {
        --- @type CommandConfig[]
        commands = {
            -- normal
            {
                name = "FzfxLiveGrep",
                feed = CommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "*",
                    desc = "Live grep",
                },
                default_provider = "restricted",
            },
            {
                name = "FzfxLiveGrepU",
                feed = CommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "*",
                    desc = "Live grep unrestricted",
                },
                default_provider = "unrestricted",
            },
            -- visual
            {
                name = "FzfxLiveGrepV",
                feed = CommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Live grep by visual select",
                },
                default_provider = "restricted",
            },
            {
                name = "FzfxLiveGrepUV",
                feed = CommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Live grep unrestricted by visual select",
                },
                default_provider = "unrestricted",
            },
            -- cword
            {
                name = "FzfxLiveGrepW",
                feed = CommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Live grep by cursor word",
                },
                default_provider = "restricted",
            },
            {
                name = "FzfxLiveGrepUW",
                feed = CommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Live grep unrestricted by cursor word",
                },
                default_provider = "unrestricted",
            },
            -- put
            {
                name = "FzfxLiveGrepP",
                feed = CommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Live grep by yank text",
                },
                default_provider = "restricted",
            },
            {
                name = "FzfxLiveGrepUP",
                feed = CommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Live grep unrestricted by yank text",
                },
                default_provider = "unrestricted",
            },
        },
        providers = {
            restricted = {
                "ctrl-r",
                constants.has_rg and default_restricted_rg
                    or (
                        constants.has_gnu_grep
                            and default_restricted_gnu_grep
                        or default_restricted_grep
                    ),
            },
            unrestricted = {
                "ctrl-u",
                constants.has_rg and default_unrestricted_rg
                    or (
                        constants.has_gnu_grep
                            and default_unrestricted_gnu_grep
                        or default_unrestricted_grep
                    ),
            },
        },
        actions = {
            ["esc"] = require("fzfx.actions").nop,
            ["enter"] = constants.has_rg and require("fzfx.actions").edit_rg
                or require("fzfx.actions").edit_grep,
            ["double-click"] = constants.has_rg
                    and require("fzfx.actions").edit_rg
                or require("fzfx.actions").edit_grep,
        },
        fzf_opts = {
            default_fzf_options.multi,
            { "--prompt", "Live Grep > " },
            { "--delimiter", ":" },
            { "--preview-window", "+{2}-/2" },
        },
        other_opts = {
            onchange_reload_delay = (
                vim.fn.executable("sleep") > 0 and not constants.is_windows
            )
                    and "sleep 0.1 && "
                or nil,
        },
    },

    -- the 'Buffers' commands
    --- @type GroupConfig
    buffers = GroupConfig:make({
        commands = {
            -- normal
            CommandConfig:make({
                name = "FzfxBuffers",
                feed = CommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "?",
                    complete = "file",
                    desc = "Find buffers",
                },
            }),
            -- visual
            CommandConfig:make({
                name = "FzfxBuffersV",
                feed = CommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Find buffers by visual select",
                },
            }),
            -- cword
            CommandConfig:make({
                name = "FzfxBuffersW",
                feed = CommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Find buffers by cursor word",
                },
            }),
            -- put
            CommandConfig:make({
                name = "FzfxBuffersP",
                feed = CommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Find buffers by yank text",
                },
            }),
        },
        providers = ProviderConfig:make({
            key = "default",
            provider = function(query, context)
                local function valid_bufnr(b)
                    local exclude_filetypes = {
                        ["qf"] = true,
                        ["neo-tree"] = true,
                    }
                    local ft = utils.get_buf_option(b, "filetype")
                    return utils.is_buf_valid(b) and not exclude_filetypes[ft]
                end
                local bufnrs_list = vim.api.nvim_list_bufs()
                local bufpaths_list = {}
                local current_bufpath = valid_bufnr(context.bufnr)
                        and path.reduce(context.bufnr)
                    or nil
                if
                    type(current_bufpath) == "string"
                    and string.len(current_bufpath) > 0
                then
                    table.insert(bufpaths_list, current_bufpath)
                end
                for _, bn in ipairs(bufnrs_list) do
                    local bp = path.reduce(bn)
                    if valid_bufnr(bn) and bp ~= current_bufpath then
                        table.insert(bufpaths_list, bp)
                    end
                end
                return bufpaths_list
            end,
            provider_type = ProviderTypeEnum.LIST,
            line_type = ProviderLineTypeEnum.FILE,
        }),
        previewers = PreviewerConfig:make({
            previewer = make_file_previewer(),
            previewer_type = PreviewerTypeEnum.COMMAND,
        }),
        interactions = {
            delete_buffer = InteractionConfig:make({
                key = "ctrl-d",
                interaction = require("fzfx.actions").bdelete,
                reload_after_execute = true,
            }),
        },
        actions = {
            ["esc"] = require("fzfx.actions").nop,
            ["enter"] = require("fzfx.actions").buffer,
            ["double-click"] = require("fzfx.actions").buffer,
        },
        fzf_opts = {
            default_fzf_options.multi,
            {
                "--prompt",
                "Buffers > ",
            },
            function()
                local current_bufnr = vim.api.nvim_get_current_buf()
                return utils.is_buf_valid(current_bufnr) and "--header-lines=1"
                    or nil
            end,
        },
    }),

    -- the 'Git Files' commands
    git_files = {
        commands = {
            -- normal
            {
                name = "FzfxGFiles",
                feed = CommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "?",
                    complete = "dir",
                    desc = "Find git files",
                },
            },
            -- visual
            {
                name = "FzfxGFilesV",
                feed = CommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Find git files by visual select",
                },
            },
            -- cword
            {
                name = "FzfxGFilesW",
                feed = CommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Find git files by cursor word",
                },
            },
            -- put
            {
                name = "FzfxGFilesP",
                feed = CommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Find git files by yank text",
                },
            },
        },
        providers = "git ls-files",
        actions = {
            ["esc"] = require("fzfx.actions").nop,
            ["enter"] = require("fzfx.actions").edit,
            ["double-click"] = require("fzfx.actions").edit,
        },
        fzf_opts = {
            default_fzf_options.multi,
            function()
                return {
                    "--prompt",
                    path.shorten() .. " > ",
                }
            end,
        },
    },

    -- the 'Git Branches' commands
    --- @type GroupConfig
    git_branches = GroupConfig:make({
        commands = {
            -- normal
            CommandConfig:make({
                name = "FzfxGBranches",
                feed = CommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "?",
                    complete = "dir",
                    desc = "Search local git branches",
                },
                default_provider = "local_branch",
            }),
            CommandConfig:make({
                name = "FzfxGBranchesR",
                feed = CommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "?",
                    complete = "dir",
                    desc = "Search remote git branches",
                },
                default_provider = "remote_branch",
            }),
            -- visual
            CommandConfig:make({
                name = "FzfxGBranchesV",
                feed = CommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Search local git branches by visual select",
                },
                default_provider = "local_branch",
            }),
            CommandConfig:make({
                name = "FzfxGBranchesRV",
                feed = CommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Search remote git branches by visual select",
                },
                default_provider = "remote_branch",
            }),
            -- cword
            CommandConfig:make({
                name = "FzfxGBranchesW",
                feed = CommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Search local git branches by cursor word",
                },
                default_provider = "local_branch",
            }),
            CommandConfig:make({
                name = "FzfxGBranchesRW",
                feed = CommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Search remote git branches by cursor word",
                },
                default_provider = "remote_branch",
            }),
            -- put
            CommandConfig:make({
                name = "FzfxGBranchesP",
                feed = CommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Search local git branches by yank text",
                },
                default_provider = "local_branch",
            }),
            CommandConfig:make({
                name = "FzfxGBranchesRP",
                feed = CommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Search remote git branches by yank text",
                },
                default_provider = "remote_branch",
            }),
        },
        providers = {
            local_branch = ProviderConfig:make({
                key = "ctrl-o",
                provider = function(query, context)
                    local cmd = require("fzfx.cmd")
                    local git_root_cmd = cmd.GitRootCmd:run()
                    if git_root_cmd:wrong() then
                        log.echo(LogLevel.INFO, "not in git repo.")
                        return nil
                    end
                    local git_current_branch_cmd = cmd.GitCurrentBranchCmd:run()
                    if git_current_branch_cmd:wrong() then
                        log.echo(
                            LogLevel.WARN,
                            table.concat(
                                git_current_branch_cmd.result.stderr,
                                " "
                            )
                        )
                        return nil
                    end
                    local branch_results = {}
                    table.insert(
                        branch_results,
                        string.format("* %s", git_current_branch_cmd:value())
                    )
                    local git_branch_cmd = cmd.Cmd:run("git branch")
                    if git_branch_cmd.result:wrong() then
                        log.echo(
                            LogLevel.WARN,
                            table.concat(
                                git_current_branch_cmd.result.stderr,
                                " "
                            )
                        )
                        return nil
                    end
                    for _, line in ipairs(git_branch_cmd.result.stdout) do
                        table.insert(
                            branch_results,
                            string.format("  %s", vim.fn.trim(line))
                        )
                    end

                    return branch_results
                end,
                provider_type = ProviderTypeEnum.LIST,
            }),
            remote_branch = ProviderConfig:make({
                key = "ctrl-r",
                provider = function(query, context)
                    local cmd = require("fzfx.cmd")
                    local git_root_cmd = cmd.GitRootCmd:run()
                    if git_root_cmd:wrong() then
                        log.echo(LogLevel.INFO, "not in git repo.")
                        return nil
                    end
                    local git_current_branch_cmd = cmd.GitCurrentBranchCmd:run()
                    if git_current_branch_cmd:wrong() then
                        log.echo(
                            LogLevel.WARN,
                            table.concat(
                                git_current_branch_cmd.result.stderr,
                                " "
                            )
                        )
                        return nil
                    end
                    local branch_results = {}
                    table.insert(
                        branch_results,
                        string.format("* %s", git_current_branch_cmd:value())
                    )
                    local git_branch_cmd = cmd.Cmd:run("git branch --remotes")
                    if git_branch_cmd.result:wrong() then
                        log.echo(
                            LogLevel.WARN,
                            table.concat(
                                git_current_branch_cmd.result.stderr,
                                " "
                            )
                        )
                        return nil
                    end
                    for _, line in ipairs(git_branch_cmd.result.stdout) do
                        table.insert(
                            branch_results,
                            string.format("  %s", vim.fn.trim(line))
                        )
                    end

                    return branch_results
                end,
                provider_type = ProviderTypeEnum.LIST,
            }),
        },
        previewers = {
            local_branch = PreviewerConfig:make({
                previewer = function(line)
                    local branch = vim.fn.split(line)[1]
                    -- "git log --graph --date=short --color=always --pretty='%C(auto)%cd %h%d %s'",
                    -- "git log --graph --color=always --date=relative",
                    return string.format(
                        "git log --pretty=%s --graph --date=short --color=always %s",
                        utils.shellescape(default_git_log_pretty),
                        branch
                    )
                end,
                previewer_type = PreviewerTypeEnum.COMMAND,
            }),
            remote_branch = PreviewerConfig:make({
                previewer = function(line)
                    local branch = vim.fn.split(line)[1]
                    return string.format(
                        "git log --pretty=%s --graph --date=short --color=always %s",
                        utils.shellescape(default_git_log_pretty),
                        branch
                    )
                end,
                previewer_type = PreviewerTypeEnum.COMMAND,
            }),
        },
        actions = {
            ["esc"] = require("fzfx.actions").nop,
            ["enter"] = require("fzfx.actions").git_checkout,
            ["double-click"] = require("fzfx.actions").git_checkout,
        },
        fzf_opts = {
            default_fzf_options.no_multi,
            {
                "--prompt",
                "GBranches > ",
            },
            function()
                local cmd = require("fzfx.cmd")
                local git_root_cmd = cmd.GitRootCmd:run()
                if git_root_cmd:wrong() then
                    return nil
                end
                local git_current_branch_cmd = cmd.GitCurrentBranchCmd:run()
                if git_current_branch_cmd:wrong() then
                    return nil
                end
                return utils.string_not_empty(git_current_branch_cmd:value())
                        and "--header-lines=1"
                    or nil
            end,
        },
    }),

    -- the 'Git Commits' commands
    --- @type GroupConfig
    git_commits = GroupConfig:make({
        commands = {
            -- normal
            CommandConfig:make({
                name = "FzfxGCommits",
                feed = CommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "?",
                    desc = "Search git commits",
                },
                default_provider = "all_commits",
            }),
            CommandConfig:make({
                name = "FzfxGCommitsB",
                feed = CommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "?",
                    desc = "Search git commits only on current buffer",
                },
                default_provider = "buffer_commits",
            }),
            -- visual
            CommandConfig:make({
                name = "FzfxGCommitsV",
                feed = CommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Search git commits by visual select",
                },
                default_provider = "all_commits",
            }),
            CommandConfig:make({
                name = "FzfxGCommitsBV",
                feed = CommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Search git commits only on current buffer by visual select",
                },
                default_provider = "buffer_commits",
            }),
            -- cword
            CommandConfig:make({
                name = "FzfxGCommitsW",
                feed = CommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Search git commits by cursor word",
                },
                default_provider = "all_commits",
            }),
            CommandConfig:make({
                name = "FzfxGCommitsBW",
                feed = CommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Search git commits only on current buffer by cursor word",
                },
                default_provider = "buffer_commits",
            }),
            -- put
            CommandConfig:make({
                name = "FzfxGCommitsP",
                feed = CommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Search git commits by yank text",
                },
                default_provider = "all_commits",
            }),
            CommandConfig:make({
                name = "FzfxGCommitsBP",
                feed = CommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Search git commits only on current buffer by yank text",
                },
                default_provider = "buffer_commits",
            }),
        },
        providers = {
            all_commits = ProviderConfig:make({
                key = "ctrl-a",
                -- provider = {
                --     "git",
                --     "log",
                --     "--pretty=" .. default_git_log_pretty,
                --     "--date=short",
                --     "--color=always",
                -- },
                provider = string.format(
                    "git log --pretty=%s --date=short --color=always",
                    utils.shellescape(default_git_log_pretty)
                ),
            }),
            buffer_commits = ProviderConfig:make({
                key = "ctrl-u",
                provider = function(query, context)
                    if not utils.is_buf_valid(context.bufnr) then
                        log.echo(
                            LogLevel.INFO,
                            "no commits found on invalid buffer (%s).",
                            vim.inspect(context.bufnr)
                        )
                        return nil
                    end
                    -- return string.format(
                    --     "git log --pretty=%s --date=short --color=always -- %s",
                    --     utils.shellescape(default_git_log_pretty),
                    --     vim.api.nvim_buf_get_name(context.bufnr)
                    -- )
                    return {
                        "git",
                        "log",
                        -- no need to surround two quotes to pretty format
                        -- see: https://github.com/luvit/luv/issues/673
                        "--pretty=" .. default_git_log_pretty,
                        "--date=short",
                        "--color=always",
                        "--",
                        vim.api.nvim_buf_get_name(context.bufnr),
                    }
                end,
                -- provider_type = ProviderTypeEnum.COMMAND,
                provider_type = ProviderTypeEnum.COMMAND_LIST,
            }),
        },
        previewers = {
            all_commits = PreviewerConfig:make({
                previewer = function(line)
                    local commit = vim.fn.split(line)[1]
                    return string.format("git show --color=always %s", commit)
                end,
                previewer_type = PreviewerTypeEnum.COMMAND,
            }),
            buffer_commits = PreviewerConfig:make({
                previewer = function(line)
                    local commit = vim.fn.split(line)[1]
                    return string.format("git show --color=always %s", commit)
                end,
                previewer_type = PreviewerTypeEnum.COMMAND,
            }),
        },
        actions = {
            ["esc"] = require("fzfx.actions").nop,
            ["enter"] = require("fzfx.actions").yank_git_commit,
            ["double-click"] = require("fzfx.actions").yank_git_commit,
        },
        fzf_opts = {
            default_fzf_options.no_multi,
            {
                "--prompt",
                "GCommits > ",
            },
        },
    }),

    -- the 'Git Blame' command
    --- @type GroupConfig
    git_blame = GroupConfig:make({
        commands = {
            -- normal
            CommandConfig:make({
                name = "FzfxGBlame",
                feed = CommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "?",
                    desc = "Search git commits",
                },
            }),
            -- visual
            CommandConfig:make({
                name = "FzfxGBlameV",
                feed = CommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Search git commits by visual select",
                },
            }),
            -- cword
            CommandConfig:make({
                name = "FzfxGBlameW",
                feed = CommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Search git commits by cursor word",
                },
            }),
            -- put
            CommandConfig:make({
                name = "FzfxGBlameP",
                feed = CommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Search git commits by yank text",
                },
            }),
        },
        providers = {
            default = ProviderConfig:make({
                key = "default",
                provider = function(query, context)
                    if not utils.is_buf_valid(context.bufnr) then
                        log.echo(
                            LogLevel.INFO,
                            "no commits found on invalid buffer (%s).",
                            vim.inspect(context.bufnr)
                        )
                        return nil
                    end
                    local bufname = vim.api.nvim_buf_get_name(context.bufnr)
                    local bufpath = vim.fn.fnamemodify(bufname, ":~:.")
                    return string.format(
                        "git blame --date=short --color-lines %s",
                        bufpath
                    )
                    -- return {
                    --     "git",
                    --     "blame",
                    --     "--date=short",
                    --     "--color-lines",
                    --     bufpath,
                    -- }
                end,
                provider_type = ProviderTypeEnum.COMMAND,
                -- provider_type = ProviderTypeEnum.COMMAND_LIST,
            }),
        },
        previewers = {
            default = PreviewerConfig:make({
                previewer = function(line)
                    local commit = vim.fn.split(line)[1]
                    return string.format("git show --color=always %s", commit)
                end,
                previewer_type = PreviewerTypeEnum.COMMAND,
            }),
        },
        actions = {
            ["esc"] = require("fzfx.actions").nop,
            ["enter"] = require("fzfx.actions").yank_git_commit,
            ["double-click"] = require("fzfx.actions").yank_git_commit,
        },
        fzf_opts = {
            default_fzf_options.no_multi,
            {
                "--prompt",
                "GBlame > ",
            },
        },
    }),

    -- the 'Lsp Diagnostics' command
    --- @type GroupConfig
    lsp_diagnostics = GroupConfig:make({
        commands = {
            -- normal
            CommandConfig:make({
                name = "FzfxLspDiagnostics",
                feed = CommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "?",
                    desc = "Search lsp diagnostics on workspace",
                },
                default_provider = "workspace_diagnostics",
            }),
            CommandConfig:make({
                name = "FzfxLspDiagnosticsB",
                feed = CommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "?",
                    desc = "Search lsp diagnostics on current buffer",
                },
                default_provider = "buffer_diagnostics",
            }),
            -- visual
            CommandConfig:make({
                name = "FzfxLspDiagnosticsV",
                feed = CommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Search lsp diagnostics on workspace by visual select",
                },
                default_provider = "workspace_diagnostics",
            }),
            CommandConfig:make({
                name = "FzfxLspDiagnosticsBV",
                feed = CommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Search lsp diagnostics on current buffer by visual select",
                },
                default_provider = "buffer_diagnostics",
            }),
            -- cword
            CommandConfig:make({
                name = "FzfxLspDiagnosticsW",
                feed = CommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Search lsp diagnostics on workspace by cursor word",
                },
                default_provider = "workspace_diagnostics",
            }),
            CommandConfig:make({
                name = "FzfxLspDiagnosticsBW",
                feed = CommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Search lsp diagnostics on current buffer by cursor word",
                },
                default_provider = "buffer_diagnostics",
            }),
            -- put
            CommandConfig:make({
                name = "FzfxLspDiagnosticsP",
                feed = CommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Search lsp diagnostics on workspace by yank text",
                },
                default_provider = "workspace_diagnostics",
            }),
            CommandConfig:make({
                name = "FzfxLspDiagnosticsBP",
                feed = CommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Search lsp diagnostics on current buffer by yank text",
                },
                default_provider = "buffer_diagnostics",
            }),
        },
        providers = {
            workspace_diagnostics = ProviderConfig:make({
                key = "ctrl-w",
                provider = function(query, context)
                    return lsp_diagnostics_provider({
                        mode = "workspace_diagnostics",
                    })
                end,
                provider_type = ProviderTypeEnum.LIST,
                line_type = ProviderLineTypeEnum.FILE,
                line_delimiter = ":",
                line_pos = 1,
            }),
            buffer_diagnostics = ProviderConfig:make({
                key = "ctrl-u",
                provider = function(query, context)
                    return lsp_diagnostics_provider({
                        mode = "buffer_diagnostics",
                        bufnr = context.bufnr,
                    })
                end,
                provider_type = ProviderTypeEnum.LIST,
                line_type = ProviderLineTypeEnum.FILE,
                line_delimiter = ":",
                line_pos = 1,
            }),
        },
        previewers = {
            workspace_diagnostics = PreviewerConfig:make({
                previewer = make_file_previewer(":", 1, 2),
                previewer_type = PreviewerTypeEnum.COMMAND,
            }),
            buffer_diagnostics = PreviewerConfig:make({
                previewer = make_file_previewer(":", 1, 2),
                previewer_type = PreviewerTypeEnum.COMMAND,
            }),
        },
        actions = {
            ["esc"] = require("fzfx.actions").nop,
            ["enter"] = require("fzfx.actions").edit_rg,
            ["double-click"] = require("fzfx.actions").edit_rg,
        },
        fzf_opts = {
            default_fzf_options.multi,
            { "--delimiter", ":" },
            { "--preview-window", "+{2}-/2" },
            {
                "--prompt",
                "Diagnostics > ",
            },
        },
    }),

    -- the 'Lsp Definitions' command
    --- @type GroupConfig
    lsp_definitions = GroupConfig:make({
        commands = CommandConfig:make({
            name = "FzfxLspDefinitions",
            feed = CommandFeedEnum.ARGS,
            opts = {
                bang = true,
                desc = "Search lsp definitions",
            },
        }),
        providers = ProviderConfig:make({
            key = "default",
            provider = function(query, context)
                return lsp_definitions_provider({
                    method = "textDocument/definition",
                    bufnr = context.bufnr,
                    position_params = context.position_params,
                })
            end,
            provider_type = ProviderTypeEnum.LIST,
            context_maker = lsp_position_context_maker,
            line_type = ProviderLineTypeEnum.FILE,
            line_delimiter = ":",
            line_pos = 1,
        }),
        previewers = PreviewerConfig:make({
            previewer = make_file_previewer(":", 1, 2),
            previewer_type = PreviewerTypeEnum.COMMAND,
        }),
        actions = {
            ["esc"] = require("fzfx.actions").nop,
            ["enter"] = require("fzfx.actions").edit_rg,
            ["double-click"] = require("fzfx.actions").edit_rg,
        },
        fzf_opts = {
            default_fzf_options.multi,
            { "--delimiter", ":" },
            { "--preview-window", "+{2}-/2" },
            {
                "--prompt",
                "Definitions > ",
            },
        },
    }),

    -- the 'Yank History' commands
    yank_history = {
        other_opts = {
            maxsize = 100,
        },
    },

    -- the 'Users' commands
    users = nil,

    -- FZF_DEFAULT_OPTS
    fzf_opts = {
        "--ansi",
        "--info=inline",
        "--layout=reverse",
        "--border=rounded",
        "--height=100%",
        default_fzf_options.toggle,
        default_fzf_options.toggle_all,
        default_fzf_options.toggle_preview,
        default_fzf_options.preview_half_page_down,
        default_fzf_options.preview_half_page_up,
    },

    -- fzf colors
    -- see: https://github.com/junegunn/fzf/blob/master/README-VIM.md#explanation-of-gfzf_colors
    fzf_color_opts = {
        fg = { "fg", "Normal" },
        bg = { "bg", "Normal" },
        hl = { "fg", "Comment" },
        ["fg+"] = { "fg", "CursorLine", "CursorColumn", "Normal" },
        ["bg+"] = { "bg", "CursorLine", "CursorColumn" },
        ["hl+"] = { "fg", "Statement" },
        info = { "fg", "PreProc" },
        border = { "fg", "Ignore" },
        prompt = { "fg", "Conditional" },
        pointer = { "fg", "Exception" },
        marker = { "fg", "Keyword" },
        spinner = { "fg", "Label" },
        header = { "fg", "Comment" },
    },

    -- nerd fonts: https://www.nerdfonts.com/cheat-sheet
    -- unicode: https://symbl.cc/en/
    icons = {
        -- nerd fonts:
        --     nf-fa-file_text_o               \uf0f6 (default)
        --     nf-fa-file_o                    \uf016
        unknown_file = "",

        -- nerd fonts:
        --     nf-custom-folder                \ue5ff (default)
        --     nf-fa-folder                    \uf07b
        -- 󰉋    nf-md-folder                    \udb80\ude4b
        folder = "",

        -- nerd fonts:
        --     nf-custom-folder_open           \ue5fe (default)
        --     nf-fa-folder_open               \uf07c
        -- 󰝰    nf-md-folder_open               \udb81\udf70
        folder_open = "",

        -- nerd fonts:
        --     nf-oct-arrow_right              \uf432
        --     nf-cod-arrow_right              \uea9c
        --     nf-fa-caret_right               \uf0da
        --     nf-weather-direction_right      \ue349
        --     nf-fa-long_arrow_right          \uf178
        --     nf-oct-chevron_right            \uf460
        --     nf-fa-chevron_right             \uf054 (default)
        --
        -- unicode:
        -- https://symbl.cc/en/collections/arrow-symbols/
        -- ➜    U+279C                          &#10140;
        -- ➤    U+27A4                          &#10148;
        fzf_pointer = "",

        -- nerd fonts:
        --     nf-fa-star                      \uf005
        -- 󰓎    nf-md-star                      \udb81\udcce
        --     nf-cod-star_full                \ueb59
        --     nf-oct-dot_fill                 \uf444
        --     nf-fa-dot_circle_o              \uf192
        --     nf-cod-check                    \ueab2
        --     nf-fa-check                     \uf00c
        -- 󰄬    nf-md-check                     \udb80\udd2c
        --
        -- unicode:
        -- https://symbl.cc/en/collections/star-symbols/
        -- https://symbl.cc/en/collections/list-bullets/
        -- https://symbl.cc/en/collections/special-symbols/
        -- •    U+2022                          &#8226;
        -- ✓    U+2713                          &#10003; (default)
        fzf_marker = "✓",
    },

    popup = {
        -- nvim float window options
        -- see: https://neovim.io/doc/user/api.html#nvim_open_win()
        win_opts = {
            -- popup window height/width.
            --
            -- 1. if 0 <= h/w <= 1, evaluate proportionally according to editor's lines and columns,
            --    e.g. popup height = h * lines, width = w * columns.
            --
            -- 2. if h/w > 1, evaluate as absolute height and width, directly pass to vim.api.nvim_open_win.

            --- @type number
            height = 0.85,
            --- @type number
            width = 0.85,

            -- popup window position, by default popup window is right in the center of editor.
            -- especially useful when popup window is too big and conflicts with command/status line at bottom.
            --
            -- 1. if -0.5 <= r/c <= 0.5, evaluate proportionally according to editor's lines and columns.
            --    e.g. shift rows = r * lines, shift columns = c * columns.
            --
            -- 2. if r/c <= -1 or r/c >= 1, evaluate as absolute rows/columns to be shift.
            --    e.g. you can easily set 'row = -vim.o.cmdheight' to move popup window to up 1~2 lines (based on your 'cmdheight' option).
            --
            -- 3. r/c cannot be in range (-1, -0.5) or (0.5, 1), it makes no sense.

            --- @type number
            row = 0,
            --- @type number
            col = 0,

            border = "none",
            zindex = 51,
        },
    },

    -- environment variables
    env = {
        --- @type string|nil
        nvim = nil,
        --- @type string|nil
        fzf = nil,
    },

    cache = {
        --- @type string
        dir = string.format(
            "%s%sfzfx.nvim",
            vim.fn.stdpath("data"),
            constants.path_separator
        ),
    },

    -- debug
    debug = {
        enable = false,
        console_log = true,
        file_log = false,
    },
}

--- @type Configs
local Configs = {}

--- @param options Configs|nil
--- @return Configs
local function setup(options)
    Configs = vim.tbl_deep_extend("force", Defaults, options or {})
    return Configs
end

--- @return Configs
local function get_config()
    return Configs
end

local M = {
    setup = setup,
    get_config = get_config,
}

return M
