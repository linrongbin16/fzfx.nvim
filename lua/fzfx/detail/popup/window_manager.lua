-- PopupWindowManager {

--- @class fzfx.PopupWindowsManager
--- @field instances table<integer, fzfx.PopupWindow>
local PopupWindowsManager = {}

function PopupWindowsManager:new()
  local o = {
    instances = {},
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @param obj fzfx.PopupWindow
function PopupWindowsManager:add(obj)
  self.instances[obj:handle()] = obj
end

--- @param obj fzfx.PopupWindow
function PopupWindowsManager:remove(obj)
  self.instances[obj:handle()] = nil
end

function PopupWindowsManager:resize()
  for _, obj in pairs(self.instances) do
    if obj then
      vim.schedule(function()
        obj:resize()
      end)
    end
  end
end

-- PopupWindowManager }

local M = {
  PopupWindowsManager = PopupWindowsManager,
}

return M
