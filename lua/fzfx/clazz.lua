--- @class Object
--- @field __classname string

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
        and type(o.__classname) == "string"
        and string.len(o.__classname) > 0
        and type(clz.__classname) == "string"
        and string.len(clz.__classname) > 0
        and o.__classname == clz.__classname
end

local M = {
    Clazz = Clazz,
}

return M
