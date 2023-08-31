local log = require("fzfx.log")

--- @alias AnsiCodeType "black"|"red"|"green"|"yellow"|"blue"|"magenta"|"cyan"
--- @type table<AnsiCodeType, integer>
local AnsiCode = {
    black = 30,
    red = 31,
    green = 32,
    yellow = 33,
    blue = 34,
    magenta = 35,
    cyan = 36,
}

--- @alias VimSyntaxHighlightAttribute "fg"|"bg"
--- @param attr VimSyntaxHighlightAttribute
--- @param group string
--- @return string|nil
local function get_color(attr, group)
    local gui = vim.fn.has("termguicolors") > 0 and vim.o.termguicolors
    local family = gui and "gui" or "cterm"
    local pattern = gui and "^#[%l%d]+" or "^[%d]+$"
    local code =
        vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(group)), attr, family)
    if string.find(code, pattern) then
        -- log.debug(
        --     "|fzfx.color - get_color| attr:%s, group:%s, code:%s",
        --     vim.inspect(attr),
        --     vim.inspect(group),
        --     vim.inspect(code)
        -- )
        return code
    end
    -- log.debug(
    --     "|fzfx.color - get_color| return nil, attr:%s, group:%s, code:%s",
    --     vim.inspect(attr),
    --     vim.inspect(group),
    --     vim.inspect(code)
    -- )
    return nil
end

--- @param color string
--- @param fg boolean
--- @return string|nil
local function csi(color, fg)
    local code = fg and 38 or 48
    local r, g, b = color:match("#(..)(..)(..)")
    if r and g and b then
        r = tonumber(r, 16)
        g = tonumber(g, 16)
        b = tonumber(b, 16)
        local result = string.format("%d;2;%d;%d;%d", code, r, g, b)
        -- log.debug(
        --     "|fzfx.color - csi| rgb, color:%s, fg:%s, result:%s",
        --     vim.inspect(color),
        --     vim.inspect(fg),
        --     vim.inspect(result)
        -- )
        return result
    else
        local result = string.format("%d;5;%s", code, color)
        -- log.debug(
        --     "|fzfx.color - csi| non-rgb, color:%s, fg:%s, result:%s",
        --     vim.inspect(color),
        --     vim.inspect(fg),
        --     vim.inspect(result)
        -- )
        return result
    end
end

--- @param text string
--- @param name string
--- @param hl string?
--- @return string
local function ansi(text, name, hl)
    local fgcolor = nil
    if type(hl) == "string" then
        local fg = get_color("fg", hl)
        if type(fg) == "string" then
            fgcolor = csi(fg, true)
        -- log.debug(
        --     "|fzfx.color - ansi| rgb, text:%s, name:%s, group:%s, fg:%s, fgcolor:%s",
        --     vim.inspect(text),
        --     vim.inspect(name),
        --     vim.inspect(hl),
        --     vim.inspect(fg),
        --     vim.inspect(fgcolor)
        -- )
        else
            fgcolor = AnsiCode[name]
            -- log.debug(
            --     "|fzfx.color - ansi| ansi, text:%s, name:%s, group:%s, fg:%s, fgcolor:%s",
            --     vim.inspect(text),
            --     vim.inspect(name),
            --     vim.inspect(hl),
            --     vim.inspect(fg),
            --     vim.inspect(fgcolor)
            -- )
        end
    else
        fgcolor = AnsiCode[name]
    end

    local finalcolor = nil
    if type(hl) == "string" then
        local bg = get_color("bg", hl)
        if type(bg) == "string" then
            local bgcolor = csi(bg, false)
            -- log.debug(
            --     "|fzfx.color - ansi| rgb, text:%s, name:%s, group:%s, bg:%s, bgcolor:%s",
            --     vim.inspect(text),
            --     vim.inspect(name),
            --     vim.inspect(hl),
            --     vim.inspect(bg),
            --     vim.inspect(bgcolor)
            -- )
            finalcolor = string.format("%s;%s", fgcolor, bgcolor)
        else
            -- log.debug(
            --     "|fzfx.color - ansi| ansi, text:%s, name:%s, group:%s, bg:%s",
            --     vim.inspect(text),
            --     vim.inspect(name),
            --     vim.inspect(hl),
            --     vim.inspect(bg)
            -- )
            finalcolor = fgcolor
        end
    else
        finalcolor = fgcolor
    end

    -- log.debug(
    --     "|fzfx.color - ansi| ansi, finalcolor:%s",
    --     vim.inspect(text),
    --     vim.inspect(name),
    --     vim.inspect(hl),
    --     vim.inspect(bg)
    -- )
    return string.format("[%sm%s[0m", finalcolor, text)
end

--- @type table<string, function>
local M = {
    get_color = get_color,
    csi = csi,
    ansi = ansi,
}

for color, default_hl in pairs({
    black = "Comment",
    red = "Exception",
    green = "Label",
    yellow = "LineNr",
    blue = "TabLine",
    magenta = "Special",
    cyan = "String",
}) do
    --- @param text string
    --- @param hl string|nil
    --- @return string
    M[color] = function(text, hl)
        return ansi(text, color, hl or default_hl)
    end
    M[color .. "_8b"] = function(text)
        return ansi(text, color, nil)
    end
end

--- @param fmt string
--- @param renderer fun(text:string,hl:string|nil):string
--- @return string
M.render = function(fmt, renderer, ...)
    local args = {}
    for _, a in ipairs({ ... }) do
        table.insert(args, renderer(a))
    end
    ---@diagnostic disable-next-line: deprecated
    return string.format(fmt, unpack(args))
end

--- @param action string
--- @return string
M.unrestricted_mode_header = function(action)
    return M.render(
        ":: Press %s to unrestricted mode",
        M.magenta,
        string.upper(action)
    )
end

--- @param action string
--- @return string
M.restricted_mode_header = function(action)
    return M.render(
        ":: Press %s to restricted mode",
        M.magenta,
        string.upper(action)
    )
end

--- @param action string
--- @return string
M.delete_buffer_header = function(action)
    return M.render(
        ":: Press %s to delete buffer",
        M.magenta,
        string.upper(action)
    )
end

--- @param action string
--- @return string
M.git_remote_branches_header = function(action)
    return M.render(
        ":: Press %s to remote mode",
        M.magenta,
        string.upper(action)
    )
end

--- @param action string
--- @return string
M.git_local_branches_header = function(action)
    return M.render(
        ":: Press %s to local mode",
        M.magenta,
        string.upper(action)
    )
end

--- @param action string
--- @return string
M.git_all_commits_header = function(action)
    return M.render(":: Press %s to all mode", M.magenta, string.upper(action))
end

--- @param action string
--- @return string
M.git_buffer_commits_header = function(action)
    return M.render(
        ":: Press %s to buffer mode",
        M.magenta,
        string.upper(action)
    )
end

return M
