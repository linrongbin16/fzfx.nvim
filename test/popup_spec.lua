local cwd = vim.fn.getcwd()

describe("popup", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    require("fzfx.config").setup()
    local popup = require("fzfx.popup")
    describe("[_make_window_size]", function()
        it("is in range of [0, 1]", function()
            assert_eq(5, popup._make_window_size(0.5, 10))
            assert_eq(6, popup._make_window_size(0.6, 10))
            assert_eq(7, popup._make_window_size(0.7, 10))
            assert_eq(8, popup._make_window_size(0.8, 10))
            assert_eq(9, popup._make_window_size(0.9, 10))
            assert_eq(9, popup._make_window_size(0.91, 10))
            assert_eq(9, popup._make_window_size(0.92, 10))
            assert_eq(9, popup._make_window_size(0.93, 10))
            assert_eq(9, popup._make_window_size(0.94, 10))
            assert_eq(9, popup._make_window_size(0.95, 10))
            assert_eq(9, popup._make_window_size(0.96, 10))
            assert_eq(9, popup._make_window_size(0.97, 10))
            assert_eq(9, popup._make_window_size(0.98, 10))
            assert_eq(9, popup._make_window_size(0.99, 10))
            assert_eq(10, popup._make_window_size(1, 10))
        end)
        it("is greater than 1", function()
            assert_eq(2, popup._make_window_size(2, 10, 1))
            assert_eq(3, popup._make_window_size(2, 10))
            assert_eq(3, popup._make_window_size(3, 10))
            assert_eq(4, popup._make_window_size(4, 10))
            assert_eq(8, popup._make_window_size(8, 10))
            assert_eq(9, popup._make_window_size(9, 10))
            assert_eq(10, popup._make_window_size(10, 10))
            assert_eq(10, popup._make_window_size(11, 10))
            assert_eq(10, popup._make_window_size(12, 10))
        end)
    end)
    describe("[_make_window_center_shift_size]", function()
        it("is in range of [0, 1]", function()
            assert_eq(12, popup._make_window_center_shift_size(50, 30, 0.1))
            assert_eq(10, popup._make_window_center_shift_size(50, 30, 0))
            assert_eq(0, popup._make_window_center_shift_size(50, 25, -0.5))
            assert_eq(24, popup._make_window_center_shift_size(50, 25, 0.5))
        end)
        it("is greater than 1", function()
            assert_eq(12, popup._make_window_center_shift_size(50, 30, 2))
            assert_eq(10, popup._make_window_center_shift_size(50, 30, 0))
            assert_eq(0, popup._make_window_center_shift_size(50, 20, -15))
            assert_eq(30, popup._make_window_center_shift_size(50, 20, 15))
        end)
    end)
    describe("[_make_window_config_for_cursor_anchor]", function()
        local WIN_OPTS = {
            height = 0.85,
            width = 0.85,
            row = 0,
            col = 0,
            border = "none",
            zindex = 51,
        }
        it("makes cursor config", function()
            local actual = popup._make_window_config_for_cursor_anchor(WIN_OPTS)
            print(
                string.format(
                    "make config for cursor:%s\n",
                    vim.inspect(actual)
                )
            )
            assert_eq(actual.anchor, "NW")
            assert_eq(actual.border, WIN_OPTS.border)
            assert_eq(actual.zindex, WIN_OPTS.zindex)
            assert_eq(type(actual.height), "number")
            assert_true(actual.height >= 0)
            assert_eq(type(actual.width), "number")
            assert_true(actual.width >= 0)
            assert_eq(type(actual.row), "number")
            assert_true(actual.row >= 0)
            assert_eq(type(actual.col), "number")
            assert_true(actual.col >= 0)
        end)
    end)
end)
