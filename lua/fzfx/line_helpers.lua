-- No Setup Need

local constants = require("fzfx.constants")
local env = require("fzfx.env")
local utils = require("fzfx.utils")
local path = require("fzfx.path")

-- parse lines from fd/find.
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

-- parse lines from grep.
--- @param line string
--- @param opts {no_icon:boolean?}?
--- @return {filename:string,lineno:integer}
local function parse_grep(line, opts)
    local splits = utils.string_split(line, ":")
    local filename = parse_find(splits[1], opts)
    local lineno = tonumber(splits[2])
    return { filename = filename, lineno = lineno }
end

-- parse lines from rg.
--- @param line string
--- @param opts {no_icon:boolean?}?
--- @return {filename:string,lineno:integer,column:integer}
local function parse_rg(line, opts)
    local splits = utils.string_split(line, ":")
    local filename = parse_find(splits[1], opts)
    local lineno = tonumber(splits[2])
    local column = tonumber(splits[3])
    return { filename = filename, lineno = lineno, column = column }
end

-- parse lines from ls/eza/exa.
--
-- The `ls -lh` output looks like:
--
-- windows:
-- ```
-- total 31K
-- -rwxrwxrwx 1 somebody somegroup  150 Aug  3 21:29 .editorconfig
-- drwxrwxrwx 1 somebody somegroup    0 Oct  8 12:02 .github
-- -rwxrwxrwx 1 somebody somegroup  363 Aug 30 15:51 .gitignore
-- -rwxrwxrwx 1 somebody somegroup  124 Sep 18 23:56 .luacheckrc
-- -rwxrwxrwx 1 somebody somegroup   68 Sep 11 21:58 .luacov
-- ```
--
-- macOS:
-- ```
-- total 184
-- -rw-r--r--   1 rlin  staff   1.0K Aug 28 12:39 LICENSE
-- -rw-r--r--   1 rlin  staff    27K Oct  8 11:37 README.md
-- drwxr-xr-x   3 rlin  staff    96B Aug 28 12:39 autoload
-- drwxr-xr-x   4 rlin  staff   128B Sep 22 10:11 bin
-- -rw-r--r--   1 rlin  staff   120B Sep  5 14:14 codecov.yml
-- ```
--
-- The file name starts from the 8th space.
--
-- The `eza -lh` (`exa -lh`) output looks like:
--
-- windows:
-- ```
-- Mode  Size Date Modified Name
-- d----    - 30 Sep 21:55  deps
-- -a---  585 22 Jul 14:26  init.vim
-- -a--- 6.4k 30 Sep 21:55  install.ps1
-- -a--- 5.3k 23 Sep 13:43  install.sh
-- ```
--
-- The file name starts from the 5th space.
--
-- while macOS/linux is different:
-- ```
-- Permissions Size User Date Modified Name
-- drwxr-xr-x     - linrongbin 28 Aug 12:39  autoload
-- drwxr-xr-x     - linrongbin 22 Sep 10:11  bin
-- .rw-r--r--   120 linrongbin  5 Sep 14:14  codecov.yml
-- .rw-r--r--  1.1k linrongbin 28 Aug 12:39  LICENSE
-- drwxr-xr-x     - linrongbin  8 Oct 09:14  lua
-- .rw-r--r--   28k linrongbin  8 Oct 11:37  README.md
-- drwxr-xr-x     - linrongbin  8 Oct 11:44  test
-- .rw-r--r--   28k linrongbin  8 Oct 12:10  test1-README.md
-- .rw-r--r--   28k linrongbin  8 Oct 12:10  test2-README.md
-- ```
--
-- The file name starts from the 6th space.
--
--- @param start_pos integer
--- @return fun(line:string):string
local function make_parse_ls(start_pos)
    --- @param line string
    --- @return string
    local function impl(line)
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
        return vim.fn.expand(path.normalize(vim.trim(line:sub(pos))))
    end
    return impl
end

local parse_ls = make_parse_ls(8)
local parse_eza = constants.is_windows and make_parse_ls(5) or make_parse_ls(6)

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
    parse_rg = parse_rg,
    make_parse_ls = make_parse_ls,
    parse_ls = parse_ls,
    parse_eza = parse_eza,
    parse_filename = parse_filename,
    parse_path_line = parse_path_line,
    PathLine = PathLine,
}

return M
