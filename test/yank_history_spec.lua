local cwd = vim.fn.getcwd()

describe("yank_history", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
        vim.opt.swapfile = false
    end)

    require("fzfx.config").setup()
    local yank_history = require("fzfx.yank_history")
    yank_history.setup()
    describe("[Yank]", function()
        it("creates", function()
            local yk = yank_history.Yank:new(
                "regname",
                "regtext",
                "regtype",
                "filename",
                "filetype"
            )
            assert_eq(type(yk), "table")
            assert_eq(yk.regname, "regname")
            assert_eq(yk.regtext, "regtext")
            assert_eq(yk.regtype, "regtype")
            assert_eq(yk.filename, "filename")
            assert_eq(yk.filetype, "filetype")
        end)
    end)
    describe("[YankHistory]", function()
        it("creates", function()
            local yk = yank_history.YankHistory:new(10)
            assert_eq(type(yk), "table")
            assert_eq(#yk.queue, 0)
        end)
        it("loop", function()
            local yk = yank_history.YankHistory:new(10)
            assert_eq(type(yk), "table")
            for i = 1, 10 do
                yk:push(i)
            end
            local p = yk:begin()
            while p do
                local actual = yk:get(p)
                assert_eq(actual, p)
                p = yk:next(p)
            end
            yk = yank_history.YankHistory:new(10)
            for i = 1, 15 do
                yk:push(i)
            end
            local p = yk:begin()
            while p do
                local actual = yk:get(p)
                if p <= 5 then
                    assert_eq(actual, p + 10)
                else
                    assert_eq(actual, p)
                end
                p = yk:next(p)
            end
            yk = yank_history.YankHistory:new(10)
            for i = 1, 20 do
                yk:push(i)
            end
            local p = yk:begin()
            while p do
                local actual = yk:get(p)
                assert_eq(actual, p + 10)
                p = yk:next(p)
            end
        end)
        it("get latest", function()
            local yk = yank_history.YankHistory:new(10)
            for i = 1, 50 do
                yk:push(i)
                assert_eq(yk:get(), i)
            end
        end)
    end)
end)
