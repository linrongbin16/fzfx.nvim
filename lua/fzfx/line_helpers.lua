-- No Setup Need

local env = require("fzfx.env")
local utils = require("fzfx.utils")
local path = require("fzfx.path")

-- parse lines from fd, find, etc.
--- @param line string
--- @param opts {no_icon:boolean?}?
--- @return string
local function parse_find(line, opts)
    local filename = nil
    if (type(opts) == "table" and opts.no_icon) or not env.icon_enable() then
        filename = line
    else
        local first_icon_pos = utils.string_find(line, " ")
        assert(type(first_icon_pos) == "number")
        filename = line:sub(first_icon_pos + 1)
    end
    return vim.fn.expand(path.normalize(filename))
end

-- parse lines from rg, grep, etc.
--- @param line string
--- @param opts {no_icon:boolean?,delimiter:string?,filename_pos:integer?,lineno_pos:integer?,column_pos:integer?}?
--- @return {filename:string,lineno:integer,column:integer?}
local function parse_grep(line, opts)
    local delimiter = (
        type(opts) == "table"
        and type(opts.delimiter) == "string"
        and string.len(opts.delimiter) > 0
    )
            and opts.delimiter
        or ":"
    local filename_pos = (
        type(opts) == "table" and type(opts.filename_pos) == "number"
    )
            and opts.filename_pos
        or 1
    local lineno_pos = (
        type(opts) == "table" and type(opts.lineno_pos) == "number"
    )
            and opts.lineno_pos
        or 2
    local column_pos = (
        type(opts) == "table" and type(opts.column_pos) == "number"
    )
            and opts.column_pos
        or 3
    local splits = utils.string_split(line, delimiter)
    local filename = parse_find(splits[filename_pos], opts)
    local lineno = tonumber(splits[lineno_pos])
    local column = #splits >= column_pos and tonumber(splits[column_pos]) or nil
    return { filename = filename, lineno = lineno, column = column }
end

-- parse lines from ls, eza, exa, etc.
--
-- The `ls -lh` output looks like:
--
-- ```
-- total 91K
-- -rw-r--r--   1 linrongbin Administrators 1.1K Jul  9 14:35 LICENSE
-- -rw-r--r--   1 linrongbin Administrators 6.2K Sep 28 22:26 README.md
-- drwxr-xr-x   2 linrongbin Administrators 4.0K Sep 30 21:55 deps
-- -rw-r--r--   1 linrongbin Administrators  585 Jul 22 14:26 init.vim
-- ```
--
-- The file name starts from the 8th space.
--
-- The `eza -lh` (`exa -lh`) output looks like:
--
-- ```
-- Mode  Size Date Modified Name
-- d----    - 30 Sep 21:55  deps
-- -a---  585 22 Jul 14:26  init.vim
-- -a--- 6.4k 30 Sep 21:55  install.ps1
-- -a--- 5.3k 23 Sep 13:43  install.sh
-- ```
--
-- So file name starts from the 5th space.
--
--- @param line string
--- @param start_pos integer
--- @return string
local function parse_ls(line, start_pos)
    local pos = 1
    for i = 1, start_pos do
        pos = utils.string_find(line, " ", pos) --[[@as integer]]
        assert(type(pos) == "number")
        while
            pos + 1 <= #line
            and string.byte(line, pos + 1) == string.byte(" ")
        do
            pos = pos + 1
        end
        pos = pos + 1
    end
    return vim.fn.expand(path.normalize(line:sub(pos)))
end

--- @param line string
--- @return string
local function parse_filename(line)
    local filename = nil
    if env.icon_enable() then
        local splits = utils.string_split(line, " ")
        filename = splits[#splits]
    else
        filename = line
    end
    return path.normalize(filename)
end

--- @alias PathLineParsedResult {filename:string,lineno:string?,column:string?}
--- @param line string
--- @param delimiter string?
--- @param file_pos integer?
--- @param lineno_pos integer?
--- @param colno_pos integer?
--- @return PathLineParsedResult
local function parse_path_line(line, delimiter, file_pos, lineno_pos, colno_pos)
    local filename = nil
    local lineno = nil
    local column = nil
    if type(delimiter) == "string" and string.len(delimiter) > 0 then
        local parts = utils.string_split(line, delimiter)
        filename = parse_filename(
            parts[file_pos > 0 and file_pos or (#parts + file_pos + 1)]
        )
        if type(lineno_pos) == "number" then
            lineno = tonumber(
                parts[lineno_pos > 0 and lineno_pos or (#parts + lineno_pos + 1)]
            )
        end
        if type(colno_pos) == "number" then
            column = tonumber(
                parts[colno_pos > 0 and colno_pos or (#parts + colno_pos + 1)]
            )
        end
    else
        filename = parse_filename(line)
    end
    return { filename = filename, lineno = lineno, column = column }
end

--- @class PathLine
--- @field source string
--- @field filename string
--- @field lineno integer?
--- @field column integer?
local PathLine = {}

--- @param line string
--- @param delimiter string?
--- @param file_pos integer?
--- @param lineno_pos integer?
--- @param colno_pos integer?
--- @return PathLine
function PathLine:new(line, delimiter, file_pos, lineno_pos, colno_pos)
    local parsed =
        parse_path_line(line, delimiter, file_pos, lineno_pos, colno_pos)
    local o = {
        line = line,
        filename = parsed.filename,
        lineno = parsed.lineno,
        column = parsed.column,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

local M = {
    parse_find = parse_find,
    parse_grep = parse_grep,
    parse_ls = parse_ls,
    parse_filename = parse_filename,
    parse_path_line = parse_path_line,
    PathLine = PathLine,
}

return M
