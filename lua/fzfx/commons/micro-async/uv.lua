---@diagnostic disable
---@mod micro-async.uv

local a = require("fzfx.commons.micro-async")

local yield, callback, scheduled_wrap = a.yield, a.callback, a.scheduled_wrap

local luv = vim.uv or vim.loop

---Async vim.uv wrapper
local uv = {}

---@type async fun(path: string, entries: integer): err: string?, dir: luv_dir_t
uv.fs_opendir = function(path, entries)
  ---@diagnostic disable-next-line: param-type-mismatch
  return yield(luv.fs_opendir(path, callback(), entries))
end

---@type async fun(dir: luv_dir_t): err: string?, entries: uv.aliases.fs_readdir_entries[]
uv.fs_readdir = scheduled_wrap(luv.fs_readdir, 2)

---@type async fun(path: string): err: string?, path: string?
uv.fs_realpath = scheduled_wrap(luv.fs_realpath, 2)

---@type async fun(path: string): err: string?, path: string?
uv.fs_readlink = scheduled_wrap(luv.fs_readlink, 2)

---@type async fun(path: string, mode: integer): err: string?, permissions: boolean?
uv.fs_access = scheduled_wrap(luv.fs_access, 3)

---@type async fun(fd: integer, size: integer, offset: integer?): err: string?, data: string?
uv.fs_read = scheduled_wrap(luv.fs_read, 4)

---@type async fun(path: string, new_path: string): err: string?, success: boolean?
uv.fs_rename = scheduled_wrap(luv.fs_rename, 2)

---@type async fun(path: string, flags: integer | uv.aliases.fs_access_flags, mode: integer): err: string?, fs: integer?
uv.fs_open = scheduled_wrap(luv.fs_open, 4)

---@type async fun(template: string): err: string?, fd: integer?, path: string?
uv.fs_mkstemp = scheduled_wrap(luv.fs_mkstemp, 2)

---@type async fun(template: string): err: string?, path: string?
uv.fs_mkdtemp = scheduled_wrap(luv.fs_mkdtemp, 2)

---@type async fun(path: string): err: string?, success: boolean?
uv.fs_rmdir = scheduled_wrap(luv.fs_rmdir, 2)

---@type async fun(path: string, mode: integer): err: string?, success: boolean?
uv.fs_mkdir = scheduled_wrap(luv.fs_mkdir, 3)

---@type async fun(path: string, mode: integer): err: string?, success: boolean?
uv.fs_chmod = scheduled_wrap(luv.fs_chmod, 3)

---@type async fun(path: string, uid: integer, gid: integer): err: string?, success: boolean?
uv.fs_chown = scheduled_wrap(luv.fs_chown, 4)

---@type async fun(fd: integer, mode: integer): err: string?, success: boolean?
uv.fs_fchmod = scheduled_wrap(luv.fs_fchmod, 3)

---@type async fun(fd: integer, uid: integer, gid: integer): err: string?, success: boolean?
uv.fs_fchown = scheduled_wrap(luv.fs_fchown, 4)

---@type async fun(address: uv.aliases.getsockname_rtn)
uv.getnameinfo = scheduled_wrap(luv.getnameinfo, 2)

---@type async fun(path: string, new_path: string, flags: uv.aliases.fs_copyfile_flags): err: string?, success: boolean?
uv.fs_copyfile = scheduled_wrap(luv.fs_copyfile, 4)

---@type async fun(fd: integer, atime: integer, mtime: integer): err: string?, success: boolean?
uv.fs_futime = scheduled_wrap(luv.fs_futime, 4)

---@type async fun(fd: integer, offset: integer): err: string?, success: boolean?
uv.fs_ftruncate = scheduled_wrap(luv.fs_ftruncate, 3)

---@type async fun(path: string, new_path: string): err: string?, success: boolean?
uv.fs_link = scheduled_wrap(luv.fs_link, 3)

---@type async fun(path: string): err: string?, success: boolean?
uv.fs_unlink = scheduled_wrap(luv.fs_unlink, 2)

---@type async fun(fd: integer, data: string | string[], offset: integer?): err: string?, success: boolean?
uv.fs_write = scheduled_wrap(luv.fs_write, 4)

---@type async fun(path: string, newpath: string, flags: integer | uv.aliases.fs_symlink_flags): err: string?, success: boolean?
uv.fs_symlink = scheduled_wrap(luv.fs_symlink, 3)

---@type async fun(path: string, atime: integer, mtime: integer): err: string?, success: boolean?
uv.fs_lutime = scheduled_wrap(luv.fs_lutime, 4)

---@type async fun(path: string): err: string?, stat: uv.aliases.fs_stat_table
uv.fs_stat = scheduled_wrap(luv.fs_stat, 2)

---@type async fun(path: string): err: string?, stat: uv_fs_t?
uv.fs_scandir = scheduled_wrap(luv.fs_scandir, 2)

---@type async fun(path: string): err: string?, stat: uv.aliases.fs_statfs_stats
uv.fs_statfs = scheduled_wrap(luv.fs_statfs, 2)

---@type async fun(fd: integer): err: string?, success: boolean?
uv.fs_fsync = scheduled_wrap(luv.fs_fsync, 2)

---@type async fun(out_fd: integer, in_fd: integer, in_offset: integer, size: integer): err: string?, bytes: integer?
uv.fs_sendfile = scheduled_wrap(luv.fs_sendfile, 4)

---@type async fun(fd: integer): err: string?, success: boolean?
uv.fs_fdatasync = scheduled_wrap(luv.fs_fdatasync, 2)

---@type async fun(fd: integer): err: string?, success: boolean?
uv.fs_close = scheduled_wrap(luv.fs_close, 2)

---@type async fun(path: string, atime: integer, mtime: integer): err: string?, success: boolean?
uv.fs_utime = scheduled_wrap(luv.fs_utime, 4)

---@type async fun(fn: fun(...:uv.aliases.threadargs):...: uv.aliases.threadargs): luv_work_ctx_t
uv.new_work = function(fn)
  return luv.new_work(fn, callback())
end

---@type async fun(work: luv_work_ctx_t, ...:uv.aliases.threadargs): ...: uv.aliases.threadargs
uv.queue_work = function(work, ...)
  return yield(luv.queue_work(work, ...))
end

return uv
