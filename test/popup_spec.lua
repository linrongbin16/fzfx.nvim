local cwd = vim.fn.getcwd()

describe("popup", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
        vim.opt.swapfile = false
        vim.fn["fzf#exec"] = function()
            return "fzf"
        end
    end)

    require("fzfx.config").setup()
    local fzf_helpers = require("fzfx.fzf_helpers")
    local popup = require("fzfx.popup")
    local utils = require("fzfx.utils")
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
            assert_eq(12, popup._make_window_center_shift(50, 30, 0.1))
            assert_eq(10, popup._make_window_center_shift(50, 30, 0))
            assert_eq(0, popup._make_window_center_shift(50, 25, -0.5))
            assert_eq(24, popup._make_window_center_shift(50, 25, 0.5))
        end)
        it("is greater than 1", function()
            assert_eq(12, popup._make_window_center_shift(50, 30, 2))
            assert_eq(10, popup._make_window_center_shift(50, 30, 0))
            assert_eq(0, popup._make_window_center_shift(50, 20, -15))
            assert_eq(30, popup._make_window_center_shift(50, 20, 15))
        end)
    end)
    describe("[_make_cursor_window_config]", function()
        local WIN_OPTS = {
            height = 0.85,
            width = 0.85,
            row = 0,
            col = 0,
            border = "none",
            zindex = 51,
        }
        it("makes cursor config", function()
            local actual = popup._make_cursor_window_config(WIN_OPTS)
            print(string.format("make cursor config:%s\n", vim.inspect(actual)))
            local win_width = vim.api.nvim_win_get_width(0)
            local win_height = vim.api.nvim_win_get_height(0)
            local expect_width =
                popup._make_window_size(WIN_OPTS.width, win_width)
            local expect_height =
                popup._make_window_size(WIN_OPTS.height, win_height)
            assert_eq(actual.anchor, "NW")
            assert_eq(actual.border, WIN_OPTS.border)
            assert_eq(actual.zindex, WIN_OPTS.zindex)
            assert_eq(type(actual.height), "number")
            assert_eq(actual.height, expect_height)
            assert_eq(type(actual.width), "number")
            assert_eq(actual.width, expect_width)
            assert_eq(type(actual.row), "number")
            assert_eq(actual.row, 0)
            assert_eq(type(actual.col), "number")
            assert_eq(actual.col, 0)
        end)
    end)
    describe("[_make_center_window_config]", function()
        local WIN_OPTS = {
            height = 0.85,
            width = 0.85,
            row = 0,
            col = 0,
            border = "none",
            zindex = 51,
        }
        it("makes center config", function()
            local actual = popup._make_center_window_config(WIN_OPTS)
            print(string.format("make center config:%s\n", vim.inspect(actual)))
            local total_width = vim.o.columns
            local total_height = vim.o.lines
            local expect_width =
                popup._make_window_size(WIN_OPTS.width, total_width)
            local expect_height =
                popup._make_window_size(WIN_OPTS.height, total_height)
            local expect_row = popup._make_window_center_shift(
                total_height,
                expect_height,
                WIN_OPTS.row
            )
            local expect_col = popup._make_window_center_shift(
                total_width,
                expect_width,
                WIN_OPTS.col
            )
            assert_eq(actual.anchor, "NW")
            assert_eq(actual.border, WIN_OPTS.border)
            assert_eq(actual.zindex, WIN_OPTS.zindex)
            assert_eq(type(actual.height), "number")
            assert_eq(actual.height, expect_height)
            assert_eq(type(actual.width), "number")
            assert_eq(actual.width, expect_width)
            assert_eq(type(actual.row), "number")
            assert_eq(actual.row, expect_row)
            assert_eq(type(actual.col), "number")
            assert_eq(actual.col, expect_col)
        end)
    end)
    describe("[_make_window_config]", function()
        local WIN_OPTS = {
            height = 0.85,
            width = 0.85,
            row = 0,
            col = 0,
            border = "none",
            zindex = 51,
        }
        it("makes center config", function()
            local actual1 = popup._make_window_config(WIN_OPTS)
            local actual2 = popup._make_center_window_config(WIN_OPTS)
            print(
                string.format("make window config:%s\n", vim.inspect(actual1))
            )
            assert_eq(actual1.anchor, "NW")
            assert_eq(actual1.border, WIN_OPTS.border)
            assert_eq(actual1.zindex, WIN_OPTS.zindex)
            assert_eq(type(actual1.height), "number")
            assert_eq(type(actual2.height), "number")
            assert_eq(actual1.height, actual2.height)
            assert_eq(type(actual1.width), "number")
            assert_eq(type(actual2.width), "number")
            assert_eq(actual1.width, actual2.width)
            assert_eq(type(actual1.row), "number")
            assert_eq(type(actual2.row), "number")
            assert_eq(actual1.row, actual2.row)
            assert_eq(type(actual1.col), "number")
            assert_eq(type(actual2.col), "number")
            assert_eq(actual1.col, actual2.col)
        end)
    end)
    describe("[_get_all_popup_window_instances]", function()
        it("get all instances", function()
            popup._remove_all_popup_window_instances()
            assert_eq(type(popup._get_all_popup_window_instances()), "table")
            assert_true(
                vim.tbl_isempty(popup._get_all_popup_window_instances())
            )
            local pw = popup.PopupWindow:new()
            assert_eq(type(popup._get_all_popup_window_instances()), "table")
            assert_false(
                vim.tbl_isempty(popup._get_all_popup_window_instances())
            )
            local instances = popup._get_all_popup_window_instances()
            for _, p in pairs(instances) do
                assert_eq(p.winnr, pw.winnr)
                assert_eq(p.bufnr, pw.bufnr)
                assert_true(
                    vim.deep_equal(
                        p.window_opts_context,
                        pw.window_opts_context
                    )
                )
                assert_true(
                    vim.deep_equal(p._saved_win_opts, pw._saved_win_opts)
                )
                assert_eq(p._resizing, pw._resizing)
            end
            assert_eq(popup._count_all_popup_window_instances(), 1)
        end)
        it("create and remove instances", function()
            popup._remove_all_popup_window_instances()
            assert_eq(type(popup._get_all_popup_window_instances()), "table")
            assert_true(
                vim.tbl_isempty(popup._get_all_popup_window_instances())
            )
            assert_eq(popup._count_all_popup_window_instances(), 0)
            local pw = popup.PopupWindow:new()
            assert_eq(popup._count_all_popup_window_instances(), 1)
            pw:close()
            assert_eq(popup._count_all_popup_window_instances(), 0)
            local pw1 = popup.PopupWindow:new()
            local pw2 = popup.PopupWindow:new()
            assert_eq(popup._count_all_popup_window_instances(), 2)
            pw1:close()
            pw2:close()
            assert_eq(popup._count_all_popup_window_instances(), 0)
        end)
    end)
    describe("[PopupWindow]", function()
        it("creates new", function()
            local pw = popup.PopupWindow:new()
            assert_eq(type(pw), "table")
            assert_eq(type(pw.window_opts_context), "table")
            assert_eq(type(pw.window_opts_context.bufnr), "number")
            assert_eq(type(pw.window_opts_context.winnr), "number")
            assert_eq(type(pw.window_opts_context.tabnr), "number")
            assert_true(pw.window_opts_context.bufnr > 0)
            assert_true(pw.window_opts_context.winnr > 0)
            assert_true(pw.window_opts_context.tabnr > 0)
            assert_eq(type(pw.bufnr), "number")
            assert_eq(type(pw.winnr), "number")
            assert_true(pw.bufnr > 0)
            assert_true(pw.winnr > 0)
            assert_eq(type(pw._saved_win_opts), "table")
            assert_eq(type(pw._resizing), "boolean")
            assert_false(pw._resizing)
        end)
        it("resize", function()
            local pw = popup.PopupWindow:new()
            pw:resize()
        end)
    end)
    describe("[_make_expect_keys]", function()
        it("make --expect options", function()
            local input = {
                ["ctrl-d"] = function(lines) end,
                ["ctrl-r"] = function(lines) end,
            }
            local actual = popup._make_expect_keys(input)
            assert_eq(type(actual), "table")
            assert_eq(#actual, 2)
            for _, a in ipairs(actual) do
                assert_eq(a[1], "--expect")
                assert_true(a[2] == "ctrl-d" or a[2] == "ctrl-r")
            end
        end)
    end)
    describe("[_merge_fzf_actions]", function()
        it("merge fzf actions", function()
            local input = {
                ["ctrl-d"] = function(lines) end,
                ["ctrl-r"] = function(lines) end,
            }
            local actual = popup._merge_fzf_actions({}, input)
            assert_eq(type(actual), "table")
            assert_eq(#actual, 2)
            for _, a in ipairs(actual) do
                assert_eq(a[1], "--expect")
                assert_true(a[2] == "ctrl-d" or a[2] == "ctrl-r")
            end
            local actual2 = popup._make_expect_keys(input)
            assert_true(vim.deep_equal(actual, actual2))
        end)
    end)
    describe("[_make_fzf_command]", function()
        it("merge fzf command", function()
            local input = {
                ["ctrl-d"] = function(lines) end,
                ["ctrl-r"] = function(lines) end,
            }
            local tmpname = vim.fn.tempname()
            local fzfopts = fzf_helpers.make_fzf_default_opts()
            local actual = popup._make_fzf_command({ fzfopts }, input, tmpname)
            print(string.format("make fzf command:%s\n", vim.inspect(actual)))
            assert_eq(type(actual), "string")
            assert_true(string.len(actual) > 0)
            assert_true(utils.string_startswith(actual, "fzf "))
            assert_eq(utils.string_find(actual, fzfopts), 5)
            assert_true(
                utils.string_find(actual, "--expect") > string.len(fzfopts)
            )
        end)
    end)
end)
