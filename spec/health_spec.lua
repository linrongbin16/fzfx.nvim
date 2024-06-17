local cwd = vim.fn.getcwd()

describe("health", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
    vim.health = {
      start = function() end,
      ok = function() end,
      error = function() end,
      warn = function() end,
    }
  end)

  local health = require("fzfx.health")
  local tbl = require("fzfx.commons.tbl")
  local str = require("fzfx.commons.str")

  describe("[check]", function()
    it("run", function()
      health.check()
    end)
    it("_misses", function()
      local actual1 = health._misses({ "a", "b", "c" })
      assert_eq(actual1, "Missing 'a', 'b', 'c'")
      local actual2 = health._misses({})
      assert_eq(actual2, "Missing ")
    end)
    it("_versions", function()
      for _, config in ipairs(health.HEALTH_CHECKS) do
        local configured_items = tbl.List:copy(config.items)
        local items = configured_items:filter(function(
          item --[[@as fzfx.HealthCheckItem]]
        )
          return item.cond
        end)

        if not items:empty() then
          local actual = health._versions(items)
          print(string.format("actual:%s\n", vim.inspect(actual)))
          assert_true(str.startswith(actual, "\n  - ") or str.empty(actual))
        end
      end
    end)
    it("_summary", function()
      for _, config in ipairs(health.HEALTH_CHECKS) do
        local configured_items = tbl.List:copy(config.items)
        local items = configured_items:filter(function(
          item --[[@as fzfx.HealthCheckItem]]
        )
          return item.cond
        end)

        if not items:empty() then
          local actual = health._summary(items)
          print(string.format("actual:%s\n", vim.inspect(actual)))
          assert_true(str.startswith(actual, "Found "))
        end
      end
    end)
  end)
end)
