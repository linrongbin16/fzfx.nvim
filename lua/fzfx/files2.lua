local Pipeline = require("fzfx.schema_def").Pipeline
local Command = require("fzfx.schema_def").Command
local ProviderTypeEnum = require("fzfx.schema_def").ProviderTypeEnum
local LineProcessorTypeEnum = require("fzfx.schema_def").LineProcessorTypeEnum
local PreviewerTypeEnum = require("fzfx.schema_def").PreviewerTypeEnum
local CommandFeedEnum = require("fzfx.schema_def").CommandFeedEnum
local NormalCommandOpts = require("fzfx.schema_def").NormalCommandOpts
local constants = require("fzfx.constants")
local env = require("fzfx.env")
local color = require("fzfx.color")
local action = require("fzfx.action")
local fzf_opt_constants = require("fzfx.fzf_opt_constants")

local default_fd_command =
    string.format("%s -cnever -tf -tl -L -i", constants.fd)

--- @param line string
--- @return string
local function processor(line)
    if env.icon_enable() then
        local devicons = require("nvim-web-devicons")
        local ext = vim.fn.fnamemodify(line, ":e")
        local icon, icon_color = devicons.get_icon_color(line, ext)
        -- if DEBUG_ENABLE then
        --     log_debug(
        --         "|fzfx.shell_helpers - render_line_with_icon| line:%s, ext:%s, icon:%s, color:%s\n",
        --         vim.inspect(line),
        --         vim.inspect(ext),
        --         vim.inspect(icon),
        --         vim.inspect(color)
        --     )
        -- end
        if type(icon) == "string" and string.len(icon) > 0 then
            local colorfmt = color.csi(icon_color, true)
            if colorfmt then
                return string.format("[%sm%s[0m %s", colorfmt, icon, line)
            else
                return string.format("%s %s", icon, line)
            end
        else
            if vim.fn.isdirectory(line) > 0 then
                return string.format(
                    "%s %s",
                    require("fzfx.config").get_config().popup.icon.folder,
                    line
                )
            else
                return string.format(
                    "%s %s",
                    require("fzfx.config").get_config().popup.icon.unknown_file,
                    line
                )
            end
        end
    else
        return line
    end
end

local function previewer(...)
    local args = { ... }
    local filename = args[1]
    local lineno = nil
    if #args >= 2 then
        lineno = args[2]
    end

    if env.icon_enable() then
        local splits = vim.fn.split(filename)
        filename = splits[2]
    end

    if vim.fn.executable("batcat") > 0 or vim.fn.executable("bat") > 0 then
        local style = "numbers,changes"
        if
            type(vim.env["BAT_STYLE"]) == "string"
            and string.len(vim.env["BAT_STYLE"]) > 0
        then
            style = vim.env["BAT_STYLE"]
        end
        local cmd = string.format(
            "%s --style=%s --color=always --pager=never %s -- %s",
            constants.bat,
            style,
            (lineno ~= nil and string.len(lineno) > 0)
                    and string.format("--highlight-line=%s", lineno)
                or "",
            filename
        )

        return cmd
    else
        local cmd = string.format("cat %s", filename)
        return cmd
    end
end

local restricted_pipeline = Pipeline:make({
    provider = default_fd_command,
    provider_type = ProviderTypeEnum.PLAIN,
    line_processor = processor,
    line_processor_type = LineProcessorTypeEnum.FUNCTION,
    previewer = previewer,
    previewer_type = PreviewerTypeEnum.COMMAND,
    help_format = "%s to restricted mode",
})

local unrestricted_pipeline = Pipeline:make({
    provider = default_fd_command .. " -u",
    provider_type = ProviderTypeEnum.PLAIN,
    line_processor = processor,
    line_processor_type = LineProcessorTypeEnum.FUNCTION,
    previewer = previewer,
    previewer_type = PreviewerTypeEnum.COMMAND,
    help_format = "%s to unrestricted mode",
})

local default_fzf_opts = {
    fzf_opt_constants.multi,
    fzf_opt_constants.toggle,
    fzf_opt_constants.toggle_all,
    fzf_opt_constants.preview_half_page_down,
    fzf_opt_constants.preview_half_page_up,
    fzf_opt_constants.toggle_preview,
    function()
        local path = require("fzfx.path")
        return { "--prompt", path.shorten() .. " > " }
    end,
}

local files = Command:make({
    name = "FzfxFiles",
    pipelines = {
        ["ctrl-r"] = restricted_pipeline,
        ["ctrl-u"] = unrestricted_pipeline,
    },
    default_pipeline = restricted_pipeline,
    interactive_actions = nil,
    expect_actions = {
        ["esc"] = action.nop,
        ["enter"] = action.edit,
        ["double-click"] = action.edit,
    },
    command_opts = NormalCommandOpts:make({
        desc = "Find files",
        complete = "dir",
    }),
    feed_method = CommandFeedEnum.ARGS,
    fzf_opts = default_fzf_opts,
})

local files_u = Command:make({
    name = "FzfxFilesU",
    pipelines = {
        ["ctrl-r"] = restricted_pipeline,
        ["ctrl-u"] = unrestricted_pipeline,
    },
    default_pipeline = unrestricted_pipeline,
    interactive_actions = nil,
    expect_actions = {
        ["esc"] = action.nop,
        ["enter"] = action.edit,
        ["double-click"] = action.edit,
    },
    command_opts = NormalCommandOpts:make({
        desc = "Find files unrestricted",
        complete = "dir",
    }),
    feed_method = CommandFeedEnum.ARGS,
    fzf_opts = default_fzf_opts,
})

local M = {
    files = files,
    files_u = files_u,
}

return M
