-- test case: https://github.com/linrongbin16/fzfx.nvim/issues/317

vim.o.number = true
vim.o.autoread = true
vim.o.autowrite = true
vim.o.swapfile = false
vim.o.confirm = true
vim.o.termguicolors = true

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

local M = {}

local function file_previewer_rg(line)
    local line_helpers = require("fzfx.line_helpers")
    local parsed = line_helpers.parse_grep(line)
    local style = "numbers,changes"
    if
        type(vim.env["BAT_STYLE"]) == "string"
        and string.len(vim.env["BAT_STYLE"]) > 0
    then
        style = vim.env["BAT_STYLE"]
    end
    local theme = "base16"
    if
        type(vim.env["BAT_THEME"]) == "string"
        and string.len(vim.env["BAT_THEME"]) > 0
    then
        theme = vim.env["BAT_THEME"]
    end
    -- "%s --style=%s --theme=%s --color=always --pager=never --highlight-line=%s -- %s"
    return {
        vim.fn.executable("batcat") > 0 and "batcat" or "bat",
        "--style=" .. style,
        "--theme=" .. theme,
        "--color=always",
        "--pager=never",
        "--highlight-line=" .. parsed.lineno,
        "--",
        parsed.filename,
    }
end

local function merge_query_options(merged, option)
    local option_splits =
        vim.split(option, " ", { plain = true, trimempty = true })
    for _, o in ipairs(option_splits) do
        if type(o) == "string" and string.len(o) > 0 then
            table.insert(merged, o)
        end
    end
    return merged
end

local live_grep_curr = {
    commands = {
        -- normal
        {
            name = "FzfxLiveGrep",
            feed = "args",
            opts = {
                bang = true,
                nargs = "*",
                desc = "Live grep",
            },
            default_provider = "restricted_mode",
        },
        {
            name = "FzfxLiveGrepU",
            feed = "args",
            opts = {
                bang = true,
                nargs = "*",
                desc = "Live grep unrestricted",
            },
            default_provider = "unrestricted_mode",
        },
        {
            name = "FzfxLiveGrepB",
            feed = "args",
            opts = {
                bang = true,
                nargs = "*",
                desc = "Live grep only on current buffer",
            },
            default_provider = "buffer_mode",
        },
        -- visual
        {
            name = "FzfxLiveGrepV",
            feed = "visual",
            opts = {
                bang = true,
                range = true,
                desc = "Live grep by visual select",
            },
            default_provider = "restricted_mode",
        },
        {
            name = "FzfxLiveGrepUV",
            feed = "visual",
            opts = {
                bang = true,
                range = true,
                desc = "Live grep unrestricted by visual select",
            },
            default_provider = "unrestricted_mode",
        },
        {
            name = "FzfxLiveGrepBV",
            feed = "visual",
            opts = {
                bang = true,
                nargs = "*",
                desc = "Live grep only on current buffer by visual select",
            },
            default_provider = "buffer_mode",
        },
        -- cword
        {
            name = "FzfxLiveGrepW",
            feed = "cword",
            opts = {
                bang = true,
                desc = "Live grep by cursor word",
            },
            default_provider = "restricted_mode",
        },
        {
            name = "FzfxLiveGrepUW",
            feed = "cword",
            opts = {
                bang = true,
                desc = "Live grep unrestricted by cursor word",
            },
            default_provider = "unrestricted_mode",
        },
        {
            name = "FzfxLiveGrepBW",
            feed = "cword",
            opts = {
                bang = true,
                nargs = "*",
                desc = "Live grep only on current buffer by cursor word",
            },
            default_provider = "buffer_mode",
        },
        -- put
        {
            name = "FzfxLiveGrepP",
            feed = "put",
            opts = {
                bang = true,
                desc = "Live grep by yank text",
            },
            default_provider = "restricted_mode",
        },
        {
            name = "FzfxLiveGrepUP",
            feed = "put",
            opts = {
                bang = true,
                desc = "Live grep unrestricted by yank text",
            },
            default_provider = "unrestricted_mode",
        },
        {
            name = "FzfxLiveGrepBP",
            feed = "put",
            opts = {
                bang = true,
                nargs = "*",
                desc = "Live grep only on current buffer by yank text",
            },
            default_provider = "buffer_mode",
        },
    },
    providers = {
        restricted_mode = {
            key = "ctrl-r",
            provider = function(query)
                local parsed_query =
                    require("fzfx.utils").parse_flag_query(query or "")
                local content = parsed_query[1]
                local option = parsed_query[2]

                if type(option) == "string" and string.len(option) > 0 then
                    -- "rg --column -n --no-heading --color=always -S %s -- %s"
                    local args = {
                        "rg",
                        "--column",
                        "-n",
                        "--no-heading",
                        "--color=always",
                        "-S",
                    }
                    args = merge_query_options(args, option)
                    table.insert(args, "--")
                    table.insert(args, content)
                    return args
                else
                    -- "rg --column -n --no-heading --color=always -S -- %s"
                    return {
                        "rg",
                        "--column",
                        "-n",
                        "--no-heading",
                        "--color=always",
                        "-S",
                        "--",
                        content,
                    }
                end
            end,
            provider_type = "command_list",
            line_opts = {
                prepend_icon_by_ft = true,
                prepend_icon_path_delimiter = ":",
                prepend_icon_path_position = 1,
            },
        },
        unrestricted_mode = {
            key = "ctrl-u",
            provider = function(query)
                local parsed_query =
                    require("fzfx.utils").parse_flag_query(query or "")
                local content = parsed_query[1]
                local option = parsed_query[2]

                if type(option) == "string" and string.len(option) > 0 then
                    -- "rg --column -n --no-heading --color=always -S -uu %s -- %s"
                    local args = {
                        "rg",
                        "--column",
                        "-n",
                        "--no-heading",
                        "--color=always",
                        "-S",
                        "-uu",
                    }
                    args = merge_query_options(args, option)
                    table.insert(args, "--")
                    table.insert(args, content)
                    return args
                else
                    -- "rg --column -n --no-heading --color=always -S -uu -- %s"
                    return {
                        "rg",
                        "--column",
                        "-n",
                        "--no-heading",
                        "--color=always",
                        "-S",
                        "-uu",
                        "--",
                        content,
                    }
                end
            end,
            provider_type = "command_list",
            line_opts = {
                prepend_icon_by_ft = true,
                prepend_icon_path_delimiter = ":",
                prepend_icon_path_position = 1,
            },
        },
        buffer_mode = {
            key = "ctrl-o",
            provider = function(query, context)
                local utils = require("fzfx.utils")
                local log = require("fzfx.log")
                local path = require("fzfx.path")

                local parsed_query = utils.parse_flag_query(query or "")
                local content = parsed_query[1]
                local option = parsed_query[2]
                if not utils.is_buf_valid(context.bufnr) then
                    log.echo(
                        log.LogLevels.INFO,
                        "not valid buffer(%s).",
                        vim.inspect(context.bufnr)
                    )
                    return nil
                end
                local current_bufpath =
                    path.reduce(vim.api.nvim_buf_get_name(context.bufnr))
                if type(option) == "string" and string.len(option) > 0 then
                    -- "rg --column -n --no-heading --color=always -S -uu %s -- %s"
                    local args = {
                        "rg",
                        "--column",
                        "-n",
                        "--no-heading",
                        "--color=always",
                        "-S",
                        "-g",
                        current_bufpath,
                    }
                    args = merge_query_options(args, option)
                    table.insert(args, "--")
                    table.insert(args, content)
                    return args
                else
                    -- "rg --column -n --no-heading --color=always -S -uu -- %s"
                    return {
                        "rg",
                        "--column",
                        "-n",
                        "--no-heading",
                        "--color=always",
                        "-S",
                        "-g",
                        current_bufpath,
                        "--",
                        content,
                    }
                end
            end,
            provider_type = "command_list",
            line_opts = {
                prepend_icon_by_ft = true,
                prepend_icon_path_delimiter = ":",
                prepend_icon_path_position = 1,
            },
        },
    },
    previewers = {
        restricted_mode = {
            previewer = file_previewer_rg,
            previewer_type = "command_list",
        },
        unrestricted_mode = {
            previewer = file_previewer_rg,
            previewer_type = "command_list",
        },
        buffer_mode = {
            previewer = file_previewer_rg,
            previewer_type = "command_list",
        },
    },
    actions = {
        ["esc"] = require("fzfx.actions").nop,
        ["enter"] = require("fzfx.actions").edit_rg,
        ["double-click"] = require("fzfx.actions").edit_rg,
    },
    fzf_opts = {
        "--multi",
        "--disabled",
        { "--prompt", "Live Grep > " },
        { "--delimiter", ":" },
        { "--preview-window", "top,75%,+{2}-/2" },
    },
    other_opts = {
        reload_on_change = true,
    },
}

M.config = function()
    local fzfx = require("fzfx")
    local GroupConfig = require("fzfx.schema").GroupConfig
    fzfx.setup({
        live_grep = live_grep_curr,
        -- live_grep = {
        --     fzf_opts = {
        --       "--disabled",
        --       { "--prompt",         "Live Grep > " },
        --       { "--delimiter",      ":" },
        --       { "--preview-window", "top,75%,+{2}-/2" },
        --     },
        -- },
        buffers = {
            fzf_opts = {
                { "--prompt", "Buffers > " },
                { "--delimiter", ":" },
                { "--preview-window", "top,75%,+{2}-/2" },
            },
        },
        files = {
            fzf_opts = {
                { "--prompt", "Files > " },
                { "--delimiter", ":" },
                { "--preview-window", "top,50%,+{2}-/2" },
            },
        },
    })
end

M.keys = {
    { "<leader>xg", "<cmd>FzfxLiveGrep<cr>" },
    { "<leader><Leader>xg", "<cmd>FzfxLiveGrepW<cr>" },
    { "<leader>xs", "<cmd>FzfxLiveGrepB<cr>" },
    { "<leader><Leader>xs", "<cmd>FzfxLiveGrepBW<cr>" },
}

require("lazy").setup({
    {
        "linrongbin16/fzfx.nvim",
        -- dir = "~/.local/share/nvim/site/pack/plugins/start/fzfx.nvim",
        keys = M.keys,
        config = function()
            M.config()
        end,
        dependencies = {
            "nvim-tree/nvim-web-devicons",
            "junegunn/fzf",
        },
    },
})
