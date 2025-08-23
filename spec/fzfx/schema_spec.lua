local cwd = vim.fn.getcwd()

describe("schema", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local schema = require("fzfx.schema")
  local ProviderTypeEnum = schema.ProviderTypeEnum
  local PreviewerTypeEnum = schema.PreviewerTypeEnum

  describe("[ProviderConfig]", function()
    it("makes a plain provider", function()
      local plain_key = "plain"
      local plain_provider = "ls -la"
      local plain_provider_type = ProviderTypeEnum.PLAIN_COMMAND_STRING
      local plain = {
        key = plain_key,
        provider = plain_provider,
        provider_type = ProviderTypeEnum.PLAIN_COMMAND_STRING,
      }
      assert_eq(type(plain), "table")
      assert_true(schema.is_provider_config(plain))
      assert_eq(plain.key, plain_key)
      assert_eq(plain.provider, plain_provider)
      assert_eq(plain.provider_type, plain_provider_type)
    end)
    it("makes a plain_list provider", function()
      local plain_key = "plain"
      local plain_provider = { "ls", "-la" }
      local plain = {
        key = plain_key,
        provider = plain_provider,
        provider_type = ProviderTypeEnum.PLAIN_COMMAND_ARRAY,
      }
      assert_eq(type(plain), "table")
      assert_true(schema.is_provider_config(plain))
      assert_eq(plain.key, plain_key)
      assert_eq(plain.provider, plain_provider)
      assert_true(plain.provider_type == ProviderTypeEnum.PLAIN_COMMAND_ARRAY)
    end)
  end)
  describe("[PreviewerConfig]", function()
    it("makes a command previewer", function()
      local command_previewer = function(line)
        return string.format("cat %s", line)
      end
      local command_previewer_type = "command"
      local command = {
        previewer = command_previewer,
        previewer_type = command_previewer_type,
      }
      assert_eq(type(command), "table")
      assert_true(schema.is_previewer_config(command))
      assert_eq(type(command.previewer), "function")
      assert_eq(command.previewer(), command_previewer())
      assert_eq(command.previewer_type, command_previewer_type)
    end)
  end)
  describe("[VariantConfig]", function()
    it("makes a variant", function()
      local variant = {
        name = "command",
        feed = "args",
      }
      assert_eq(type(variant), "table")
      assert_true(schema.is_variant_config(variant))
      assert_eq(variant.name, "command")
    end)
  end)
  describe("[is_variant_config]", function()
    it("is variant config", function()
      local obj = {
        name = "FzfxLiveGrep",
        feed = "args",
      }
      assert_true(schema.is_variant_config(obj))
      local obj2 = {
        name = "FzfxLiveGrep",
        feed = "args",
      }
      assert_true(schema.is_variant_config(obj2))
    end)
    it("is not command config", function()
      local obj1 = {}
      assert_false(schema.is_variant_config(obj1))
      local obj2 = {
        key = "FzfxLiveGrep",
      }
      assert_false(schema.is_variant_config(obj2))
    end)
  end)
  describe("[is_provider_config]", function()
    it("is provider config", function()
      local p1 = {
        key = "ctrl-l",
        provider = "ls -lh",
      }
      local p2 = {
        key = "ctrl-g",
        provider = { "ls", "-lh" },
      }
      local p3 = {
        key = "ctrl-k",
        provider = function()
          return { "ls", "-lh" }
        end,
      }
      assert_true(schema.is_provider_config(p1))
      assert_true(schema.is_provider_config(p2))
      assert_true(schema.is_provider_config(p3))
      local p4 = {
        key = "ctrl-l",
        provider = "ls -lh",
      }
      local p5 = {
        key = "ctrl-g",
        provider = { "ls", "-lh" },
      }
      local p6 = {
        key = "ctrl-k",
        provider = function()
          return { "ls", "-lh" }
        end,
      }
      assert_true(schema.is_provider_config(p4))
      assert_true(schema.is_provider_config(p5))
      assert_true(schema.is_provider_config(p6))
    end)
    it("is not provider config", function()
      local p1 = {}
      assert_false(schema.is_provider_config(p1))
      local p2 = {
        name = "FzfxLiveGrep",
      }
      assert_false(schema.is_provider_config(p2))
    end)
  end)
  describe("[is_previewer_config]", function()
    it("is previewer config", function()
      local p1 = {
        previewer = function()
          return "ls -lh"
        end,
      }
      local p2 = {
        previewer = function()
          return { "ls", "-lh", "~" }
        end,
        previewer_type = "command_list",
      }
      local p3 = {
        previewer = function()
          return "ls -lh"
        end,
        previewer_type = "command",
      }
      assert_true(schema.is_previewer_config(p1))
      assert_true(schema.is_previewer_config(p2))
      assert_true(schema.is_previewer_config(p3))
      local p4 = {
        previewer = function()
          return "ls -lh"
        end,
      }
      local p5 = {
        previewer = function()
          return { "ls", "-lh" }
        end,
        previewer_type = "command_list",
      }
      assert_true(schema.is_previewer_config(p4))
      assert_true(schema.is_previewer_config(p5))
    end)
    it("is not previewer config", function()
      local p1 = {}
      assert_false(schema.is_previewer_config(p1))
      local p2 = {
        name = "FzfxLiveGrep",
      }
      assert_false(schema.is_previewer_config(p2))
    end)
  end)
end)
