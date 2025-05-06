local M = {}

-- os
M.IS_WINDOWS = vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0
M.IS_MACOS = vim.fn.has("mac") > 0
M.IS_BSD = vim.fn.has("bsd") > 0
M.IS_LINUX = not M.IS_WINDOWS
  and not M.IS_MACOS
  and not M.IS_BSD
  and (vim.fn.has("linux") > 0 or vim.fn.has("unix") > 0)

-- cli

-- fzf
M.HAS_FZF = vim.fn.executable("fzf") > 0 or vim.fn.exists("*fzf#exec") > 0
M.FZF = vim.fn.executable("fzf") > 0 and "fzf"
  or (vim.fn.exists("*fzf#exec") > 0 and vim.fn["fzf#exec"]() or "fzf")

-- bat
M.HAS_BAT = vim.fn.executable("batcat") > 0 or vim.fn.executable("bat") > 0
M.BAT = vim.fn.executable("batcat") > 0 and "batcat" or "bat"

-- cat
M.HAS_CAT = vim.fn.executable("cat") > 0
M.CAT = "cat"

-- ripgrep(rg)
M.HAS_RG = vim.fn.executable("rg") > 0
M.RG = "rg"

-- grep/ggrep
M.HAS_GNU_GREP = ((M.IS_WINDOWS or M.IS_LINUX) and vim.fn.executable("grep") > 0)
  or vim.fn.executable("ggrep") > 0
M.GNU_GREP = vim.fn.executable("ggrep") > 0 and "ggrep" or "grep"
M.HAS_GREP = vim.fn.executable("ggrep") > 0 or vim.fn.executable("grep") > 0
M.GREP = vim.fn.executable("ggrep") > 0 and "ggrep" or "grep"

-- fd-find(fd)
M.HAS_FD = vim.fn.executable("fdfind") > 0 or vim.fn.executable("fd") > 0
M.FD = vim.fn.executable("fdfind") > 0 and "fdfind" or "fd"

-- find/gfind
M.HAS_FIND = vim.fn.executable("gfind") > 0 or vim.fn.executable("find") > 0
M.FIND = vim.fn.executable("gfind") > 0 and "gfind" or "find"

-- lsd
M.HAS_LSD = vim.fn.executable("lsd") > 0
M.LSD = "lsd"

-- eza/exa
M.HAS_EZA = vim.fn.executable("exa") > 0 or vim.fn.executable("eza") > 0
M.EZA = vim.fn.executable("eza") > 0 and "eza" or "exa"

-- ls
M.HAS_LS = vim.fn.executable("ls") > 0
M.LS = "ls"

-- git
M.HAS_GIT = vim.fn.executable("git") > 0
M.GIT = "git"

-- git-delta
M.HAS_DELTA = vim.fn.executable("delta") > 0
M.DELTA = "delta"

-- echo
M.HAS_ECHO = vim.fn.executable("echo") > 0
M.ECHO = "echo"

-- curl
M.HAS_CURL = vim.fn.executable("curl") > 0
M.CURL = "curl"

-- neovim version
M.NVIM_VERSION_0_11_0 = vim.fn.has("nvim-0.11.0") > 0

return M
