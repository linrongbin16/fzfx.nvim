# Known Issues

## Previewer

### 1. Cannot use both nvim buffer previewer and fzf's builtin previewer in the same command?

Yes, this is a technical limitation for previewer. Since the gap between nvim buffer and fzf's builtin-preview is quite big, the whole architecture is different, so switching previewer's implementation requires a lot of effort.

While we usually only need the buffer previewer to preview file contents, so it should not be a serious issue. Please avoid such kind of configurations.

## File Explorer

### 1. Cannot go upper in empty directory?

When in normal variant (not showing hidden files/directories), once cd into an empty directory (with `CTRL-L`) you will cannot go upper (with `CTRL-H`).

Please switch to hidden variant (with `CTRL-U`), e.g. showing hidden files/directories, thus there will have two lines `.` and `..`, then you could go upper (with `CTRL-H`).
