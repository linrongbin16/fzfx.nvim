local DEBUG_ENABLE = tostring(vim.env._FZFX_NVIM_DEBUG_ENABLE):lower() == "1"

local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
    io.write(
        string.format("|fzfx.bin.files.provider| error! SELF_PATH is empty!")
    )
end
vim.opt.runtimepath:append(SELF_PATH)
local shell_helpers = require("fzfx.shell_helpers")

-- local ICON_ENABLE = tostring(vim.env._FZFX_NVIM_ICON_ENABLE):lower() == "1"
-- local DEVICONS_PATH = vim.env._FZFX_NVIM_DEVICON_PATH
-- local DEVICONS = nil
-- if
--     ICON_ENABLE
--     and type(DEVICONS_PATH) == "string"
--     and string.len(DEVICONS_PATH) > 0
-- then
--     vim.opt.runtimepath:append(DEVICONS_PATH)
--     DEVICONS = require("nvim-web-devicons")
-- end
-- shell_helpers.log_debug(
--     "|fzfx.shell_helpers| ICON_ENABLE:%s, DEVICONS_PATH:%s",
--     vim.inspect(ICON_ENABLE),
--     vim.inspect(DEVICONS_PATH)
-- )
-- shell_helpers.log_debug(
--     "|fzfx.shell_helpers| DEVICONS:%s",
--     vim.inspect(DEVICONS)
-- )

local provider = _G.arg[1]

if DEBUG_ENABLE then
    io.write(string.format("DEBUG provider:[%s]\n", provider))
    -- io.write(
    --     string.format("DEBUG shell_helpers:%s\n", vim.inspect(shell_helpers))
    -- )
end

-- local function render_line_with_icon(line)
--     if DEVICONS ~= nil then
--         local ext = vim.fn.fnamemodify(line, ":e")
--         local icon, color = DEVICONS.get_icon_color(line, ext)
--         if DEBUG_ENABLE then
--             shell_helpers.log_debug(
--                 "|fzfx.shell_helpers - render_line_with_icon| line:%s, ext:%s, icon:%s, color:%s\n",
--                 vim.inspect(line),
--                 vim.inspect(ext),
--                 vim.inspect(icon),
--                 vim.inspect(color)
--             )
--         end
--         if type(icon) == "string" and string.len(icon) > 0 then
--             local colorfmt = shell_helpers.color_csi(color, true)
--             if colorfmt then
--                 return string.format("[%sm%s[0m %s", colorfmt, icon, line)
--             else
--                 return string.format("%s %s", icon, line)
--             end
--         else
--             return string.format(" %s", line)
--         end
--     else
--         return line
--     end
-- end

local cmd = shell_helpers.get_provider_command(provider) --[[@as string]]
shell_helpers.log_debug("cmd:[%s]", cmd)

local p = io.popen(cmd)
-- shell_helpers.log_debug("p:[%s]", vim.inspect(p))
shell_helpers.log_ensure(
    p ~= nil,
    "error! failed to open pipe on cmd! %s",
    vim.inspect(cmd)
)
--- @diagnostic disable-next-line: need-check-nil
for line in p:lines("*line") do
    -- shell_helpers.log_debug("line:%s", vim.inspect(line))
    local line_with_icon = shell_helpers.render_line_with_icon(line)
    io.write(string.format("%s\n", line_with_icon))
end
--- @diagnostic disable-next-line: need-check-nil
p:close()
