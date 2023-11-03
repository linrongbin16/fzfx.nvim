local log = require("fzfx.log")
local LogLevels = require("fzfx.log").LogLevels
local path = require("fzfx.path")
local line_helpers = require("fzfx.line_helpers")
local utils = require("fzfx.utils")
local ui = require("fzfx.ui")

--- @param lines string[]
--- @return nil
local function nop(lines)
    log.debug("|fzfx.actions - nop| lines:%s", vim.inspect(lines))
end

--- @package
--- @param lines string[]
--- @param opts {no_icon:boolean?}?
--- @return string[]
local function _make_edit_find_commands(lines, opts)
    local results = {}
    for i, line in ipairs(lines) do
        local filename = line_helpers.parse_find(line, opts)
        local edit_command = string.format("edit! %s", filename)
        table.insert(results, edit_command)
    end
    return results
end

-- Run 'edit' vim command on fd/find results.
--- @param lines string[]
--- @param context PipelineContext
local function edit_find(lines, context)
    ui.confirm_discard_buffer_modified(context.bufnr, function()
        local edit_commands = _make_edit_find_commands(lines)
        for i, edit_command in ipairs(edit_commands) do
            log.debug("|fzfx.actions - edit_find| [%d]:[%s]", i, edit_command)
            vim.cmd(edit_command)
        end
    end)
end

--- @deprecated
local function edit_buffers(lines, context)
    return edit_find(lines, context)
end

--- @deprecated
local function edit_git_files(lines, context)
    return edit_find(lines, context)
end

--- @deprecated
local function edit(lines, context)
    return edit_find(lines, context)
end

--- @package
--- @param lines string[]
--- @param opts {no_icon:boolean?}?
--- @return string[]
local function _make_edit_rg_commands(lines, opts)
    local results = {}
    for i, line in ipairs(lines) do
        local parsed = line_helpers.parse_rg(line, opts)
        local edit_command = string.format("edit! %s", parsed.filename)
        table.insert(results, edit_command)
        if parsed.lineno ~= nil then
            if i == #lines then
                local column = parsed.column or 1
                local setpos_command = string.format(
                    "call setpos('.', [0, %d, %d])",
                    parsed.lineno,
                    column
                )
                table.insert(results, setpos_command)
            end
        end
    end
    return results
end

--- @param lines string[]
local function edit_rg(lines)
    local vim_commands = _make_edit_rg_commands(lines)
    for i, vim_command in ipairs(vim_commands) do
        log.debug("|fzfx.actions - edit_rg| [%d]:[%s]", i, vim_command)
        vim.cmd(vim_command)
    end
end

--- @package
--- @param lines string[]
--- @param opts {no_icon:boolean?}?
--- @return string[]
local function _make_edit_grep_commands(lines, opts)
    local results = {}
    for i, line in ipairs(lines) do
        local parsed = line_helpers.parse_grep(line, opts)
        local edit_command = string.format("edit! %s", parsed.filename)
        table.insert(results, edit_command)
        if parsed.lineno ~= nil then
            if i == #lines then
                local column = 1
                local setpos_command = string.format(
                    "call setpos('.', [0, %d, %d])",
                    parsed.lineno,
                    column
                )
                table.insert(results, setpos_command)
            end
        end
    end
    return results
end

--- @param lines string[]
local function edit_grep(lines)
    local vim_commands = _make_edit_grep_commands(lines)
    for i, vim_command in ipairs(vim_commands) do
        log.debug("|fzfx.actions - edit_grep| [%d]:[%s]", i, vim_command)
        vim.cmd(vim_command)
    end
end

-- Run 'edit' vim command on eza/exa/ls results.
--- @param lines string[]
local function edit_ls(lines)
    local edit_commands = _make_edit_find_commands(lines, { no_icon = true })
    for i, edit_command in ipairs(edit_commands) do
        log.debug("|fzfx.actions - edit_ls| [%d]:[%s]", i, edit_command)
        vim.cmd(edit_command)
    end
end

--- @deprecated
local function buffer(lines, context)
    return edit_find(lines, context)
end

--- @deprecated
--- @param line string?
local function bdelete(line)
    local list_bufnrs = vim.api.nvim_list_bufs()
    local list_bufpaths = {}
    for _, bufnr in ipairs(list_bufnrs) do
        local bufpath = path.reduce(vim.api.nvim_buf_get_name(bufnr))
        list_bufpaths[bufpath] = bufnr
    end
    log.debug(
        "|fzfx.actions - bdelete| list_bufpaths:%s",
        vim.inspect(list_bufpaths)
    )
    log.debug("|fzfx.actions - bdelete| line:%s", vim.inspect(line))
    if type(line) == "string" and string.len(line) > 0 then
        local bufpath = line_helpers.parse_find(line)
        log.debug("|fzfx.actions - bdelete| bufpath:%s", vim.inspect(bufpath))
        local bufnr = list_bufpaths[bufpath]
        if type(bufnr) == "number" then
            vim.api.nvim_buf_delete(bufnr, {})
        end
    end
end

--- @param lines string[]
--- @return string?
local function _make_git_checkout_command(lines)
    log.debug(
        "|fzfx.actions - _make_git_checkout_command| lines:%s",
        vim.inspect(lines)
    )

    --- @param s string
    --- @param t string
    --- @return string
    local function _try_remove_prefix(s, t)
        return utils.string_startswith(s, t) and s:sub(#t + 1) or s
    end

    if type(lines) == "table" and #lines > 0 then
        local line = vim.trim(lines[#lines])
        if type(line) == "string" and string.len(line) > 0 then
            -- `git branch -a` output looks like:
            --   main
            -- * my-plugin-dev
            --   remotes/origin/HEAD -> origin/main
            --   remotes/origin/main
            --   remotes/origin/my-plugin-dev
            line = _try_remove_prefix(line, "remotes/origin/")

            -- `git branch -r` output looks like:
            -- origin/HEAD -> origin/main
            -- origin/main
            -- origin/my-plugin-dev
            line = _try_remove_prefix(line, "origin/")
            local arrow_pos = utils.string_find(line, "->")
            if type(arrow_pos) == "number" and arrow_pos >= 0 then
                arrow_pos = arrow_pos + 1 + 2
                line = vim.trim(line:sub(arrow_pos))
            end
            line = _try_remove_prefix(line, "origin/")

            return vim.trim(string.format([[ !git checkout %s ]], line))
        end
    end
end

--- @param lines string[]
local function git_checkout(lines)
    local checkout_command = _make_git_checkout_command(lines) --[[@as string]]
    vim.cmd(checkout_command)
end

--- @param lines string[]
--- @return string?
local function _make_yank_git_commit_command(lines)
    if type(lines) == "table" and #lines > 0 then
        local line = lines[#lines]
        local space_pos = utils.string_find(line, " ")
        if not space_pos then
            return nil
        end
        local git_commit = line:sub(1, space_pos - 1)
        return string.format("let @+ = '%s'", git_commit)
    end
    return nil
end

--- @param lines string[]
local function yank_git_commit(lines)
    local yank_command = _make_yank_git_commit_command(lines)
    if yank_command then
        vim.api.nvim_command(yank_command)
    end
end

--- @param lines string[]
--- @return {filename:string,lnum:integer,col:integer}[]
local function _make_setqflist_find_items(lines)
    local qflist = {}
    for _, line in ipairs(lines) do
        local filename = line_helpers.parse_find(line)
        table.insert(qflist, { filename = filename, lnum = 1, col = 1 })
    end
    return qflist
end

--- @param lines string[]
local function setqflist_find(lines)
    local qflist = _make_setqflist_find_items(lines --[[@as table]])
    vim.cmd([[ :copen ]])
    vim.fn.setqflist({}, " ", {
        nr = "$",
        items = qflist,
    })
end

--- @param lines string[]
--- @return {filename:string,lnum:integer,col:integer,text:string}[]
local function _make_setqflist_rg_items(lines)
    local qflist = {}
    for _, line in ipairs(lines) do
        local parsed = line_helpers.parse_rg(line)
        table.insert(qflist, {
            filename = parsed.filename,
            lnum = parsed.lineno,
            col = parsed.column,
            text = parsed.text,
        })
    end
    return qflist
end

--- @param lines string[]
local function setqflist_rg(lines)
    local qflist = _make_setqflist_rg_items(lines)
    vim.cmd([[ :copen ]])
    vim.fn.setqflist({}, " ", {
        nr = "$",
        items = qflist,
    })
end

--- @param lines string[]
--- @return {filename:string,lnum:integer,col:integer,text:string}[]
local function _make_setqflist_grep_items(lines)
    local qflist = {}
    for _, line in ipairs(lines) do
        local parsed = line_helpers.parse_grep(line)
        table.insert(qflist, {
            filename = parsed.filename,
            lnum = parsed.lineno,
            col = 1,
            text = parsed.text,
        })
    end
    return qflist
end

--- @param lines string[]
local function setqflist_grep(lines)
    local qflist = _make_setqflist_grep_items(lines)
    vim.cmd([[ :copen ]])
    vim.fn.setqflist({}, " ", {
        nr = "$",
        items = qflist,
    })
end

--- @param lines string[]
--- @return {filename:string,lnum:integer,col:integer}[]
local function _make_setqflist_git_status_items(lines)
    local qflist = {}
    for _, line in ipairs(lines) do
        local filename = line_helpers.parse_git_status(line)
        table.insert(qflist, { filename = filename, lnum = 1, col = 1 })
    end
    return qflist
end

--- @param lines string[]
local function setqflist_git_status(lines)
    local qflist = _make_setqflist_git_status_items(lines --[[@as table]])
    vim.cmd([[ :copen ]])
    vim.fn.setqflist({}, " ", {
        nr = "$",
        items = qflist,
    })
end

--- @package
--- @param lines string[]
--- @return string, string
local function _make_feed_vim_command_params(lines)
    local line = lines[#lines]
    local space_pos = utils.string_find(line, " ")
    local input = vim.trim(line:sub(1, space_pos - 1))
    return string.format([[:%s]], input), "n"
end

--- @param lines string[]
local function feed_vim_command(lines)
    local input, mode = _make_feed_vim_command_params(lines)
    vim.fn.feedkeys(input, mode)
end

--- @package
--- @param lines string[]
--- @return "cmd"|"feedkeys"|nil, string?, string?
local function _make_feed_vim_key_params(lines)
    local line = lines[#lines]
    local space_pos = utils.string_find(line, " ") --[[@as integer]]
    local input = vim.trim(line:sub(1, space_pos - 1))
    local bar_pos = utils.string_find(line, "|", space_pos)
    local mode = vim.trim(line:sub(space_pos, bar_pos - 1))
    if utils.string_find(mode, "n") then
        mode = "n"
        if utils.string_startswith(input:lower(), "<plug>") then
            return "cmd", string.format([[execute "normal \%s"]], input), nil
        elseif
            utils.string_startswith(input, "<")
            and type(utils.string_rfind(input, ">")) == "number"
            and utils.string_rfind(input, ">") > 1
        then
            local tcodes =
                vim.api.nvim_replace_termcodes(input, true, false, true)
            return "feedkeys", tcodes, "n"
        else
            return "feedkeys", input, "n"
        end
    else
        log.echo(LogLevels.INFO, "%s mode %s not support.", mode, input)
        return nil, nil, nil
    end
end

--- @param lines string[]
local function feed_vim_key(lines)
    local feedtype, input, mode = _make_feed_vim_key_params(lines)
    if feedtype == "cmd" and type(input) == "string" then
        vim.cmd(input)
    elseif
        feedtype == "feedkeys"
        and type(input) == "string"
        and type(mode) == "string"
    then
        vim.fn.feedkeys(input, mode)
    end
end

--- @package
--- @param lines string[]
--- @return string[]
local function _make_edit_git_status_commands(lines)
    local results = {}
    for i, line in ipairs(lines) do
        local filename = line_helpers.parse_git_status(line)
        local edit_command = string.format("edit! %s", filename)
        table.insert(results, edit_command)
    end
    return results
end

-- Run 'edit' vim command on gits status results.
--- @param lines string[]
local function edit_git_status(lines)
    local edit_commands = _make_edit_git_status_commands(lines)
    for i, edit_command in ipairs(edit_commands) do
        log.debug("|fzfx.actions - edit_git_status| [%d]:[%s]", i, edit_command)
        vim.cmd(edit_command)
    end
end

local M = {
    nop = nop,
    _make_edit_find_commands = _make_edit_find_commands,
    _make_edit_grep_commands = _make_edit_grep_commands,
    _make_edit_rg_commands = _make_edit_rg_commands,
    edit = edit,
    edit_find = edit_find,
    edit_buffers = edit_buffers,
    edit_git_files = edit_git_files,
    edit_ls = edit_ls,
    edit_rg = edit_rg,
    edit_grep = edit_grep,
    buffer = buffer,
    bdelete = bdelete,
    _make_git_checkout_command = _make_git_checkout_command,
    git_checkout = git_checkout,
    _make_yank_git_commit_command = _make_yank_git_commit_command,
    yank_git_commit = yank_git_commit,
    _make_edit_git_status_commands = _make_edit_git_status_commands,
    edit_git_status = edit_git_status,
    _make_feed_vim_command_params = _make_feed_vim_command_params,
    _make_feed_vim_key_params = _make_feed_vim_key_params,
    feed_vim_command = feed_vim_command,
    feed_vim_key = feed_vim_key,
    _make_setqflist_find_items = _make_setqflist_find_items,
    _make_setqflist_rg_items = _make_setqflist_rg_items,
    _make_setqflist_grep_items = _make_setqflist_grep_items,
    _make_setqflist_git_status_items = _make_setqflist_git_status_items,
    setqflist_find = setqflist_find,
    setqflist_rg = setqflist_rg,
    setqflist_grep = setqflist_grep,
    setqflist_git_status = setqflist_git_status,
}

return M
