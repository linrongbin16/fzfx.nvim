local cwd = vim.fn.getcwd()

describe("profiler", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local Profiler = require("fzfx.profiler").Profiler
    describe("[Profiler]", function()
        it("creates", function()
            local p = Profiler:new()
            print(string.format("profiler1:%s\n", vim.inspect(p)))
            assert_true(p.start_at.secs > 0)
            assert_true(p.start_at.ms >= 0 and p.start_at.ms < 1000000)
            assert_true(
                p:start_secs() > 0 and p:start_secs() == p.start_at.secs
            )
            assert_true(
                p:start_ms() > 0
                    and p:start_ms()
                        == (p.start_at.secs * 1000000 + p.start_at.ms)
            )
        end)
        it("elapsed", function()
            local p = Profiler:new()
            print(string.format("profiler2:%s\n", vim.inspect(p)))
            assert_true(p.start_at.secs > 0)
            assert_true(p.start_at.ms >= 0 and p.start_at.ms < 1000000)
            assert_true(p:elapsed_secs() == 0)
            assert_true(p:elapsed_ms() >= 0 and p:elapsed_ms() < 100000)
        end)
    end)
end)
