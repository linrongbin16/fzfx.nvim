local log = require("fzfx.log")
local line_helpers = require("fzfx.line_helpers")

--- @param lines string[]
--- @return nil
local function nop(lines)
    log.debug("|fzfx.actions - nop| lines:%s", vim.inspect(lines))
end

--- @alias EditFindVimCommands {edit:string[]}
--- @param lines string[]
--- @param opts {no_icon:boolean?}?
--- @return EditFindVimCommands
local function make_edit_find_commands(lines, opts)
    local results = { edit = {} }
    for i, line in ipairs(lines) do
        local filename = line_helpers.parse_find(line, opts)
        local edit_command = string.format("edit %s", filename)
        table.insert(results.edit, edit_command)
    end
    return results
end

-- Run 'edit' vim command on fd/find results.
--- @param lines string[]
local function edit_find(lines)
    local vim_commands = make_edit_find_commands(lines)
    for i, edit_command in ipairs(vim_commands.edit) do
        log.debug("|fzfx.actions - edit_find| [%d]:[%s]", i, edit_command)
        vim.cmd(edit_command)
    end
end

-- Run 'edit' vim command on buffers results.
--- @param lines string[]
local function edit_buffers(lines)
    return edit_find(lines)
end

-- Run 'edit' vim command on git files results.
--- @param lines string[]
local function edit_git_files(lines)
    return edit_find(lines)
end

--- @deprecated
--- @param lines string[]
local function edit(lines)
    require("fzfx.deprecated").notify(
        "deprecated 'actions.edit', please use 'actions.edit_find'!"
    )
    return edit_find(lines)
end

--- @alias EditGrepVimCommands {edit:string[], setpos:string?}
--- @param lines string[]
--- @param opts {no_icon:boolean?,delimiter:string?,filename_pos:integer?,lineno_pos:integer?,column_pos:integer?}?
--- @return EditGrepVimCommands
local function make_edit_grep_commands(lines, opts)
    local results = { edit = {}, setpos = nil }
    for i, line in ipairs(lines) do
        local parsed = line_helpers.parse_grep(line, opts)
        local edit_command = string.format("edit %s", parsed.filename)
        table.insert(results.edit, edit_command)
        if parsed.lineno ~= nil then
            if i == #lines then
                local column = parsed.column or 1
                local setpos_cmd = string.format(
                    "call setpos('.', [0, %d, %d])",
                    parsed.lineno,
                    column
                )
                results.setpos = setpos_cmd
            end
        end
    end
    return results
end

local function edit_grep(lines)
    local vim_commands = make_edit_grep_commands(lines)
    for i, edit_command in ipairs(vim_commands.edit) do
        log.debug("|fzfx.actions - edit_grep| edit[%d]:[%s]", i, edit_command)
        vim.cmd(edit_command)
    end
    if vim_commands.setpos then
        log.debug("|fzfx.actions - edit_grep| setpos:[%s]", vim_commands.setpos)
        vim.cmd(vim_commands.setpos)
    end
end

--- @deprecated
local function edit_rg(lines)
    return edit_grep(lines)
end

-- Run 'edit' vim command on eza/exa/ls results.
--- @param lines string[]
local function edit_ls(lines)
    local vim_commands = make_edit_find_commands(lines, { no_icon = true })
    for i, edit_command in ipairs(vim_commands.edit) do
        log.debug("|fzfx.actions - edit_ls| [%d]:[%s]", i, edit_command)
        vim.cmd(edit_command)
    end
end

--- @deprecated
local function buffer(lines)
    return edit_find(lines)
end

local function bdelete(lines)
    if type(lines) == "string" then
        lines = { lines }
    end
    if type(lines) == "table" and #lines > 0 then
        for _, line in ipairs(lines) do
            local parsed = line_helpers.PathLine:new(line)
            local cmd = string.format("bdelete %s", parsed.filename)
            log.debug(
                "|fzfx.actions - bdelete| line:[%s], bufname:[%s], cmd:[%s]",
                line,
                parsed.filename,
                cmd
            )
            vim.cmd(cmd)
        end
    end
end

local function git_checkout(lines)
    log.debug("|fzfx.actions - git_checkout| lines:%s", vim.inspect(lines))

    --- @param l string
    ---@param p string
    local function remove_prefix(l, p)
        local n = #p
        if string.len(l) > n and l:sub(1, n) == p then
            return l:sub(n + 1, #l)
        end
        return l
    end

    if type(lines) == "table" and #lines > 0 then
        local last_line = vim.trim(lines[#lines])
        if type(last_line) == "string" and string.len(last_line) > 0 then
            last_line = remove_prefix(last_line, "origin/")
            local arrow_pos = vim.fn.stridx(last_line, "->")
            if arrow_pos >= 0 then
                arrow_pos = arrow_pos + 1 + 2
                last_line = vim.trim(last_line:sub(arrow_pos, #last_line))
            end
            last_line = remove_prefix(last_line, "origin/")
            vim.cmd(vim.trim(string.format([[ !git checkout %s ]], last_line)))
        end
    end
end

local function yank_git_commit(lines)
    if type(lines) == "table" and #lines > 0 then
        local line = lines[#lines]
        local git_commit = vim.fn.split(line)[1]
        vim.api.nvim_command("let @+ = '" .. git_commit .. "'")
    end
end

local M = {
    nop = nop,
    make_edit_find_commands = make_edit_find_commands,
    make_edit_grep_commands = make_edit_grep_commands,
    edit = edit,
    edit_find = edit_find,
    edit_buffers = edit_buffers,
    edit_git_files = edit_git_files,
    edit_ls = edit_ls,
    edit_rg = edit_rg,
    edit_grep = edit_grep,
    buffer = buffer,
    bdelete = bdelete,
    git_checkout = git_checkout,
    yank_git_commit = yank_git_commit,
}

return M
