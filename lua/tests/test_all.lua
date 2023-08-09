-- :lua MiniTest.run_file()

MiniTest.run({
    collect = {
        find_files = function()
            return {
                "lua/tests/test_ansi_color.lua",
                "lua/tests/test_env.lua",
                "lua/tests/test_hello.lua",
                "lua/tests/test_rgb_color.lua",
            }
        end,
    },
})
