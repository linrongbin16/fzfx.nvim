local log = require("fzfx.log")

--- @param configs Config
local function define_command(configs, fun, command_opts)
    vim.api.nvim_create_user_command(
        configs.name,
        fun,
        configs.desc
                and vim.tbl_deep_extend(
                    "force",
                    vim.deepcopy(command_opts),
                    { desc = configs.desc }
                )
            or command_opts
    )
end

--- @param mode string
--- @return string
local function get_visual_lines(mode)
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local line_start = start_pos[2]
    local column_start = start_pos[3]
    local line_end = end_pos[2]
    local column_end = end_pos[3]
    line_start = math.min(line_start, line_end)
    line_end = math.max(line_start, line_end)
    column_start = math.min(column_start, column_end)
    column_end = math.max(column_start, column_end)

    local lines = vim.fn.getlines(line_start, line_end)
    if #lines == 0 then
        return ""
    end

    if mode == "v" or mode == "\22" then
        local offset = string.lower(vim.o.selection) == "inclusive" and 1 or 2
        local last_line = string.sub(lines[#lines], 1, column_end - offset + 1)
        local first_line = string.sub(lines[1], column_start)
        log.debug(
            "|fzfx.utils - get_visual_lines| last_line:[%s], first_line:[%s]",
            last_line,
            first_line
        )
        lines[#lines] = last_line
        lines[1] = first_line
    elseif mode == "V" then
        if #lines == 1 then
            lines[1] = vim.fn.trim(lines[1])
        end
    end

    return table.concat(lines, "\n")
end

--- @return string
local function visual_select()
    vim.cmd([[ execute "normal! \<ESC>" ]])
    local mode = vim.fn.visualmode()
    if mode == "v" or mode == "V" or mode == "\22" then
        return get_visual_lines(mode)
    end
    return ""
end

local M = {
    define_command = define_command,
    visual_select = visual_select,
}

return M
