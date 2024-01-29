local async = require("fzfx.commons.async")
local spawn = require("fzfx.commons.spawn")

local M = {}

--- @alias fzfx.AsyncSpawnOpts {on_stdout:commons.SpawnLineProcessor, on_stderr:commons.SpawnLineProcessor, [string]:any}
--- @alias fzfx.AsyncSpawnOnExit fun(completed:vim.SystemCompleted):nil
--- @async
--- @type fun(cmd:string[],opts:fzfx.AsyncSpawnOpts):vim.SystemCompleted
M.aspawn = async.wrap(function(cmd, opts, callback)
  return spawn.run(cmd, opts, callback)
end, 3)
