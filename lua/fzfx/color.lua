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
--- @return string|nil
local function csi(color, fg)
    local code = fg and 38 or 48
    local r, g, b = color:match("#(..)(..)(..)")
    if not r or not g or not b then
        log.debug(
            "|fzfx.color - csi| fallback, color:%s, fg:%s, result:nil",
            vim.inspect(color),
            vim.inspect(fg)
        )
        return nil
    end
    r = tonumber(r, 16)
    g = tonumber(g, 16)
    b = tonumber(b, 16)
    local result = string.format("%d;2;%d;%d;%d", code, r, g, b)
    log.debug(
        "|fzfx.color - csi| color:%s, fg:%s, result:%s",
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
    if type(fg) == "string" and string.len(fg) > 0 then
        local fgfmt = csi(fg --[[@as string]], true)
        if type(fgfmt) == "string" and string.len(fgfmt) > 0 then
            local result = string.format("[%sm%s[0m", fgfmt, text)
            log.debug(
                "|fzfx.color - ansi| text:%s, name:%s, group:%s, fg:%s, fgfmt:%s, result:%s",
                vim.inspect(text),
                vim.inspect(name),
                vim.inspect(group),
                vim.inspect(fg),
                vim.inspect(fgfmt),
                vim.inspect(result)
            )
            return result
        end
    end
    local fgfmt = AnsiCode[name]
    local result = string.format("[%sm%s[m", fgfmt, text)
    log.debug(
        "|fzfx.color - ansi| text:%s, name:%s, group:%s, fg:%s, fgfmt:%s, result:%s",
        vim.inspect(text),
        vim.inspect(name),
        vim.inspect(group),
        vim.inspect(fg),
        vim.inspect(fgfmt),
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
    return ansi(text, "green", "Identifier")
end

local function yellow(text)
    return ansi(text, "yellow", "String")
end

local function blue(text)
    return ansi(text, "blue", "Constant")
end

local function magenta(text)
    return ansi(text, "magenta", "Operator")
end

local function cyan(text)
    return ansi(text, "cyan", "Number")
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
