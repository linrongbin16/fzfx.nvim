local cwd = vim.fn.getcwd()

describe("server", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local utils = require("fzfx.utils")
    local server = require("fzfx.server")
    server.setup()
    describe("[_make_windows_pipe_name]", function()
        it("gets bigger", function()
            local ok, err = pcall(server._make_windows_pipe_name)
            assert_false(ok)
            assert_eq(type(err), "string")
        end)
    end)
    describe("[RpcServer]", function()
        it("create server", function()
            local s = server.get_rpc_server()
            assert_eq(type(s), "table")
            local sockaddr = vim.env._FZFX_NVIM_SOCKET_ADDRESS
            print(
                string.format("rpc server socket:%s\n", vim.inspect(sockaddr))
            )
            assert_eq(type(sockaddr), "string")
            assert_true(string.len(sockaddr) > 0)
        end)
        it("register/unregister", function()
            local s = server.get_rpc_server()
            local f = function(x) end
            local rid = s:register(f)
            assert_eq(type(rid), "string")
            assert_true(tonumber(rid) == tonumber(utils.make_unique_id()) - 1)
            local actual1 = s:get(rid)
            assert_eq(type(actual1), "function")
            assert_eq(vim.inspect(f), vim.inspect(actual1))
            local actual2 = s:unregister(rid)
            assert_eq(type(actual2), "function")
            assert_eq(vim.inspect(f), vim.inspect(actual2))
            assert_eq(vim.inspect(actual1), vim.inspect(actual2))
        end)
    end)
end)
