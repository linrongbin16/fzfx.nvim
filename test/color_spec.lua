local cwd = vim.fn.getcwd()

describe("color", function()
    local assert_eq = assert.are.equal
    local assert_neq = assert.are_not.equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false
    local assert_truthy = assert.is.truthy
    local assert_falsy = assert.is.falsy

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local color = require("fzfx.color")
    describe("[hlgroup]", function()
        local hlgroups = {
            "Special",
            "Normal",
            "LineNr",
            "TabLine",
            "Exception",
            "Comment",
            "Label",
            "String",
        }

        it("get vim fg colors", function()
            for _, grp in ipairs(hlgroups) do
                local actual = color.hlcode("fg", grp)
                print(
                    string.format("hlgroup(%s): %s\n", grp, vim.inspect(actual))
                )
                assert_true(type(actual) == "string" or actual == nil)
                if type(actual) == "string" then
                    assert_true(tonumber(actual) >= 0)
                end
            end
        end)
        it("get vim bg colors", function()
            for _, group in ipairs(hlgroups) do
                local actual = color.hlcode("bg", group)
                print(
                    string.format(
                        "hlgroup(%s): %s\n",
                        group,
                        vim.inspect(actual)
                    )
                )
                assert_true(type(actual) == "string" or actual == nil)
                if type(actual) == "string" then
                    assert_true(tonumber(actual) >= 0)
                end
            end
        end)
    end)

    describe("[ansi]", function()
        local ansigroups = {
            black = "Comment",
            grey = "Comment",
            silver = "Comment",
            white = "Comment",
            red = "Exception",
            magenta = "Special",
            fuchsia = "Special",
            purple = "Special",
            yellow = "LineNr",
            orange = "LineNr",
            olive = "LineNr",
            green = "Label",
            lime = "Label",
            teal = "Label",
            cyan = "String",
            aqua = "String",
            blue = "TabLine",
            navy = "TabLine",
        }

        -- see: https://stackoverflow.com/a/55324681/4438921
        local function test_ansi(fn_print, result)
            fn_print()
            assert_eq(type(result), "string")
            assert_true(string.len(result) > 0)
            local i0, j0 = result:find("\x1b%[0m")
            assert_true(i0 > 1)
            assert_true(j0 > 1)
            local i1, j1 = result:find("\x1b%[%d+m")
            assert_true(i1 >= 1)
            assert_true(j1 >= 1)
            local i2, j2 = result:find("\x1b%[%d+;%d+m")
            if i2 ~= nil and j2 ~= nil then
                assert_true(i2 >= 1)
                assert_true(j2 >= 1)
                assert_true(i2 < i0)
                assert_true(j2 < j0)
            end
            local i3, j3 = result:find("\x1b%[%d+;%d+;%d+m")
            if i3 ~= nil and j3 ~= nil then
                assert_true(i3 >= 1)
                assert_true(j3 >= 1)
                assert_true(i3 < i0)
                assert_true(j3 < j0)
            end
            local i4, j4 = result:find("\x1b%[%d+;%d+;%d+;%d+m")
            if i4 ~= nil and j4 ~= nil then
                assert_true(i4 >= 1)
                assert_true(j4 >= 1)
                assert_true(i4 < i0)
                assert_true(j4 < j0)
            end
        end

        it("get fg hlgroup color or fallback to ansi color", function()
            for clr, grp in pairs(ansigroups) do
                local actual = color.ansi("fg", clr, grp)
                test_ansi(function()
                    print(
                        string.format(
                            "fg ansigroup(%s): %s\n",
                            grp,
                            vim.inspect(actual)
                        )
                    )
                end, actual)
            end
        end)
        it("get bg hlgroup color or fallback to ansi color", function()
            for clr, grp in ipairs(ansigroups) do
                local actual = color.ansi("bg", clr, grp)
                test_ansi(function()
                    print(
                        string.format(
                            "bg ansigroup(%s): %s\n",
                            grp,
                            vim.inspect(actual)
                        )
                    )
                end, actual)
            end
        end)
    end)
    describe("[erase]", function()
        it("do nothing", function()
            assert_eq("hello world", color.erase("hello world"))
            assert_eq("let's go", color.erase("let's go"))
        end)
    end)
end)
