local function define_command(configs, fun, command_opts)
    vim.api.nvim_create_user_command(
        configs.name,
        fun,
        configs.desc
                and vim.tbl_deep_extend(
                    "force",
                    vim.deepcopy(command_opts),
                    { desc = configs.desc }
                )
            or command_opts
    )
end

local M = {
    define_command = define_command,
}

return M
