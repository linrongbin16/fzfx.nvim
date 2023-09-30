-- No Setup Need

local env = require("fzfx.env")
local utils = require("fzfx.utils")
local path = require("fzfx.path")

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
    parse_filename = parse_filename,
    parse_path_line = parse_path_line,
    PathLine = PathLine,
}

return M
