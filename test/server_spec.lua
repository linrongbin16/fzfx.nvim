local cwd = vim.fn.getcwd()

describe("server", function()
    local assert_eq = assert.are.equal
    local assert_neq = assert.are_not.equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false
    local assert_truthy = assert.is.truthy
    local assert_falsy = assert.is.falsy

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local server = require("fzfx.server")
    describe("[next_registry_id]", function()
        it("gets bigger", function()
            local id1 = server.next_registry_id()
            assert_eq(id1, "1")
            local id2 = server.next_registry_id()
            assert_eq(id2, "2")
            local id3 = server.next_registry_id()
            assert_eq(id3, "3")
        end)
    end)
    describe("[RpcServer]", function()
        it("create server", function()
            server.setup()
            local s = server.get_global_rpc_server()
            assert_eq(type(s), "table")
            assert_false(vim.tbl_isempty(s))
        end)
    end)
end)
