local cwd = vim.fn.getcwd()

describe("general", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
        vim.env._FZFX_NVIM_DEBUG_ENABLE = 1
    end)

    local github_actions = os.getenv("GITHUB_ACTIONS") == "true"
    local general = require("fzfx.general")
    local ProviderConfig = require("fzfx.schema").ProviderConfig
    local PreviewerConfig = require("fzfx.schema").PreviewerConfig
    local utils = require("fzfx.utils")
    local path = require("fzfx.path")
    local schema = require("fzfx.schema")
    local conf = require("fzfx.config")
    conf.setup()
    describe("[ProviderSwitch:new]", function()
        it("creates single plain provider", function()
            local ps = general.ProviderSwitch:new(
                "single",
                "pipeline",
                ProviderConfig:make({
                    key = "ctrl-k",
                    provider = "ls -1",
                })
            )
            assert_eq(type(ps), "table")
            assert_false(vim.tbl_isempty(ps))
            assert_eq(type(ps.provider_configs.default), "table")
            assert_false(vim.tbl_isempty(ps.provider_configs.default))
            assert_eq(ps.provider_configs.default.key, "ctrl-k")
            assert_eq(ps.provider_configs.default.provider, "ls -1")
            assert_eq(ps.provider_configs.default.provider_type, "plain")
            assert_eq(ps:switch("default"), nil)
        end)
        it("creates single plain_list provider", function()
            local ps = general.ProviderSwitch:new(
                "single",
                "pipeline",
                ProviderConfig:make({
                    key = "ctrl-k",
                    provider = { "ls", "-1" },
                })
            )
            assert_eq(type(ps), "table")
            assert_false(vim.tbl_isempty(ps))
            assert_eq(type(ps.provider_configs.default), "table")
            assert_false(vim.tbl_isempty(ps.provider_configs.default))
            assert_eq(ps.provider_configs.default.key, "ctrl-k")
            assert_eq(type(ps.provider_configs.default.provider), "table")
            assert_eq(#ps.provider_configs.default.provider, 2)
            assert_eq(ps.provider_configs.default.provider[1], "ls")
            assert_eq(ps.provider_configs.default.provider[2], "-1")
            assert_eq(ps.provider_configs.default.provider_type, "plain_list")
            assert_eq(ps:switch("default"), nil)
        end)
        it("creates multiple plain providers", function()
            local ps = general.ProviderSwitch:new("single", "pipeline", {
                p1 = ProviderConfig:make({
                    key = "ctrl-p",
                    provider = "p1",
                }),
                p2 = ProviderConfig:make({
                    key = "ctrl-q",
                    provider = "p2",
                }),
            })
            assert_eq(type(ps), "table")
            assert_false(vim.tbl_isempty(ps))

            assert_eq(type(ps.provider_configs.p1), "table")
            assert_false(vim.tbl_isempty(ps.provider_configs.p1))
            assert_eq(ps.provider_configs.p1.key, "ctrl-p")
            assert_eq(type(ps.provider_configs.p1.provider), "string")
            assert_eq(ps.provider_configs.p1.provider, "p1")
            assert_eq(ps.provider_configs.p1.provider_type, "plain")
            assert_eq(ps:switch("p1"), nil)

            assert_eq(type(ps.provider_configs.p2), "table")
            assert_false(vim.tbl_isempty(ps.provider_configs.p2))
            assert_eq(ps.provider_configs.p2.key, "ctrl-q")
            assert_eq(type(ps.provider_configs.p2.provider), "string")
            assert_eq(ps.provider_configs.p2.provider, "p2")
            assert_eq(ps.provider_configs.p2.provider_type, "plain")
            assert_eq(ps:switch("p2"), nil)
        end)
        it("creates multiple plain_list providers", function()
            local ps = general.ProviderSwitch:new("single", "pipeline", {
                p1 = ProviderConfig:make({
                    key = "ctrl-p",
                    provider = { "p1", "p11", "p12" },
                }),
                p2 = ProviderConfig:make({
                    key = "ctrl-q",
                    provider = { "p2", "p21", "p22" },
                }),
            })
            assert_eq(type(ps), "table")
            assert_false(vim.tbl_isempty(ps))

            assert_eq(type(ps.provider_configs.p1), "table")
            assert_false(vim.tbl_isempty(ps.provider_configs.p1))
            assert_eq(ps.provider_configs.p1.key, "ctrl-p")
            assert_eq(type(ps.provider_configs.p1.provider), "table")
            assert_eq(#ps.provider_configs.p1.provider, 3)
            assert_eq(ps.provider_configs.p1.provider[1], "p1")
            assert_eq(ps.provider_configs.p1.provider[2], "p11")
            assert_eq(ps.provider_configs.p1.provider[3], "p12")
            assert_eq(ps.provider_configs.p1.provider_type, "plain_list")
            assert_eq(ps:switch("p1"), nil)

            assert_eq(type(ps.provider_configs.p2), "table")
            assert_false(vim.tbl_isempty(ps.provider_configs.p2))
            assert_eq(ps.provider_configs.p2.key, "ctrl-q")
            assert_eq(type(ps.provider_configs.p2.provider), "table")
            assert_eq(#ps.provider_configs.p2.provider, 3)
            assert_eq(ps.provider_configs.p2.provider[1], "p2")
            assert_eq(ps.provider_configs.p2.provider[2], "p21")
            assert_eq(ps.provider_configs.p2.provider[3], "p22")
            assert_eq(ps.provider_configs.p2.provider_type, "plain_list")
            assert_eq(ps:switch("p2"), nil)
        end)
    end)
    describe("[PreviewerSwitch:provide]", function()
        it("is a plain/plain_list provider", function()
            local ps = general.ProviderSwitch:new("plain_test", "p1", {
                p1 = ProviderConfig:make({
                    key = "ctrl-p",
                    provider = "ls -lh",
                }),
                p2 = ProviderConfig:make({
                    key = "ctrl-q",
                    provider = { "ls", "-lha", "~" },
                }),
            })
            print(
                string.format("GITHUB_ACTIONS:%s", os.getenv("GITHUB_ACTIONS"))
            )
            assert_eq(ps:provide("p1", "hello", {}), "plain")
            if not github_actions then
                local meta1 = utils.readfile(
                    path.join(
                        vim.fn.stdpath("data"),
                        "fzfx.nvim",
                        "provider_switch_metafile_plain_test"
                    )
                )
                local result1 = utils.readfile(
                    path.join(
                        vim.fn.stdpath("data"),
                        "fzfx.nvim",
                        "provider_switch_resultfile_plain_test"
                    )
                )
                print(string.format("metafile:%s\n", meta1))
                local metajson1 = vim.fn.json_decode(meta1) --[[@as table]]
                assert_eq(type(metajson1), "table")
                assert_eq(metajson1.pipeline, "p1")
                assert_eq(metajson1.provider_type, "plain")
                print(string.format("resultfile:%s\n", result1))
                assert_eq(result1, "ls -lh")
            end
            ps:switch("p2")
            assert_eq(ps:provide("p2", "world", {}), "plain_list")
            if not github_actions then
                local meta2 = utils.readfile(
                    path.join(
                        vim.fn.stdpath("data"),
                        "fzfx.nvim",
                        "provider_switch_metafile_plain_test"
                    )
                )
                local result2 = utils.readfile(
                    path.join(
                        vim.fn.stdpath("data"),
                        "fzfx.nvim",
                        "provider_switch_resultfile_plain_test"
                    )
                )
                print(string.format("metafile:%s\n", meta2))
                local metajson2 = vim.fn.json_decode(meta2) --[[@as table]]
                assert_eq(type(metajson2), "table")
                assert_eq(metajson2.pipeline, "p2")
                assert_eq(metajson2.provider_type, "plain_list")
                print(string.format("resultfile:%s\n", result2))
                local resultjson2 = vim.fn.json_decode(result2) --[[@as table]]
                assert_eq(type(resultjson2), "table")
                assert_eq(#resultjson2, 3)
                assert_eq(resultjson2[1], "ls")
                assert_eq(resultjson2[2], "-lha")
                assert_eq(resultjson2[3], "~")
            end
        end)
        it("is a command/command_list provider", function()
            local ps = general.ProviderSwitch:new("command_test", "p1", {
                p1 = ProviderConfig:make({
                    key = "ctrl-p",
                    provider = function()
                        return "ls -lh"
                    end,
                    provider_type = schema.ProviderTypeEnum.COMMAND,
                }),
                p2 = ProviderConfig:make({
                    key = "ctrl-q",
                    provider = function()
                        return { "ls", "-lha", "~" }
                    end,
                    provider_type = schema.ProviderTypeEnum.COMMAND_LIST,
                }),
            })
            assert_eq(ps:provide("p1", "hello", {}), "command")
            if not github_actions then
                local meta1 = utils.readfile(
                    path.join(
                        vim.fn.stdpath("data"),
                        "fzfx.nvim",
                        "provider_switch_metafile_command_test"
                    )
                )
                local result1 = utils.readfile(
                    path.join(
                        vim.fn.stdpath("data"),
                        "fzfx.nvim",
                        "provider_switch_resultfile_command_test"
                    )
                )
                print(string.format("metafile:%s\n", meta1))
                local metajson1 = vim.fn.json_decode(meta1) --[[@as table]]
                assert_eq(type(metajson1), "table")
                assert_eq(metajson1.pipeline, "p1")
                assert_eq(metajson1.provider_type, "command")
                print(string.format("resultfile:%s\n", result1))
                assert_eq(result1, "ls -lh")
            end
            ps:switch("p2")
            assert_eq(ps:provide("p2", "world", {}), "command_list")
            if not github_actions then
                local meta2 = utils.readfile(
                    path.join(
                        vim.fn.stdpath("data"),
                        "fzfx.nvim",
                        "provider_switch_metafile_command_test"
                    )
                )
                local result2 = utils.readfile(
                    path.join(
                        vim.fn.stdpath("data"),
                        "fzfx.nvim",
                        "provider_switch_resultfile_command_test"
                    )
                )
                print(string.format("metafile:%s\n", meta2))
                local metajson2 = vim.fn.json_decode(meta2) --[[@as table]]
                assert_eq(type(metajson2), "table")
                assert_eq(metajson2.pipeline, "p2")
                assert_eq(metajson2.provider_type, "command_list")
                print(string.format("resultfile:%s\n", result2))
                local resultjson2 = vim.fn.json_decode(result2) --[[@as table]]
                assert_eq(type(resultjson2), "table")
                assert_eq(#resultjson2, 3)
                assert_eq(resultjson2[1], "ls")
                assert_eq(resultjson2[2], "-lha")
                assert_eq(resultjson2[3], "~")
            end
        end)
    end)
    describe("[PreviewerSwitch:new]", function()
        it("creates single command previewer", function()
            local ps = general.PreviewerSwitch:new(
                "single",
                "pipeline",
                PreviewerConfig:make({
                    previewer = function()
                        return "ls -1"
                    end,
                })
            )
            assert_eq(type(ps), "table")
            assert_false(vim.tbl_isempty(ps))
            assert_eq(type(ps.previewers), "table")
            assert_false(vim.tbl_isempty(ps.previewers))
            assert_eq(type(ps.previewers.default), "function")
            assert_eq(ps.previewers.default(), "ls -1")
            assert_eq(ps.previewer_types.default, "command")
            assert_eq(ps:switch("default"), nil)
        end)
        it("creates multiple command previewer", function()
            local ps = general.PreviewerSwitch:new("single", "pipeline", {
                p1 = PreviewerConfig:make({
                    previewer = function()
                        return "p1"
                    end,
                }),
                p2 = PreviewerConfig:make({
                    previewer = function()
                        return "p2"
                    end,
                }),
            })
            assert_eq(type(ps), "table")
            assert_false(vim.tbl_isempty(ps))

            assert_eq(type(ps.previewers), "table")
            assert_false(vim.tbl_isempty(ps.previewers))
            assert_eq(type(ps.previewers.p1), "function")
            assert_eq(ps.previewers.p1(), "p1")
            assert_eq(ps.previewer_types.p1, "command")
            assert_eq(ps:switch("p1"), nil)

            assert_eq(type(ps.previewers), "table")
            assert_false(vim.tbl_isempty(ps.previewers))
            assert_eq(type(ps.previewers.p2), "function")
            assert_eq(ps.previewers.p2(), "p2")
            assert_eq(ps.previewer_types.p2, "command")
            assert_eq(ps:switch("p2"), nil)
        end)
    end)
    describe("[render_help]", function()
        it("renders1", function()
            local actual = general.render_help("doc1", "bs")
            print(string.format("render help1:%s\n", actual))
            assert_true(actual:gmatch("to doc1") ~= nil)
            assert_true(actual:gmatch("BS") ~= nil)
            assert_true(
                utils.string_find(actual, "to doc1")
                    > utils.string_find(actual, "BS")
            )
        end)
        it("renders2", function()
            local actual = general.render_help("do_it", "ctrl")
            print(string.format("render help2:%s\n", actual))
            assert_true(actual:gmatch("to do it") ~= nil)
            assert_true(actual:gmatch("CTRL") ~= nil)
            assert_true(
                utils.string_find(actual, "to do it")
                    > utils.string_find(actual, "CTRL")
            )
        end)
        it("renders3", function()
            local actual = general.render_help("ok_ok", "alt")
            print(string.format("render help3:%s\n", actual))
            assert_true(actual:gmatch("to ok ok") ~= nil)
            assert_true(actual:gmatch("ALT") ~= nil)
            assert_true(
                utils.string_find(actual, "to ok ok")
                    > utils.string_find(actual, "ALT")
            )
        end)
    end)
    describe("[skip_help]", function()
        it("skip1", function()
            local actual = general.skip_help(nil, "bs")
            assert_false(actual)
        end)
        it("skip2", function()
            local actual = general.skip_help({}, "bs")
            assert_false(actual)
        end)
        it("skip3", function()
            local actual = general.skip_help({ "bs" }, "bs")
            assert_true(actual)
        end)
    end)
    describe("[make_help_doc]", function()
        it("make1", function()
            local action_configs = {
                action1 = {
                    key = "ctrl-l",
                },
                upper = {
                    key = "ctrl-u",
                },
            }
            local actual = general.make_help_doc(action_configs, {})
            assert_eq(type(actual), "table")
            assert_eq(#actual, 2)
            assert_true(
                utils.string_find(actual[1], "to action1")
                    > utils.string_find(actual[1], "CTRL-L")
            )
            assert_true(utils.string_endswith(actual[1], "to action1"))
            assert_true(
                utils.string_find(actual[2], "to upper")
                    > utils.string_find(actual[2], "CTRL-U")
            )
            assert_true(utils.string_endswith(actual[2], "to upper"))
        end)
        it("make2", function()
            local action_configs = {
                action1 = {
                    key = "ctrl-l",
                },
                upper = {
                    key = "ctrl-u",
                },
                goto_inter = {
                    key = "alt-p",
                },
            }
            local actual = general.make_help_doc(action_configs, {})
            assert_eq(type(actual), "table")
            assert_eq(#actual, 3)
            assert_true(
                utils.string_find(actual[1], "to action1")
                    > utils.string_find(actual[1], "CTRL-L")
            )
            assert_true(utils.string_endswith(actual[1], "to action1"))
            assert_true(
                utils.string_find(actual[2], "to goto inter")
                    > utils.string_find(actual[2], "ALT-P")
            )
            assert_true(utils.string_endswith(actual[2], "to goto inter"))
            assert_true(
                utils.string_find(actual[3], "to upper")
                    > utils.string_find(actual[3], "CTRL-U")
            )
            assert_true(utils.string_endswith(actual[3], "to upper"))
        end)
    end)
end)
