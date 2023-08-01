local log = require("fzfx.log")

local AnsiCode = {
    black = 30,
    red = 31,
    green = 32,
    yellow = 33,
    blue = 34,
    magenta = 35,
    cyan = 36,
}

--- @param attr "fg"|"bg"
--- @param group string
--- @return string|nil
local function get_color(attr, group)
    local gui = vim.fn.has("termguicolors") > 0 and vim.o.termguicolors
    local fam = gui and "gui" or "cterm"
    local pat = gui and "^#[%l%d]+" or "^[%d]+$"
    local code =
        vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(group)), attr, fam)
    if string.find(code, pat) then
        log.debug(
            "|fzfx.color - get_color| attr:%s, group:%s, code:%s",
            vim.inspect(attr),
            vim.inspect(group),
            vim.inspect(code)
        )
        return code
    end
    log.debug(
        "|fzfx.color - get_color| return nil, attr:%s, group:%s, code:%s",
        vim.inspect(attr),
        vim.inspect(group),
        vim.inspect(code)
    )
    return nil
end

--- @param color string
--- @param fg boolean
--- @return string
local function csi(color, fg)
    local prefix = fg and "38;" or "48;"
    if string.sub(color, 1, 1) == "#" then
        local splits = {
            vim.fn.str2nr(string.sub(color, 2, 2), 16),
            vim.fn.str2nr(string.sub(color, 4, 2), 16),
            vim.fn.str2nr(string.sub(color, 6, 2), 16),
        }
        local result =
            string.format("%s2;%s", prefix, table.concat(splits, ";"))
        log.debug(
            "|fzfx.color - csi| color:%s, fg:%s, result:%s",
            vim.inspect(color),
            vim.inspect(fg),
            vim.inspect(result)
        )
        return result
    end
    local result = string.format("%s5;%s", prefix, color)
    log.debug(
        "|fzfx.color - csi| fallback, color:%s, fg:%s, result:%s",
        vim.inspect(color),
        vim.inspect(fg),
        vim.inspect(result)
    )
    return result
end

--- @param text string
--- @param name string
--- @param group string
--- @return string
local function ansi(text, name, group)
    local fg = get_color("fg", group)
    local bg = get_color("bg", group)
    local fgcolor = (fg == nil or string.len(fg) <= 0) and AnsiCode[name]
        or csi(fg --[[@as string]], true)
    local bgcolor = (bg == nil or string.len(bg) <= 0) and ""
        or string.format(";", csi(bg --[[@as string]], false))
    local color = fgcolor .. bgcolor
    -- NOTE: this is \x1b, not a whitespace
    local result = string.format("[%sm%s[m", color, text)
    log.debug(
        "|fzfx.color - ansi| text:%s, name:%s, group:%s, fg:%s, bg:%s, fgcolor:%s, bgcolor:%s, color:%s, result:%s",
        vim.inspect(text),
        vim.inspect(name),
        vim.inspect(group),
        vim.inspect(fg),
        vim.inspect(bg),
        vim.inspect(fgcolor),
        vim.inspect(bgcolor),
        vim.inspect(color),
        vim.inspect(result)
    )
    return result
end

local function black(text)
    return ansi(text, "black", "Comment")
end

local function red(text)
    return ansi(text, "red", "Exception")
end

local function green(text)
    return ansi(text, "green", "Constant")
end

local function yellow(text)
    return ansi(text, "yellow", "Number")
end

local function blue(text)
    return ansi(text, "blue", "Operator")
end

local function magenta(text)
    return ansi(text, "magenta", "Special")
end

local function cyan(text)
    return ansi(text, "cyan", "String")
end

local M = {
    black = black,
    red = red,
    green = green,
    yellow = yellow,
    blue = blue,
    magenta = magenta,
    cyan = cyan,
}

return M
