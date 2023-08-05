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
    local family = gui and "gui" or "cterm"
    local pattern = gui and "^#[%l%d]+" or "^[%d]+$"
    local code =
        vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(group)), attr, family)
    if string.find(code, pattern) then
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
--- @return string|nil
local function csi(color, fg)
    local code = fg and 38 or 48
    local r, g, b = color:match("#(..)(..)(..)")
    if r and g and b then
        r = tonumber(r, 16)
        g = tonumber(g, 16)
        b = tonumber(b, 16)
        local result = string.format("%d;2;%d;%d;%d", code, r, g, b)
        log.debug(
            "|fzfx.color - csi| rgb, color:%s, fg:%s, result:%s",
            vim.inspect(color),
            vim.inspect(fg),
            vim.inspect(result)
        )
        return result
    else
        local result = string.format("%d;5;%s", code, color)
        log.debug(
            "|fzfx.color - csi| non-rgb, color:%s, fg:%s, result:%s",
            vim.inspect(color),
            vim.inspect(fg),
            vim.inspect(result)
        )
        return result
    end
end

--- @param text string
--- @param name string
--- @param group string
--- @return string
local function ansi(text, name, group)
    local fg = get_color("fg", group)
    local fgcolor = nil
    if type(fg) == "string" then
        fgcolor = csi(fg, true)
        log.debug(
            "|fzfx.color - ansi| rgb, text:%s, name:%s, group:%s, fg:%s, fgcolor:%s",
            vim.inspect(text),
            vim.inspect(name),
            vim.inspect(group),
            vim.inspect(fg),
            vim.inspect(fgcolor)
        )
    else
        fgcolor = AnsiCode[name]
        log.debug(
            "|fzfx.color - ansi| ansi, text:%s, name:%s, group:%s, fg:%s, fgcolor:%s",
            vim.inspect(text),
            vim.inspect(name),
            vim.inspect(group),
            vim.inspect(fg),
            vim.inspect(fgcolor)
        )
    end

    local bg = get_color("bg", group)
    local finalcolor = nil
    if type(bg) == "string" then
        local bgcolor = csi(bg, false)
        log.debug(
            "|fzfx.color - ansi| rgb, text:%s, name:%s, group:%s, bg:%s, bgcolor:%s",
            vim.inspect(text),
            vim.inspect(name),
            vim.inspect(group),
            vim.inspect(bg),
            vim.inspect(bgcolor)
        )
        finalcolor = string.format("%s;%s", fgcolor, bgcolor)
    else
        log.debug(
            "|fzfx.color - ansi| ansi, text:%s, name:%s, group:%s, bg:%s",
            vim.inspect(text),
            vim.inspect(name),
            vim.inspect(group),
            vim.inspect(bg)
        )
        finalcolor = fgcolor
    end

    log.debug(
        "|fzfx.color - ansi| ansi, finalcolor:%s",
        vim.inspect(text),
        vim.inspect(name),
        vim.inspect(group),
        vim.inspect(bg)
    )
    return string.format("[%sm%s[0m", finalcolor, text)
end

local M = {}

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
end

--- @param fmt string
--- @param renderer fun(color:string,hl:string|nil):string
--- @return string
local function render(fmt, renderer, ...)
    local args = {}
    for _, a in ipairs({ ... }) do
        table.insert(args, renderer(a))
    end
    return string.format(fmt, unpack(args))
end

M.unrestricted_mode_header = function(action)
    return render(
        ":: Press %s to unrestricted mode",
        M.magenta,
        string.upper(action)
    )
end

M.restricted_mode_header = function(action)
    return render(
        ":: Press %s to restricted mode",
        M.magenta,
        string.upper(action)
    )
end

return M
