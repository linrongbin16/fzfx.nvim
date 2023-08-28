--- @class Object
--- @field __class string

local Object = {
    __class = "object",
}

--- @param classname string?
function Object:new(classname)
    return vim.tbl_deep_extend("force", vim.deepcopy(Object), {
        __class = classname or "object",
    })
end

--- @param o any?
--- @return boolean
function Object:instanceof(o)
    return type(o) == "table" and o.__class == self.__class
end

local M = {
    Object = Object,
}

return M
