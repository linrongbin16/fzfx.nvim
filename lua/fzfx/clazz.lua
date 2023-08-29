--- @class Object
--- @field __class string

local Clazz = {
    __classname = "object",
}

--- @param classname string
--- @param body table
function Clazz:implement(classname, body)
    local o = vim.tbl_deep_extend("force", vim.deepcopy(Clazz), {
        __classname = classname,
    })
    return vim.tbl_deep_extend("force", vim.deepcopy(o), body or nil)
end

--- @param o any?
--- @param clz any?
--- @return boolean
function Clazz:instanceof(o, clz)
    return type(o) == "table"
        and type(clz) == "table"
        and type(o.__class) == "string"
        and string.len(o.__class) > 0
        and type(clz.__class) == "string"
        and string.len(clz.__class) > 0
end

local M = {
    Clazz = Clazz,
}

return M
