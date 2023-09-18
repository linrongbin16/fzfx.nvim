local cwd = vim.fn.getcwd()

describe("popup", function()
    local assert_eq = assert.are.equal
    local assert_neq = assert.are_not.equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false
    local assert_truthy = assert.is.truthy
    local assert_falsy = assert.is.falsy

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local popup = require("fzfx.popup")
    describe("[make_popup_window_size]", function()
        it("is in range of [0, 1]", function()
            assert_eq(5, popup.make_popup_window_size(0.5, 10))
            assert_eq(6, popup.make_popup_window_size(0.6, 10))
            assert_eq(7, popup.make_popup_window_size(0.7, 10))
            assert_eq(8, popup.make_popup_window_size(0.8, 10))
            assert_eq(9, popup.make_popup_window_size(0.9, 10))
            assert_eq(9, popup.make_popup_window_size(0.91, 10))
            assert_eq(9, popup.make_popup_window_size(0.92, 10))
            assert_eq(9, popup.make_popup_window_size(0.93, 10))
            assert_eq(9, popup.make_popup_window_size(0.94, 10))
            assert_eq(9, popup.make_popup_window_size(0.95, 10))
            assert_eq(9, popup.make_popup_window_size(0.96, 10))
            assert_eq(9, popup.make_popup_window_size(0.97, 10))
            assert_eq(9, popup.make_popup_window_size(0.98, 10))
            assert_eq(9, popup.make_popup_window_size(0.99, 10))
            assert_eq(10, popup.make_popup_window_size(1, 10))
        end)
        it("is greater than 1", function()
            assert_eq(2, popup.make_popup_window_size(2, 10, 1))
            assert_eq(3, popup.make_popup_window_size(2, 10))
            assert_eq(3, popup.make_popup_window_size(3, 10))
            assert_eq(4, popup.make_popup_window_size(4, 10))
            assert_eq(8, popup.make_popup_window_size(8, 10))
            assert_eq(9, popup.make_popup_window_size(9, 10))
            assert_eq(10, popup.make_popup_window_size(10, 10))
            assert_eq(10, popup.make_popup_window_size(11, 10))
            assert_eq(10, popup.make_popup_window_size(12, 10))
        end)
    end)
    describe("[make_popup_window_center_shift_size]", function()
        it("is in range of [0, 1]", function()
            assert_eq(
                12,
                popup.make_popup_window_center_shift_size(50, 30, 0.1)
            )
            assert_eq(10, popup.make_popup_window_center_shift_size(50, 30, 0))
            assert_eq(
                0,
                popup.make_popup_window_center_shift_size(50, 25, -0.5)
            )
            assert_eq(
                24,
                popup.make_popup_window_center_shift_size(50, 25, 0.5)
            )
        end)
        it("is greater than 1", function()
            assert_eq(12, popup.make_popup_window_center_shift_size(50, 30, 2))
            assert_eq(10, popup.make_popup_window_center_shift_size(50, 30, 0))
            assert_eq(0, popup.make_popup_window_center_shift_size(50, 20, -15))
            assert_eq(30, popup.make_popup_window_center_shift_size(50, 20, 15))
        end)
    end)
end)
