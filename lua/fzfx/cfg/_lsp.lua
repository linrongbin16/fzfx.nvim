local term_color = require("fzfx.commons.color.term")

local consts = require("fzfx.lib.constants")

local M = {}

-- Simulate rg's filepath color, see:
-- * https://github.com/BurntSushi/ripgrep/discussions/2605#discussioncomment-6881383
-- * https://github.com/BurntSushi/ripgrep/blob/d596f6ebd035560ee5706f7c0299c4692f112e54/crates/printer/src/color.rs#L14
M.LSP_FILENAME_COLOR = consts.IS_WINDOWS and term_color.cyan or term_color.magenta

return M
