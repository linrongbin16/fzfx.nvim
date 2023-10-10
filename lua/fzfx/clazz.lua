-- No Setup Need

--- @deprecated
local function instanceof(obj, clz)
    return type(obj) == "table"
        and type(clz) == "table"
        and getmetatable(obj) == clz
end

local M = {
    instanceof = instanceof,
}

return M
