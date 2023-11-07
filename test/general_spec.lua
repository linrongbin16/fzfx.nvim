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
    local utils = require("fzfx.utils")
    local path = require("fzfx.path")
    local schema = require("fzfx.schema")
    local conf = require("fzfx.config")
    local json = require("fzfx.json")
    conf.setup()

    local function get_provider_metafile(name)
        return path.join(
            conf.get_config().cache.dir,
            "provider_metafile_" .. name
        )
    end

    local function get_provider_resultfile(name)
        return path.join(
            conf.get_config().cache.dir,
            "provider_resultfile_" .. name
        )
    end

    describe("[ProviderSwitch:new]", function()
        it("creates single plain provider", function()
            local ps = general.ProviderSwitch:new("single_test", "pipeline", {
                key = "ctrl-k",
                provider = "ls -1",
            })
            assert_eq(type(ps), "table")
            assert_false(vim.tbl_isempty(ps))
            assert_eq(type(ps.provider_configs.default), "table")
            assert_false(vim.tbl_isempty(ps.provider_configs.default))
            assert_eq(ps.provider_configs.default.key, "ctrl-k")
            assert_eq(ps.provider_configs.default.provider, "ls -1")
            assert_eq(ps.provider_configs.default.provider_type, "plain")
            assert_eq(ps:switch("default"), nil)
            assert_eq(ps:provide("default", "hello", {}), "plain")
            if not github_actions then
                local meta1 =
                    utils.readfile(get_provider_metafile("single_test"))
                local result1 =
                    utils.readfile(get_provider_resultfile("single_test"))
                print(string.format("metafile1:%s\n", meta1))
                local metajson1 = json.decode(meta1) --[[@as table]]
                assert_eq(type(metajson1), "table")
                assert_eq(metajson1.pipeline, "default")
                assert_eq(metajson1.provider_type, "plain")
                print(string.format("resultfile1:%s\n", result1))
                assert_eq(result1, "ls -1")
            end
        end)
        it("creates single plain_list provider", function()
            local ps = general.ProviderSwitch:new(
                "single_plain_list_test",
                "pipeline",
                {
                    key = "ctrl-k",
                    provider = { "ls", "-lh", "~" },
                }
            )
            assert_eq(type(ps), "table")
            assert_false(vim.tbl_isempty(ps))
            assert_eq(type(ps.provider_configs.default), "table")
            assert_false(vim.tbl_isempty(ps.provider_configs.default))
            assert_eq(ps.provider_configs.default.key, "ctrl-k")
            assert_eq(type(ps.provider_configs.default.provider), "table")
            assert_eq(#ps.provider_configs.default.provider, 3)
            assert_eq(ps.provider_configs.default.provider[1], "ls")
            assert_eq(ps.provider_configs.default.provider[2], "-lh")
            assert_eq(ps.provider_configs.default.provider[3], "~")
            assert_eq(ps.provider_configs.default.provider_type, "plain_list")
            assert_eq(ps:switch("default"), nil)
            assert_eq(ps:provide("default", "hello", {}), "plain_list")
            if not github_actions then
                local meta2 = utils.readfile(
                    get_provider_metafile("single_plain_list_test")
                )
                local result2 = utils.readfile(
                    get_provider_resultfile("single_plain_list_test")
                )
                print(string.format("metafile2:%s\n", meta2))
                local metajson1 = json.decode(meta2) --[[@as table]]
                assert_eq(type(metajson1), "table")
                assert_eq(metajson1.pipeline, "default")
                assert_eq(metajson1.provider_type, "plain_list")
                print(string.format("resultfile2:%s\n", result2))
                local resultjson2 = json.decode(result2) --[[@as table]]
                assert_eq(type(resultjson2), "table")
                assert_eq(#resultjson2, 3)
                assert_eq(resultjson2[1], "ls")
                assert_eq(resultjson2[2], "-lh")
                assert_eq(resultjson2[3], "~")
            end
        end)
        it("creates multiple plain providers", function()
            local ps = general.ProviderSwitch:new("multiple_test", "pipeline", {
                p1 = {
                    key = "ctrl-p",
                    provider = "p1",
                },
                p2 = {
                    key = "ctrl-q",
                    provider = { "p2", "p3", "p4" },
                },
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
            assert_eq(ps:provide("p1", "hello", {}), "plain")
            if not github_actions then
                local meta3 =
                    utils.readfile(get_provider_metafile("multiple_test"))
                local result3 =
                    utils.readfile(get_provider_resultfile("multiple_test"))
                print(string.format("metafile3:%s\n", meta3))
                local metajson1 = json.decode(meta3) --[[@as table]]
                assert_eq(type(metajson1), "table")
                assert_eq(metajson1.pipeline, "p1")
                assert_eq(metajson1.provider_type, "plain")
                print(string.format("resultfile3:%s\n", result3))
                assert_eq(result3, "p1")
            end

            assert_eq(type(ps.provider_configs.p2), "table")
            assert_false(vim.tbl_isempty(ps.provider_configs.p2))
            assert_eq(ps.provider_configs.p2.key, "ctrl-q")
            assert_eq(type(ps.provider_configs.p2.provider), "table")
            assert_eq(type(ps.provider_configs.p2.provider), "table")
            assert_eq(#ps.provider_configs.p2.provider, 3)
            assert_eq(ps.provider_configs.p2.provider[1], "p2")
            assert_eq(ps.provider_configs.p2.provider[2], "p3")
            assert_eq(ps.provider_configs.p2.provider[3], "p4")
            assert_eq(ps.provider_configs.p2.provider_type, "plain_list")
            assert_eq(ps:switch("p2"), nil)
            assert_eq(ps:provide("p2", "hello", {}), "plain_list")
            if not github_actions then
                local meta4 =
                    utils.readfile(get_provider_metafile("multiple_test"))
                local result4 =
                    utils.readfile(get_provider_resultfile("multiple_test"))
                print(string.format("metafile4:%s\n", meta4))
                local metajson1 = json.decode(meta4) --[[@as table]]
                assert_eq(type(metajson1), "table")
                assert_eq(metajson1.pipeline, "p2")
                assert_eq(metajson1.provider_type, "plain_list")
                print(string.format("resultfile4:%s\n", result4))
                local resultjson4 = json.decode(result4) --[[@as table]]
                assert_eq(type(resultjson4), "table")
                assert_eq(#resultjson4, 3)
                assert_eq(resultjson4[1], "p2")
                assert_eq(resultjson4[2], "p3")
                assert_eq(resultjson4[3], "p4")
            end
        end)
    end)
    describe("[PreviewerSwitch:provide]", function()
        it("is a plain/plain_list provider", function()
            local ps = general.PreviewerSwitch:new("plain_test", "p1", {
                p1 = {
                    previewer = function()
                        return "ls -lh"
                    end,
                },
                p2 = {
                    previewer = function()
                        return { "ls", "-lha", "~" }
                    end,
                    previewer_type = "command_list",
                },
            })
            print(
                string.format(
                    "GITHUB_ACTIONS:%s\n",
                    os.getenv("GITHUB_ACTIONS")
                )
            )
            assert_eq(ps:preview("p1", "hello", {}), "command")
            if not github_actions then
                local meta1 = utils.readfile(
                    path.join(
                        vim.fn.stdpath("data"),
                        "fzfx.nvim",
                        "previewer_metafile_plain_test"
                    )
                )
                local result1 = utils.readfile(
                    path.join(
                        vim.fn.stdpath("data"),
                        "fzfx.nvim",
                        "previewer_resultfile_plain_test"
                    )
                )
                print(string.format("metafile1:%s\n", meta1))
                local metajson1 = json.decode(meta1) --[[@as table]]
                assert_eq(type(metajson1), "table")
                assert_eq(metajson1.pipeline, "p1")
                assert_eq(metajson1.previewer_type, "command")
                print(string.format("resultfile1:%s\n", result1))
                assert_eq(result1, "ls -lh")
            end
            ps:switch("p2")
            assert_eq(ps:preview("p2", "world", {}), "command_list")
            if not github_actions then
                local meta2 = utils.readfile(
                    path.join(
                        vim.fn.stdpath("data"),
                        "fzfx.nvim",
                        "previewer_metafile_plain_test"
                    )
                )
                local result2 = utils.readfile(
                    path.join(
                        vim.fn.stdpath("data"),
                        "fzfx.nvim",
                        "previewer_resultfile_plain_test"
                    )
                )
                print(string.format("metafile2:%s\n", meta2))
                local metajson2 = json.decode(meta2) --[[@as table]]
                assert_eq(type(metajson2), "table")
                assert_eq(metajson2.pipeline, "p2")
                assert_eq(metajson2.previewer_type, "command_list")
                print(string.format("resultfile2:%s\n", result2))
                local resultjson2 = json.decode(result2) --[[@as table]]
                assert_eq(type(resultjson2), "table")
                assert_eq(#resultjson2, 3)
                assert_eq(resultjson2[1], "ls")
                assert_eq(resultjson2[2], "-lha")
                assert_eq(resultjson2[3], "~")
            end
        end)
        it("is a command/command_list provider", function()
            local ps = general.PreviewerSwitch:new("command_test", "p1", {
                p1 = {
                    previewer = function()
                        return "ls -lh"
                    end,
                    previewer_type = schema.ProviderTypeEnum.COMMAND,
                },
                p2 = {
                    previewer = function()
                        return { "ls", "-lha", "~" }
                    end,
                    previewer_type = schema.ProviderTypeEnum.COMMAND_LIST,
                },
            })
            assert_eq(ps:preview("p1", "hello", {}), "command")
            if not github_actions then
                local meta1 = utils.readfile(
                    path.join(
                        vim.fn.stdpath("data"),
                        "fzfx.nvim",
                        "previewer_metafile_command_test"
                    )
                )
                local result1 = utils.readfile(
                    path.join(
                        vim.fn.stdpath("data"),
                        "fzfx.nvim",
                        "previewer_resultfile_command_test"
                    )
                )
                print(string.format("metafile:%s\n", meta1))
                local metajson1 = json.decode(meta1) --[[@as table]]
                assert_eq(type(metajson1), "table")
                assert_eq(metajson1.pipeline, "p1")
                assert_eq(metajson1.previewer_type, "command")
                print(string.format("resultfile:%s\n", result1))
                assert_eq(result1, "ls -lh")
            end
            ps:switch("p2")
            assert_eq(ps:preview("p2", "world", {}), "command_list")
            if not github_actions then
                local meta2 = utils.readfile(
                    path.join(
                        vim.fn.stdpath("data"),
                        "fzfx.nvim",
                        "previewer_metafile_command_test"
                    )
                )
                local result2 = utils.readfile(
                    path.join(
                        vim.fn.stdpath("data"),
                        "fzfx.nvim",
                        "previewer_resultfile_command_test"
                    )
                )
                print(string.format("metafile:%s\n", meta2))
                local metajson2 = json.decode(meta2) --[[@as table]]
                assert_eq(type(metajson2), "table")
                assert_eq(metajson2.pipeline, "p2")
                assert_eq(metajson2.previewer_type, "command_list")
                print(string.format("resultfile:%s\n", result2))
                local resultjson2 = json.decode(result2) --[[@as table]]
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
            local ps = general.PreviewerSwitch:new("single", "pipeline", {
                previewer = function()
                    return "ls -1"
                end,
            })
            assert_eq(type(ps), "table")
            assert_false(vim.tbl_isempty(ps))
            assert_eq(type(ps.previewer_configs), "table")
            assert_false(vim.tbl_isempty(ps.previewer_configs))
            assert_eq(type(ps.previewer_configs.default.previewer), "function")
            assert_eq(ps.previewer_configs.default.previewer(), "ls -1")
            assert_eq(ps.previewer_configs.default.previewer_type, "command")
            assert_eq(ps:switch("default"), nil)
        end)
        it("creates multiple command previewer", function()
            local ps = general.PreviewerSwitch:new("single", "pipeline", {
                p1 = {
                    previewer = function()
                        return "p1"
                    end,
                },
                p2 = {
                    previewer = function()
                        return "p2"
                    end,
                },
            })
            assert_eq(type(ps), "table")
            assert_false(vim.tbl_isempty(ps))
            assert_eq(type(ps.previewer_configs), "table")
            assert_false(vim.tbl_isempty(ps.previewer_configs))
            assert_eq(type(ps.previewer_configs.p1.previewer), "function")
            assert_eq(ps.previewer_configs.p1.previewer(), "p1")
            assert_eq(ps.previewer_configs.p1.previewer_type, "command")
            assert_eq(ps:switch("p1"), nil)

            assert_eq(type(ps.previewer_configs), "table")
            assert_false(vim.tbl_isempty(ps.previewer_configs))
            assert_eq(type(ps.previewer_configs.p2.previewer), "function")
            assert_eq(ps.previewer_configs.p2.previewer(), "p2")
            assert_eq(ps.previewer_configs.p2.previewer_type, "command")
            assert_eq(ps:switch("p2"), nil)
        end)
    end)
    describe("[_render_help]", function()
        it("renders1", function()
            local actual = general._render_help("doc1", "bs")
            print(string.format("render help1:%s\n", actual))
            assert_true(actual:gmatch("to doc1") ~= nil)
            assert_true(actual:gmatch("BS") ~= nil)
            assert_true(
                utils.string_find(actual, "to doc1")
                    > utils.string_find(actual, "BS")
            )
        end)
        it("renders2", function()
            local actual = general._render_help("do_it", "ctrl")
            print(string.format("render help2:%s\n", actual))
            assert_true(actual:gmatch("to do it") ~= nil)
            assert_true(actual:gmatch("CTRL") ~= nil)
            assert_true(
                utils.string_find(actual, "to do it")
                    > utils.string_find(actual, "CTRL")
            )
        end)
        it("renders3", function()
            local actual = general._render_help("ok_ok", "alt")
            print(string.format("render help3:%s\n", actual))
            assert_true(actual:gmatch("to ok ok") ~= nil)
            assert_true(actual:gmatch("ALT") ~= nil)
            assert_true(
                utils.string_find(actual, "to ok ok")
                    > utils.string_find(actual, "ALT")
            )
        end)
    end)
    describe("[_should_skip_help]", function()
        it("skip1", function()
            local actual = general._should_skip_help(nil, "bs")
            assert_false(actual)
        end)
        it("skip2", function()
            local actual = general._should_skip_help({}, "bs")
            assert_false(actual)
        end)
        it("skip3", function()
            local actual = general._should_skip_help({ "bs" }, "bs")
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
    describe("[make_cache_filename]", function()
        it("is debug mode", function()
            vim.env._FZFX_NVIM_DEBUG_ENABLE = 1
            assert_eq(
                general.make_cache_filename(
                    "provider",
                    "switch",
                    "meta",
                    "live_grep"
                ),
                path.join(
                    conf.get_config().cache.dir,
                    "provider_switch_meta_live_grep"
                )
            )
        end)
        it("is not debug mode", function()
            vim.env._FZFX_NVIM_DEBUG_ENABLE = 0
            local actual = general.make_cache_filename(
                "provider",
                "switch",
                "meta",
                "live_grep"
            )
            print(
                string.format(
                    "make cache filename (non-debug):%s",
                    vim.inspect(actual)
                )
            )
            assert_true(
                actual
                    ~= path.join(
                        vim.fn.stdpath("data"),
                        "provider_switch_meta_live_grep"
                    )
            )
        end)
    end)
    describe("[make_provider_meta_opts]", function()
        it("makes without icon", function()
            local actual1 = general.make_provider_meta_opts("test1", {
                key = "test1",
                provider_type = "command",
            })
            assert_eq(type(actual1), "table")
            assert_eq(actual1.pipeline, "test1")
            assert_eq(actual1.provider_type, "command")
            assert_true(actual1.prepend_icon_by_ft == nil)
            local actual2 = general.make_provider_meta_opts("test2", {
                key = "test2",
                provider_type = "command_list",
                line_opts = {
                    prepend_icon_by_ft = false,
                },
            })
            assert_eq(type(actual2), "table")
            assert_eq(actual2.pipeline, "test2")
            assert_eq(actual1.provider_type, "command")
            assert_false(actual2.prepend_icon_by_ft)
        end)
        it("makes with icon", function()
            local actual = general.make_provider_meta_opts("test3", {
                key = "test3",
                provider_type = "list",
                line_opts = {
                    prepend_icon_by_ft = true,
                    prepend_icon_path_delimiter = ":",
                    prepend_icon_path_position = 1,
                },
            })
            assert_eq(type(actual), "table")
            assert_eq(actual.pipeline, "test3")
            assert_eq(actual.provider_type, "list")
            assert_true(actual.prepend_icon_by_ft)
            assert_eq(actual.prepend_icon_path_delimiter, ":")
            assert_eq(actual.prepend_icon_path_position, 1)
        end)
    end)
    describe("[make_previewer_meta_opts]", function()
        it("makes without icon", function()
            local actual1 = general.make_previewer_meta_opts("test1", {
                previewer = function() end,
                previewer_type = "command",
            })
            assert_eq(type(actual1), "table")
            assert_eq(actual1.pipeline, "test1")
            assert_eq(actual1.previewer_type, "command")
            local actual2 = general.make_previewer_meta_opts("test2", {
                previewer = function() end,
                previewer_type = "command_list",
            })
            assert_eq(type(actual2), "table")
            assert_eq(actual2.pipeline, "test2")
            assert_eq(actual2.previewer_type, "command_list")
        end)
        it("makes with icon", function()
            local actual = general.make_previewer_meta_opts("test3", {
                previewer = function() end,
                previewer_type = "list",
            })
            assert_eq(type(actual), "table")
            assert_eq(actual.pipeline, "test3")
            assert_eq(actual.previewer_type, "list")
        end)
    end)
end)
