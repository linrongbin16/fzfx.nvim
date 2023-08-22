local log = require("fzfx.log")
local conf = require("fzfx.config")
local utils = require("fzfx.utils")

-- --- @class WindowContext
-- --- @field bufnr integer|nil
-- --- @field winnr integer|nil
-- --- @field tabnr integer|nil
--
-- --- @type WindowContext
-- local WindowContext = {
--     bufnr = nil,
--     winnr = nil,
--     tabnr = nil,
-- }
--
-- --- @param bufnr integer
-- --- @param winnr integer
-- --- @param tabnr integer
-- --- @return WindowContext
-- local function new_window_context(bufnr, winnr, tabnr)
--     local ctx = vim.tbl_deep_extend("force", vim.deepcopy(WindowContext), {
--         bufnr = bufnr,
--         winnr = winnr,
--         tabnr = tabnr,
--     })
--     return ctx
-- end
--
-- -- First in, last out
-- -- Last in, first out
-- --- @class WindowContextStack
-- --- @field size integer
-- --- @field stack WindowContext[]
-- local WindowContextStack = {
--     size = 0,
--     stack = {},
-- }
--
-- function WindowContextStack:push()
--     local current_bufnr = vim.api.nvim_get_current_buf()
--     local current_winnr = vim.api.nvim_get_current_win()
--     local current_tabnr = vim.api.nvim_get_current_tabpage()
--     local ctx = new_window_context(current_bufnr, current_winnr, current_tabnr)
--     table.insert(self.stack, ctx)
--     self.size = self.size + 1
--     log.debug(
--         "|fzfx.popup - WindowContextStack:push| self:%s",
--         vim.inspect(self)
--     )
--     return ctx
-- end
--
-- function WindowContextStack:top()
--     if self.size <= 0 then
--         return nil
--     end
--     return self.stack[self.size]
-- end
--
-- function WindowContextStack:pop()
--     if self.size <= 0 then
--         return nil
--     end
--     local top = self:top()
--     table.remove(self.stack)
--     self.size = self.size - 1
--     return top
-- end
--
-- local Context = {
--     window_context_stack = nil,
-- }
--
-- local function get_window_context_stack()
--     if Context.window_context_stack == nil then
--         Context.window_context_stack =
--             vim.tbl_deep_extend("force", vim.deepcopy(WindowContextStack), {
--                 size = 0,
--                 stack = {},
--             })
--     end
--     return Context.window_context_stack
-- end

--- @class SavedWindowContext
--- @class bufnr integer?
--- @class tabnr integer?
--- @class winnr integer?
local SavedWindowContext = {
    bufnr = nil,
    tabnr = nil,
    winnr = nil,
}

function SavedWindowContext:new()
    local saved =
        vim.tbl_deep_extend("force", vim.deepcopy(SavedWindowContext), {
            bufnr = vim.api.nvim_get_current_buf(),
            winnr = vim.api.nvim_get_current_win(),
            tabnr = vim.api.nvim_get_current_tabpage(),
        })
    log.debug(
        "|fzfx.popup - SavedWindowContext:new| saved:%s",
        vim.inspect(saved)
    )
    return saved --[[@as SavedWindowContext]]
end

function SavedWindowContext:restore()
    log.debug(
        "|fzfx.popup - SavedWindowContext:restore| self:%s",
        vim.inspect(self)
    )
    if vim.api.nvim_tabpage_is_valid(self.tabnr) then
        vim.api.nvim_set_current_tabpage(self.tabnr)
    else
        log.debug(
            "error! cannot restore to invalid previous tabpage! %s",
            vim.inspect(self.tabnr)
        )
    end
    if vim.api.nvim_win_is_valid(self.winnr) then
        vim.api.nvim_set_current_win(self.winnr)
    else
        log.debug(
            "error! cannot restore to invalid previous window! %s",
            vim.inspect(self.winnr)
        )
    end
end

--- @class Popup
--- @field saved_window_context SavedWindowContext?
--- @field bufnr integer|nil
--- @field winnr integer|nil
local Popup = {
    saved_window_context = nil,
    bufnr = nil,
    winnr = nil,
}

--- @class PopupOpts
--- @field relative "editor"|"win"|nil
--- @field width integer|nil
--- @field height integer|nil
--- @field row integer|nil
--- @field col integer|nil
--- @field style "minimal"|nil
--- @field border "none"|"single"|"double"|"rounded"|"solid"|"shadow"|nil
--- @field zindex integer|nil
local PopupOpts = {
    relative = nil,
    width = nil,
    height = nil,
    row = nil,
    col = nil,
    style = nil,
    border = nil,
    zindex = nil,
}

local function safe_range(left, value, right)
    return math.min(math.max(left, value), right)
end

--- @param win_opts Configs
--- @return PopupOpts
local function make_popup_window_opts(win_opts)
    --- @type integer
    local columns = vim.o.columns
    --- @type integer
    local lines = vim.o.lines
    --- @type integer
    local width = safe_range(
        3,
        win_opts.width > 1 and win_opts.width
            or math.floor(columns * win_opts.width),
        columns
    )
    --- @type integer
    local height = safe_range(
        3,
        win_opts.height > 1 and win_opts.height
            or math.floor(lines * win_opts.height),
        lines
    )
    --- @type integer
    local row = nil
    if
        (win_opts.row > -1 and win_opts.row < -0.5)
        or (win_opts.row > 0.5 and win_opts.row < 1)
    then
        log.throw(
            "error! invalid option win_opts.row '%s'!",
            vim.inspect(win_opts.row)
        )
    else
        local base_row = math.floor((lines - height) * 0.5)
        if win_opts.row >= 0 then
            local shift_row = win_opts.row < 1
                    and math.floor((lines - height) * win_opts.row)
                or win_opts.row
            row = safe_range(0, base_row + shift_row, lines - height)
        else
            local shift_row = win_opts.row > -1
                    and math.ceil((lines - height) * win_opts.row)
                or win_opts.row
            row = safe_range(0, base_row + shift_row, lines - height)
        end
    end
    --- @type integer
    local col = nil
    if
        (win_opts.col > -1 and win_opts.col < -0.5)
        or (win_opts.col > 0.5 and win_opts.col < 1)
    then
        log.throw(
            "error! invalid option win_opts.col '%s'!",
            vim.inspect(win_opts.col)
        )
    else
        local base_col = math.floor((columns - width) * 0.5)
        if win_opts.col >= 0 then
            local shift_col = win_opts.col < 1
                    and math.floor((columns - width) * win_opts.col)
                or win_opts.col
            col = safe_range(0, base_col + shift_col, columns - width)
        else
            local shift_col = win_opts.col > -1
                    and math.ceil((columns - width) * win_opts.col)
                or win_opts.col
            col = safe_range(0, base_col + shift_col, columns - width)
        end
    end

    --- @type PopupOpts
    local popup_opts = vim.tbl_deep_extend("force", vim.deepcopy(PopupOpts), {
        anchor = "NW",
        relative = "editor",
        width = width,
        height = height,
        -- start point on NW
        row = row,
        col = col,
        style = "minimal",
        border = win_opts.border,
        zindex = win_opts.zindex,
    })
    log.debug(
        "|fzfx.popup - make_popup_window_opts| (origin) win_opts:%s, popup_win_opts:%s",
        vim.inspect(win_opts),
        vim.inspect(popup_opts)
    )
    return popup_opts
end

--- @param win_opts PopupOpts|nil
--- @return Popup
function Popup:new(win_opts)
    -- check executable: nvim, fzf
    require("fzfx.shell").nvim_exec()
    require("fzfx.shell").fzf_exec()

    -- save current window context
    local saved_window_context = SavedWindowContext:new()

    -- local win_stack = get_window_context_stack() --[[@as WindowContextStack]]
    -- assert(
    --     win_stack ~= nil,
    --     "|fzfx.popup - new_popup_window| win_stack cannot be nil"
    -- )
    -- win_stack:push()

    --- @type integer
    local bufnr = vim.api.nvim_create_buf(false, true)
    -- setlocal nospell bufhidden=wipe nobuflisted nonumber
    -- setft=fzf
    utils.set_buf_option(bufnr, "spell", false)
    utils.set_buf_option(bufnr, "bufhidden", "wipe")
    utils.set_buf_option(bufnr, "buflisted", false)
    utils.set_buf_option(bufnr, "number", false)
    utils.set_buf_option(bufnr, "filetype", "fzf")

    --- @type PopupOpts
    local merged_win_opts = vim.tbl_deep_extend(
        "force",
        vim.deepcopy(conf.get_config().popup.win_opts),
        vim.deepcopy(win_opts) or {}
    )
    local popup_opts = make_popup_window_opts(merged_win_opts)

    --- @type integer
    local winnr = vim.api.nvim_open_win(bufnr, true, popup_opts)

    --- set winhighlight='Pmenu:,Normal:Normal'
    --- set colorcolumn=''
    utils.set_win_option(winnr, "winhighlight", "Pmenu:,Normal:Normal")
    utils.set_win_option(winnr, "colorcolumn", "")

    --- @type Popup
    local ppp = vim.tbl_deep_extend("force", vim.deepcopy(Popup), {
        saved_window_context = saved_window_context,
        bufnr = bufnr,
        winnr = winnr,
    })

    return ppp
end

function Popup:close()
    log.debug("|fzfx.popup - Popup:close| self:%s", vim.inspect(self))

    if vim.api.nvim_win_is_valid(self.winnr) then
        vim.api.nvim_win_close(self.winnr, true)
    else
        log.debug(
            "error! cannot close invalid popup window! %s",
            vim.inspect(self.winnr)
        )
    end

    ---@diagnostic disable-next-line: undefined-field
    self.saved_window_context:restore()
end

local M = {
    Popup = Popup,
}

return M
