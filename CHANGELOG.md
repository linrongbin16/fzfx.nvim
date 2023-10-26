# Changelog

## [2.0.1](https://github.com/linrongbin16/fzfx.nvim/compare/v2.0.0...v2.0.1) (2023-10-26)


### Bug Fixes

* **required:** set minimal required Neovim version to 0.7 ([#320](https://github.com/linrongbin16/fzfx.nvim/issues/320)) ([3b36751](https://github.com/linrongbin16/fzfx.nvim/commit/3b36751c449ef9c5ce68dcd6f2dbd62c0e2f0151))


### Performance Improvements

* **test:** improve test coverage ([#316](https://github.com/linrongbin16/fzfx.nvim/issues/316)) ([29ebe78](https://github.com/linrongbin16/fzfx.nvim/commit/29ebe785ce481f3c75f763979831d831e70d50d1))

## [2.0.0](https://github.com/linrongbin16/fzfx.nvim/compare/v1.5.0...v2.0.0) (2023-10-25)


### ⚠ BREAKING CHANGES

* **drop:** drop deprecated! ([#308](https://github.com/linrongbin16/fzfx.nvim/issues/308))

### Bug Fixes

* **bin:** setup log at first ([#309](https://github.com/linrongbin16/fzfx.nvim/issues/309)) ([a090851](https://github.com/linrongbin16/fzfx.nvim/commit/a0908513eff3457c16c2cd1a3597d02951ff6c58))


### Performance Improvements

* **drop:** drop deprecated! ([#308](https://github.com/linrongbin16/fzfx.nvim/issues/308)) ([545d137](https://github.com/linrongbin16/fzfx.nvim/commit/545d137de12872bf48f3061e59262e5c969abb2d))

## [1.5.0](https://github.com/linrongbin16/fzfx.nvim/compare/v1.4.0...v1.5.0) (2023-10-24)


### Features

* **keymaps:** add 'FzfxKeyMaps' to search vim keymaps ([#306](https://github.com/linrongbin16/fzfx.nvim/issues/306)) ([f43e70f](https://github.com/linrongbin16/fzfx.nvim/commit/f43e70f3ba7ab1132dfd65fbcf71db6bfc11912b))

## [1.4.0](https://github.com/linrongbin16/fzfx.nvim/compare/v1.3.0...v1.4.0) (2023-10-23)


### Features

* **actions:** add 'setqflist' ([#290](https://github.com/linrongbin16/fzfx.nvim/issues/290)) ([1284639](https://github.com/linrongbin16/fzfx.nvim/commit/1284639770c907fe7d850c5b05ddeb74a8db552e))
* add parse_file/parse_grep line helpers ([#222](https://github.com/linrongbin16/fzfx.nvim/issues/222)) ([5a503da](https://github.com/linrongbin16/fzfx.nvim/commit/5a503da25aec9a07ebde12dedae03e71056445c1))
* add variants for file explorer ([#213](https://github.com/linrongbin16/fzfx.nvim/issues/213)) ([289b8b8](https://github.com/linrongbin16/fzfx.nvim/commit/289b8b80c1348e604f141551a1c4877aecc5315f))
* bg color ^& fix exec ([#22](https://github.com/linrongbin16/fzfx.nvim/issues/22)) ([1a86b34](https://github.com/linrongbin16/fzfx.nvim/commit/1a86b34afeaeca879f05d4f7ea5ef4698f0044b6))
* buffers ([#57](https://github.com/linrongbin16/fzfx.nvim/issues/57)) ([bd1e0dc](https://github.com/linrongbin16/fzfx.nvim/commit/bd1e0dc2432f10a7947c1718ea3cb9ce9d600f64))
* color ([5537884](https://github.com/linrongbin16/fzfx.nvim/commit/5537884769b20f1ddab63c7885323e82ea31ef0b))
* colors ([#62](https://github.com/linrongbin16/fzfx.nvim/issues/62)) ([72b2437](https://github.com/linrongbin16/fzfx.nvim/commit/72b243747f6c0418f5c6e45eba79450b1f224815))
* **commands:** add 'FzfxCommands' to search vim commands ([#287](https://github.com/linrongbin16/fzfx.nvim/issues/287)) ([997821b](https://github.com/linrongbin16/fzfx.nvim/commit/997821ba69b6587ba392e3f5c46cc7dd196f62da))
* debug command ([b0ac732](https://github.com/linrongbin16/fzfx.nvim/commit/b0ac73244ac4ecf78671e29bffd07c538a86b3b6))
* diagnostics ([#124](https://github.com/linrongbin16/fzfx.nvim/issues/124)) ([a610762](https://github.com/linrongbin16/fzfx.nvim/commit/a610762e579eb31fdabb6f837f788cb7e3e9fc3e))
* file explorer (ls) ([#210](https://github.com/linrongbin16/fzfx.nvim/issues/210)) ([212c789](https://github.com/linrongbin16/fzfx.nvim/commit/212c789dc424e97894eef6209bb18f829b0191d4))
* files ([bf42213](https://github.com/linrongbin16/fzfx.nvim/commit/bf42213be415d19123a5a6f6ef4412756755c3b3))
* files ([362065c](https://github.com/linrongbin16/fzfx.nvim/commit/362065c6a650c88fb737bdd06807fb9b61d83244))
* git blame & general ([#102](https://github.com/linrongbin16/fzfx.nvim/issues/102)) ([21f5a62](https://github.com/linrongbin16/fzfx.nvim/commit/21f5a622494143ad270c430d72ad5e4c37996df5))
* git branches ([#68](https://github.com/linrongbin16/fzfx.nvim/issues/68)) ([7f055d5](https://github.com/linrongbin16/fzfx.nvim/commit/7f055d5549a01ffac8f2389ccf7a9315d2f44442))
* git commits ([#97](https://github.com/linrongbin16/fzfx.nvim/issues/97)) ([ded9623](https://github.com/linrongbin16/fzfx.nvim/commit/ded9623463864f8d0d07d08ac83e858a32d7ba10))
* git files ([#64](https://github.com/linrongbin16/fzfx.nvim/issues/64)) ([d83a857](https://github.com/linrongbin16/fzfx.nvim/commit/d83a857d619292a36ee736b88971a86acc2b0680))
* handle whitespaces on path ([#20](https://github.com/linrongbin16/fzfx.nvim/issues/20)) ([f05107b](https://github.com/linrongbin16/fzfx.nvim/commit/f05107b10523edfccb49403007d2b7efab8f487c))
* icon!!! ([#31](https://github.com/linrongbin16/fzfx.nvim/issues/31)) ([668a820](https://github.com/linrongbin16/fzfx.nvim/commit/668a82042e972427be541dfde5adad3d5173ed12))
* improve cwd ([#214](https://github.com/linrongbin16/fzfx.nvim/issues/214)) ([cd6042f](https://github.com/linrongbin16/fzfx.nvim/commit/cd6042fda05841a7d00321cae7323754d7bccba1))
* list_index ([#221](https://github.com/linrongbin16/fzfx.nvim/issues/221)) ([cb61fd5](https://github.com/linrongbin16/fzfx.nvim/commit/cb61fd5524a73f3cf8f871d60222c0119ae91498))
* live grep ([67c2776](https://github.com/linrongbin16/fzfx.nvim/commit/67c2776b6b3be654856db8b5537279368c9baf90))
* live grep ([#7](https://github.com/linrongbin16/fzfx.nvim/issues/7)) ([fda0337](https://github.com/linrongbin16/fzfx.nvim/commit/fda0337ec5189021ed6a5e023b75099bc4be1f91))
* log ([ffe368b](https://github.com/linrongbin16/fzfx.nvim/commit/ffe368ba848c8ae95cc8b1af967bc2443c309222))
* **logs:** split shell command provider/previewer logs ([#303](https://github.com/linrongbin16/fzfx.nvim/issues/303)) ([5ed1bcd](https://github.com/linrongbin16/fzfx.nvim/commit/5ed1bcd6728000c7ec692e99603ae69ab82a2edd))
* lsp color ([#166](https://github.com/linrongbin16/fzfx.nvim/issues/166)) ([690bf7a](https://github.com/linrongbin16/fzfx.nvim/commit/690bf7a42099c53a34534a79d10aba1083d59892))
* lsp commands ([#170](https://github.com/linrongbin16/fzfx.nvim/issues/170)) ([7589a88](https://github.com/linrongbin16/fzfx.nvim/commit/7589a8885b088a17fdeef040d0c768c10298a300))
* lsp definitions ([#150](https://github.com/linrongbin16/fzfx.nvim/issues/150)) ([10f5bfc](https://github.com/linrongbin16/fzfx.nvim/commit/10f5bfc3179729a579086fe67c3aa8ff29d66b82))
* lsp diagnostics file path color ([#125](https://github.com/linrongbin16/fzfx.nvim/issues/125)) ([f24e578](https://github.com/linrongbin16/fzfx.nvim/commit/f24e578d21809b7bed4fc0f92cb4fb922fbc1777))
* passing rg raw optoins ([c36bf8a](https://github.com/linrongbin16/fzfx.nvim/commit/c36bf8aff1bc0e425c6bd0853e3809e245a9ecca))
* please-release ([#254](https://github.com/linrongbin16/fzfx.nvim/issues/254)) ([a1d2da4](https://github.com/linrongbin16/fzfx.nvim/commit/a1d2da467596f679da0565ac7223324f23e10362))
* plugin home dir ([a55718f](https://github.com/linrongbin16/fzfx.nvim/commit/a55718f81a346de3c095174630e828cbb8a84b76))
* PR template ([#247](https://github.com/linrongbin16/fzfx.nvim/issues/247)) ([0843fb5](https://github.com/linrongbin16/fzfx.nvim/commit/0843fb56554237eeb54e1486a6e249be8796e153))
* relative window ([#172](https://github.com/linrongbin16/fzfx.nvim/issues/172)) ([01caa8b](https://github.com/linrongbin16/fzfx.nvim/commit/01caa8bc6c0b5689b79773112ad79b99adc0527a))
* restore query ([9c1ec44](https://github.com/linrongbin16/fzfx.nvim/commit/9c1ec443e7f2b9f3530eee4529f7c52a9391cefc))
* rgb color codes ([#165](https://github.com/linrongbin16/fzfx.nvim/issues/165)) ([835ca8a](https://github.com/linrongbin16/fzfx.nvim/commit/835ca8acbb7227997621e8f44e5c56702d7633a7))
* row/col win_opts ([#12](https://github.com/linrongbin16/fzfx.nvim/issues/12)) ([bd24d0a](https://github.com/linrongbin16/fzfx.nvim/commit/bd24d0a107330648ced401acdf30c02bc438d64f))
* **schema:** add 'PreviewerConfig' detection ([#266](https://github.com/linrongbin16/fzfx.nvim/issues/266)) ([2bdcef7](https://github.com/linrongbin16/fzfx.nvim/commit/2bdcef7f82a55327851b6d3ecb5e48c53f08a691))
* switch unrestricted mode ([5500bb1](https://github.com/linrongbin16/fzfx.nvim/commit/5500bb176a789f88a01c3cca066c0eaa3abe4a69))
* throw error ([c4eef09](https://github.com/linrongbin16/fzfx.nvim/commit/c4eef090f92bf3f5c548f92c63e386416567cf65))
* utils ([4ab3a4f](https://github.com/linrongbin16/fzfx.nvim/commit/4ab3a4f2ad9e950f962cab727ad91cc207b3ff33))
* visual/cword ([f9fbb86](https://github.com/linrongbin16/fzfx.nvim/commit/f9fbb86798ef331a6bf42213e720cbf4f9706fce))
* windows named pipe ([62a425f](https://github.com/linrongbin16/fzfx.nvim/commit/62a425fb815bfd36bb720c08b55b50d450c306ce))
* yank/put ([#45](https://github.com/linrongbin16/fzfx.nvim/issues/45)) ([b3db7b1](https://github.com/linrongbin16/fzfx.nvim/commit/b3db7b18e0efd32a542f9af7bdd007af65801d4e))


### Bug Fixes

* `new_pipe` not working on Windows arm64 ([#160](https://github.com/linrongbin16/fzfx.nvim/issues/160)) ([6efd376](https://github.com/linrongbin16/fzfx.nvim/commit/6efd376b7d2f79d667fae69bd11d0054f9cdbd2b))
* **actions:** 'bdelete' filename containing whitespaces ([#277](https://github.com/linrongbin16/fzfx.nvim/issues/277)) ([d3faf5a](https://github.com/linrongbin16/fzfx.nvim/commit/d3faf5a24177e57f19fbd056bcb940d614405a2d))
* **actions:** edit rg/grep results that contains whitespaces on filename ([#272](https://github.com/linrongbin16/fzfx.nvim/issues/272)) ([a202d1f](https://github.com/linrongbin16/fzfx.nvim/commit/a202d1f2b850271d5ff680a3ce85fbff42efba85))
* base dir ([3dbf684](https://github.com/linrongbin16/fzfx.nvim/commit/3dbf6840ed66a2489848603781150858bcd7a95a))
* base dir ([cb72633](https://github.com/linrongbin16/fzfx.nvim/commit/cb72633721ae4e1e8addb05834dde24f1a9fa2e1))
* buffer path ([#158](https://github.com/linrongbin16/fzfx.nvim/issues/158)) ([b0dc926](https://github.com/linrongbin16/fzfx.nvim/commit/b0dc926826ae17d172d424f27bf31236686da9e1))
* buffers wrong locked ([#100](https://github.com/linrongbin16/fzfx.nvim/issues/100)) ([760b1eb](https://github.com/linrongbin16/fzfx.nvim/commit/760b1eb0ba5736dcdb2727c74d621bdf19f4c647))
* **buffers:** current buffer, doc ([#98](https://github.com/linrongbin16/fzfx.nvim/issues/98)) ([990d5bf](https://github.com/linrongbin16/fzfx.nvim/commit/990d5bfdf2c4a6979a23655110287fe787924f5d))
* check method support ([#168](https://github.com/linrongbin16/fzfx.nvim/issues/168)) ([5aec401](https://github.com/linrongbin16/fzfx.nvim/commit/5aec401fab4f91d2f6a7234389207e0d6d7f29a9))
* close spawn handler ([#209](https://github.com/linrongbin16/fzfx.nvim/issues/209)) ([0338d6d](https://github.com/linrongbin16/fzfx.nvim/commit/0338d6d45858a07fd9073c8e8e74e826c2b71090))
* compat `vim.split` on v0.5.0, refactor actions ([#184](https://github.com/linrongbin16/fzfx.nvim/issues/184)) ([fafddf5](https://github.com/linrongbin16/fzfx.nvim/commit/fafddf51e47dd3b3a07184d5841506c51ba96a91))
* **config:** use cache.dir instead of hard coding ([#260](https://github.com/linrongbin16/fzfx.nvim/issues/260)) ([6bf24d1](https://github.com/linrongbin16/fzfx.nvim/commit/6bf24d1b81b29c5f37cfebfcf38c83213146d8af))
* depress log ([#78](https://github.com/linrongbin16/fzfx.nvim/issues/78)) ([4e0958d](https://github.com/linrongbin16/fzfx.nvim/commit/4e0958d9d5964ac61463f7770238dda6b221909f))
* directory icon ([#41](https://github.com/linrongbin16/fzfx.nvim/issues/41)) ([3326dd2](https://github.com/linrongbin16/fzfx.nvim/commit/3326dd2ddb6c348ecd7100bcead33e90a126b80b))
* edit files actions on path containing whitespaces for fd/find/eza/ls results ([#258](https://github.com/linrongbin16/fzfx.nvim/issues/258)) ([2a2c1a9](https://github.com/linrongbin16/fzfx.nvim/commit/2a2c1a93f840d58310fcbfbafd6da0643f300778))
* edit grep ([#92](https://github.com/linrongbin16/fzfx.nvim/issues/92)) ([5f2f017](https://github.com/linrongbin16/fzfx.nvim/commit/5f2f017053b88d65e7566e49c587bbc37b3d8af8))
* expand filename to full path ([#244](https://github.com/linrongbin16/fzfx.nvim/issues/244)) ([296aaf9](https://github.com/linrongbin16/fzfx.nvim/commit/296aaf92c24da4c16fd4b317c1794bbe3f2784a1))
* filepath with whitespaces ([#219](https://github.com/linrongbin16/fzfx.nvim/issues/219)) ([4491695](https://github.com/linrongbin16/fzfx.nvim/commit/449169597bbdb70d233a4ccadb2502116bcad0dd))
* func ref ([433e5d3](https://github.com/linrongbin16/fzfx.nvim/commit/433e5d3174ad07885eeb669daf76f81c069deebb))
* fuzzy mode ([598b701](https://github.com/linrongbin16/fzfx.nvim/commit/598b701b82807d273a00b30ea292b002e3950808))
* fuzzy switch ([fcbdbbe](https://github.com/linrongbin16/fzfx.nvim/commit/fcbdbbe34e3b16b9c986ad35b99bd33cfb4c96c9))
* fzf mode query ([4a5d69f](https://github.com/linrongbin16/fzfx.nvim/commit/4a5d69fe776625e49cd23af09ed169844ab3065b))
* fzfx_base ([39aa3a8](https://github.com/linrongbin16/fzfx.nvim/commit/39aa3a870cdd4655425bb54810a2532634439f91))
* git checkout on remote branches ([#153](https://github.com/linrongbin16/fzfx.nvim/issues/153)) ([e04a06d](https://github.com/linrongbin16/fzfx.nvim/commit/e04a06db730acb802ac3a1d987fd10b52107c2d6))
* grep exclude hiddens ([#93](https://github.com/linrongbin16/fzfx.nvim/issues/93)) ([a3ae56b](https://github.com/linrongbin16/fzfx.nvim/commit/a3ae56b73cccdd1c10e7ee72efe2374268e95807))
* header ([f2f6f1c](https://github.com/linrongbin16/fzfx.nvim/commit/f2f6f1c7fa43db5e0b847c69506a4343ecf96875))
* **interactions:** cd into directory containing spaces ([#279](https://github.com/linrongbin16/fzfx.nvim/issues/279)) ([e9bde4a](https://github.com/linrongbin16/fzfx.nvim/commit/e9bde4a870eb4709e4867b5150649553bbaf8f0a))
* live grep override ([#231](https://github.com/linrongbin16/fzfx.nvim/issues/231)) ([baa15e1](https://github.com/linrongbin16/fzfx.nvim/commit/baa15e1d9bc49133c0fb91a5b59262e3c020ff58))
* lock header for ls ([#211](https://github.com/linrongbin16/fzfx.nvim/issues/211)) ([3388d95](https://github.com/linrongbin16/fzfx.nvim/commit/3388d95f6b5324f01db9c65b814b62eb826cd106))
* log echo ([#55](https://github.com/linrongbin16/fzfx.nvim/issues/55)) ([1ed20c9](https://github.com/linrongbin16/fzfx.nvim/commit/1ed20c9204c91358b92a7257ff128343dc303d9b))
* lsp definitions color ([#159](https://github.com/linrongbin16/fzfx.nvim/issues/159)) ([07cca6a](https://github.com/linrongbin16/fzfx.nvim/commit/07cca6a7a11f5cfb74ba274a629db52f16a32c68))
* move plugin to autoload ([6421290](https://github.com/linrongbin16/fzfx.nvim/commit/64212903050dc6486eb4f3a0ffa53e14164daf06))
* no newline ([3641ae4](https://github.com/linrongbin16/fzfx.nvim/commit/3641ae486dba283a73d3b942d149ae7079fa61fe))
* nonumber ([#116](https://github.com/linrongbin16/fzfx.nvim/issues/116)) ([2d32add](https://github.com/linrongbin16/fzfx.nvim/commit/2d32addbf31308d0c90669d9bd34c3d06830768b))
* NotifyLevels npe ([#195](https://github.com/linrongbin16/fzfx.nvim/issues/195)) ([23ca90d](https://github.com/linrongbin16/fzfx.nvim/commit/23ca90dda56764ca5227430f8734220794d6582f))
* only setpos for last line ([#27](https://github.com/linrongbin16/fzfx.nvim/issues/27)) ([7ae74d4](https://github.com/linrongbin16/fzfx.nvim/commit/7ae74d4f25e11b8d5e36b39417e9f2847c69828f))
* packer.nvim ([#111](https://github.com/linrongbin16/fzfx.nvim/issues/111)) ([a05793a](https://github.com/linrongbin16/fzfx.nvim/commit/a05793a2358471cebb247d402afbe5c825a60d4a))
* path containing space ([#250](https://github.com/linrongbin16/fzfx.nvim/issues/250)) ([8fd2bc6](https://github.com/linrongbin16/fzfx.nvim/commit/8fd2bc6c411b863a105c92eee727ffe8447741ba))
* press ESC on fzf exit ([#59](https://github.com/linrongbin16/fzfx.nvim/issues/59)) ([8c419e5](https://github.com/linrongbin16/fzfx.nvim/commit/8c419e56058078cc7b6d825299c6667e6e21dfc5))
* prompt extra space ([#9](https://github.com/linrongbin16/fzfx.nvim/issues/9)) ([a8195f7](https://github.com/linrongbin16/fzfx.nvim/commit/a8195f7028f63270b807e20e84d620c8346c6eae))
* **push:** revert direct push to main branch ([9eac0c0](https://github.com/linrongbin16/fzfx.nvim/commit/9eac0c072ca161a0d58cf50e7aed6090486c7e9a))
* relative cursor window ([#176](https://github.com/linrongbin16/fzfx.nvim/issues/176)) ([55b35ca](https://github.com/linrongbin16/fzfx.nvim/commit/55b35caff324892c6ad507895e389bb42d3adb0f))
* relative window position ([#174](https://github.com/linrongbin16/fzfx.nvim/issues/174)) ([8cfb9cf](https://github.com/linrongbin16/fzfx.nvim/commit/8cfb9cfa5e9fb9f6d4f79d4359768a24ba8965e5))
* restore previous window on exit ([#54](https://github.com/linrongbin16/fzfx.nvim/issues/54)) ([fcc3f78](https://github.com/linrongbin16/fzfx.nvim/commit/fcc3f78f32c92441a3699e0d7b1dcab0445ecbe0))
* rtrim ([#161](https://github.com/linrongbin16/fzfx.nvim/issues/161)) ([8a6d6b7](https://github.com/linrongbin16/fzfx.nvim/commit/8a6d6b7d72442d46a39fa2c1306d44480f60fa19))
* set `row=0,col=0` for bang ([#53](https://github.com/linrongbin16/fzfx.nvim/issues/53)) ([bddfca3](https://github.com/linrongbin16/fzfx.nvim/commit/bddfca3911866e25977ba98d1fc4d3ce53379fe5))
* set spell=false ([#114](https://github.com/linrongbin16/fzfx.nvim/issues/114)) ([2e3a32f](https://github.com/linrongbin16/fzfx.nvim/commit/2e3a32f14a538e53c3775a24548f3a118b7288c1))
* shell opts for Windows ([#82](https://github.com/linrongbin16/fzfx.nvim/issues/82)) ([2bd1e56](https://github.com/linrongbin16/fzfx.nvim/commit/2bd1e56916bd2d04af35227f7494ad0a0bf0c0e6))
* shellslash ([#21](https://github.com/linrongbin16/fzfx.nvim/issues/21)) ([e1493ae](https://github.com/linrongbin16/fzfx.nvim/commit/e1493ae6c5c1cb4dbc598522591de0afe5cb529b))
* shellslash only for Windows ([#86](https://github.com/linrongbin16/fzfx.nvim/issues/86)) ([df6bfe0](https://github.com/linrongbin16/fzfx.nvim/commit/df6bfe0733d93d09f6e4963fc97b93fd5b98b792))
* stop reading on spawn ([#227](https://github.com/linrongbin16/fzfx.nvim/issues/227)) ([daf2731](https://github.com/linrongbin16/fzfx.nvim/commit/daf2731ea832efd25771a05e9870440189dfca7e))
* stridx ([#132](https://github.com/linrongbin16/fzfx.nvim/issues/132)) ([1cfe8c9](https://github.com/linrongbin16/fzfx.nvim/commit/1cfe8c9a29fe938fadc599e4249322fa9d2e7efa))
* trim ([0b45d2e](https://github.com/linrongbin16/fzfx.nvim/commit/0b45d2ed5c4c9f809fc2abedc73be26c55e16d81))
* trim query & rewrite popup and launch ([#29](https://github.com/linrongbin16/fzfx.nvim/issues/29)) ([107b07f](https://github.com/linrongbin16/fzfx.nvim/commit/107b07f9021320be7f7b6bdca919910b99b66799))
* **utils:** transform windows newline '\r\n' & close all 3 handles ([#288](https://github.com/linrongbin16/fzfx.nvim/issues/288)) ([511a919](https://github.com/linrongbin16/fzfx.nvim/commit/511a919a68e0d6d4e3ece21caa6111458d230048))
* visual select ([11e9119](https://github.com/linrongbin16/fzfx.nvim/commit/11e91199ca82482dd418e47776dbe77098dfeb8c))
* visual select ([3a5dd76](https://github.com/linrongbin16/fzfx.nvim/commit/3a5dd769333d69c10eef090b8e83018d16b06865))
* windows git log pretty ([#77](https://github.com/linrongbin16/fzfx.nvim/issues/77)) ([d2ed804](https://github.com/linrongbin16/fzfx.nvim/commit/d2ed804bb58e6fd3ec4c9d6d2cce98fb4ac019f2))
* windows named pipe ([#50](https://github.com/linrongbin16/fzfx.nvim/issues/50)) ([099e59e](https://github.com/linrongbin16/fzfx.nvim/commit/099e59e17460580acb162d70780624ac8b786bcc))


### Performance Improvements

* async file io with fs_read ([#135](https://github.com/linrongbin16/fzfx.nvim/issues/135)) ([aabf6c8](https://github.com/linrongbin16/fzfx.nvim/commit/aabf6c88eccf1d0964eb29c5c1c6eb3ee4c3290c))
* async io ([#133](https://github.com/linrongbin16/fzfx.nvim/issues/133)) ([d66d7b3](https://github.com/linrongbin16/fzfx.nvim/commit/d66d7b3636951d328dc51eac1be24b1a3552487a))
* backup ([3e7a199](https://github.com/linrongbin16/fzfx.nvim/commit/3e7a199f0f37b3ebc5906d66420e373a2ce9c2f5))
* bind toggle ([#71](https://github.com/linrongbin16/fzfx.nvim/issues/71)) ([0da7adf](https://github.com/linrongbin16/fzfx.nvim/commit/0da7adf6c343cde4f19ed2a30de0d596f8841120))
* **cmd:** migrate from jobstart to uv.spawn ([#285](https://github.com/linrongbin16/fzfx.nvim/issues/285)) ([fd570b0](https://github.com/linrongbin16/fzfx.nvim/commit/fd570b097f60777bb00d767d1109639fefb37aaa))
* command_list previewer ([#182](https://github.com/linrongbin16/fzfx.nvim/issues/182)) ([78ae874](https://github.com/linrongbin16/fzfx.nvim/commit/78ae874c51a6405e894160cd500b4ac5d2511d14))
* comments ([#28](https://github.com/linrongbin16/fzfx.nvim/issues/28)) ([13f05c6](https://github.com/linrongbin16/fzfx.nvim/commit/13f05c6cac52c9f55a5085633aaef3af22dd2065))
* detect batcat, fdfind first ([#13](https://github.com/linrongbin16/fzfx.nvim/issues/13)) ([ec2a807](https://github.com/linrongbin16/fzfx.nvim/commit/ec2a807a352b4d52e5fcd2cdb7b1f892110435c5))
* don't normalize path for Windows ([#44](https://github.com/linrongbin16/fzfx.nvim/issues/44)) ([9261d4a](https://github.com/linrongbin16/fzfx.nvim/commit/9261d4ab3bf01c71994b9880a242811df1983e4d))
* dynamic passing ([#84](https://github.com/linrongbin16/fzfx.nvim/issues/84)) ([711e7c9](https://github.com/linrongbin16/fzfx.nvim/commit/711e7c9f3dc1a48f66e0d02a8db90dc27b6955ce))
* file explorer & test ([#215](https://github.com/linrongbin16/fzfx.nvim/issues/215)) ([0468619](https://github.com/linrongbin16/fzfx.nvim/commit/046861978a47cd966f6bc918667fb811d1c90990))
* fzf default command ([#11](https://github.com/linrongbin16/fzfx.nvim/issues/11)) ([502df8e](https://github.com/linrongbin16/fzfx.nvim/commit/502df8eb125af580541da8fed701a6e8e95a5fa2))
* ggrep,gfind ([#94](https://github.com/linrongbin16/fzfx.nvim/issues/94)) ([dd510f8](https://github.com/linrongbin16/fzfx.nvim/commit/dd510f89d630ee1ba872a6711b8484ba13d41e27))
* git branches ([#75](https://github.com/linrongbin16/fzfx.nvim/issues/75)) ([667a94b](https://github.com/linrongbin16/fzfx.nvim/commit/667a94b38426632bb8ec8ca8cb1f587a8e4222c5))
* log ([#109](https://github.com/linrongbin16/fzfx.nvim/issues/109)) ([b6a7857](https://github.com/linrongbin16/fzfx.nvim/commit/b6a7857d88aa50b61a1324f9326006b608e8c9b5))
* lsp definitions ([#154](https://github.com/linrongbin16/fzfx.nvim/issues/154)) ([3418aef](https://github.com/linrongbin16/fzfx.nvim/commit/3418aefad1bff78494e67ac54f3644cf1269b1d8))
* migrate buffers ([#113](https://github.com/linrongbin16/fzfx.nvim/issues/113)) ([4da588b](https://github.com/linrongbin16/fzfx.nvim/commit/4da588bb0a759232698117c1be69ebf2f7f84232))
* move nvim,fzf executable check before open win ([#25](https://github.com/linrongbin16/fzfx.nvim/issues/25)) ([da6c446](https://github.com/linrongbin16/fzfx.nvim/commit/da6c446bf3eebfbb5d619833ed3c419a60daa5dd))
* path separator ([#51](https://github.com/linrongbin16/fzfx.nvim/issues/51)) ([3f783fd](https://github.com/linrongbin16/fzfx.nvim/commit/3f783fdccf8b974bed07e2e20520a53c27c98703))
* preview up/down keys ([#73](https://github.com/linrongbin16/fzfx.nvim/issues/73)) ([b9d115a](https://github.com/linrongbin16/fzfx.nvim/commit/b9d115aafb652b39c409e237a85b2c6469827c07))
* provider command ([c92b150](https://github.com/linrongbin16/fzfx.nvim/commit/c92b1509be7fcebdfdc19c1732b8fa20ef4505b0))
* provider switch ([#96](https://github.com/linrongbin16/fzfx.nvim/issues/96)) ([c36e378](https://github.com/linrongbin16/fzfx.nvim/commit/c36e378f8f95a099f16dcdca52cb5f1acf0812dd))
* reduce CommandConfig ([#251](https://github.com/linrongbin16/fzfx.nvim/issues/251)) ([ac78df6](https://github.com/linrongbin16/fzfx.nvim/commit/ac78df62c0e8d5fa1d2c2a11492827b2ca3f1b7d))
* reduce ESC keys & better multi keys ([#61](https://github.com/linrongbin16/fzfx.nvim/issues/61)) ([e159895](https://github.com/linrongbin16/fzfx.nvim/commit/e159895e4eab5c39d7f6e391f3b048fce85a8136))
* remove fzf/rg mode ([5bff616](https://github.com/linrongbin16/fzfx.nvim/commit/5bff6163c778ae308503bf5bdc64cd0c58d86068))
* remove internal env var ([e3b2e49](https://github.com/linrongbin16/fzfx.nvim/commit/e3b2e49cf9f7c8765cf55a01df2633188079881b))
* remove unused import ([33703c9](https://github.com/linrongbin16/fzfx.nvim/commit/33703c965c2a544ce8adb138650b0e1cafcd31de))
* **schema:** deprecate 'ProviderConfig' & 'PreviewerConfig' ([#268](https://github.com/linrongbin16/fzfx.nvim/issues/268)) ([3c2e32c](https://github.com/linrongbin16/fzfx.nvim/commit/3c2e32c0a97614a34d80b0d0392a0d377b3ead84))
* **schema:** deprecate note on 'PreviewerConfig' ([#270](https://github.com/linrongbin16/fzfx.nvim/issues/270)) ([6552efe](https://github.com/linrongbin16/fzfx.nvim/commit/6552efe8253a2b5ae467efc61df811f60a88141c))
* setup legacy ([ebbed25](https://github.com/linrongbin16/fzfx.nvim/commit/ebbed25cddcae73383c0239407bf9c90371916c7))
* shellslash ([#91](https://github.com/linrongbin16/fzfx.nvim/issues/91)) ([2663cd4](https://github.com/linrongbin16/fzfx.nvim/commit/2663cd4d4ec4778dc55b2271838b2ec7454a1c3a))
* socket server ([#39](https://github.com/linrongbin16/fzfx.nvim/issues/39)) ([5613c56](https://github.com/linrongbin16/fzfx.nvim/commit/5613c5662870f27fe7ef45b9a955f0402dd3dff8))
* use 'buffer' instead 'edit' for buffers ([#67](https://github.com/linrongbin16/fzfx.nvim/issues/67)) ([4e74d79](https://github.com/linrongbin16/fzfx.nvim/commit/4e74d79108155a864723e131d2f9d9ff2f5cb9b0))
* use uv spawn ([#181](https://github.com/linrongbin16/fzfx.nvim/issues/181)) ([7fe84c6](https://github.com/linrongbin16/fzfx.nvim/commit/7fe84c606ed5847108035f3dded7745ad61f1450))
* uv.spawn ([#128](https://github.com/linrongbin16/fzfx.nvim/issues/128)) ([5d54505](https://github.com/linrongbin16/fzfx.nvim/commit/5d54505d9f06fe1fada283024ce38d7213f3761e))
* win_opts row/col ([#23](https://github.com/linrongbin16/fzfx.nvim/issues/23)) ([f035673](https://github.com/linrongbin16/fzfx.nvim/commit/f0356732db5801b424234223d4f306a25db0d35c))


### Reverts

* lower minimal required version v0.6 ([#245](https://github.com/linrongbin16/fzfx.nvim/issues/245)) ([89eb334](https://github.com/linrongbin16/fzfx.nvim/commit/89eb334df7920a75386b659cd007a3ec5ea6fe13))

## [1.3.0](https://github.com/linrongbin16/fzfx.nvim/compare/v1.2.0...v1.3.0) (2023-10-23)


### Features

* **logs:** split shell command provider/previewer logs ([#303](https://github.com/linrongbin16/fzfx.nvim/issues/303)) ([5ed1bcd](https://github.com/linrongbin16/fzfx.nvim/commit/5ed1bcd6728000c7ec692e99603ae69ab82a2edd))

## [1.2.0](https://github.com/linrongbin16/fzfx.nvim/compare/v1.1.1...v1.2.0) (2023-10-20)


### Features

* **actions:** add 'setqflist' ([#290](https://github.com/linrongbin16/fzfx.nvim/issues/290)) ([1284639](https://github.com/linrongbin16/fzfx.nvim/commit/1284639770c907fe7d850c5b05ddeb74a8db552e))
* **commands:** add 'FzfxCommands' to search vim commands ([#287](https://github.com/linrongbin16/fzfx.nvim/issues/287)) ([997821b](https://github.com/linrongbin16/fzfx.nvim/commit/997821ba69b6587ba392e3f5c46cc7dd196f62da))


### Bug Fixes

* **utils:** transform windows newline '\r\n' & close all 3 handles ([#288](https://github.com/linrongbin16/fzfx.nvim/issues/288)) ([511a919](https://github.com/linrongbin16/fzfx.nvim/commit/511a919a68e0d6d4e3ece21caa6111458d230048))


### Performance Improvements

* **cmd:** migrate from jobstart to uv.spawn ([#285](https://github.com/linrongbin16/fzfx.nvim/issues/285)) ([fd570b0](https://github.com/linrongbin16/fzfx.nvim/commit/fd570b097f60777bb00d767d1109639fefb37aaa))

## [1.1.1](https://github.com/linrongbin16/fzfx.nvim/compare/v1.1.0...v1.1.1) (2023-10-11)


### Bug Fixes

* **actions:** 'bdelete' filename containing whitespaces ([#277](https://github.com/linrongbin16/fzfx.nvim/issues/277)) ([d3faf5a](https://github.com/linrongbin16/fzfx.nvim/commit/d3faf5a24177e57f19fbd056bcb940d614405a2d))
* **interactions:** cd into directory containing spaces ([#279](https://github.com/linrongbin16/fzfx.nvim/issues/279)) ([e9bde4a](https://github.com/linrongbin16/fzfx.nvim/commit/e9bde4a870eb4709e4867b5150649553bbaf8f0a))

## [1.1.0](https://github.com/linrongbin16/fzfx.nvim/compare/v1.0.2...v1.1.0) (2023-10-11)


### Features

* **schema:** add 'PreviewerConfig' detection ([#266](https://github.com/linrongbin16/fzfx.nvim/issues/266)) ([2bdcef7](https://github.com/linrongbin16/fzfx.nvim/commit/2bdcef7f82a55327851b6d3ecb5e48c53f08a691))


### Bug Fixes

* **actions:** edit rg/grep results that contains whitespaces on filename ([#272](https://github.com/linrongbin16/fzfx.nvim/issues/272)) ([a202d1f](https://github.com/linrongbin16/fzfx.nvim/commit/a202d1f2b850271d5ff680a3ce85fbff42efba85))
* **push:** revert direct push to main branch ([9eac0c0](https://github.com/linrongbin16/fzfx.nvim/commit/9eac0c072ca161a0d58cf50e7aed6090486c7e9a))


### Performance Improvements

* **schema:** deprecate 'ProviderConfig' & 'PreviewerConfig' ([#268](https://github.com/linrongbin16/fzfx.nvim/issues/268)) ([3c2e32c](https://github.com/linrongbin16/fzfx.nvim/commit/3c2e32c0a97614a34d80b0d0392a0d377b3ead84))
* **schema:** deprecate note on 'PreviewerConfig' ([#270](https://github.com/linrongbin16/fzfx.nvim/issues/270)) ([6552efe](https://github.com/linrongbin16/fzfx.nvim/commit/6552efe8253a2b5ae467efc61df811f60a88141c))

## [1.0.2](https://github.com/linrongbin16/fzfx.nvim/compare/v1.0.1...v1.0.2) (2023-10-09)


### Bug Fixes

* **config:** use cache.dir instead of hard coding ([#260](https://github.com/linrongbin16/fzfx.nvim/issues/260)) ([6bf24d1](https://github.com/linrongbin16/fzfx.nvim/commit/6bf24d1b81b29c5f37cfebfcf38c83213146d8af))

## [1.0.1](https://github.com/linrongbin16/fzfx.nvim/compare/v1.0.0...v1.0.1) (2023-10-09)


### Bug Fixes

* edit files actions on path containing whitespaces for fd/find/eza/ls results ([#258](https://github.com/linrongbin16/fzfx.nvim/issues/258)) ([2a2c1a9](https://github.com/linrongbin16/fzfx.nvim/commit/2a2c1a93f840d58310fcbfbafd6da0643f300778))

## 1.0.0 (2023-10-09)


### Features

* add parse_file/parse_grep line helpers ([#222](https://github.com/linrongbin16/fzfx.nvim/issues/222)) ([5a503da](https://github.com/linrongbin16/fzfx.nvim/commit/5a503da25aec9a07ebde12dedae03e71056445c1))
* add variants for file explorer ([#213](https://github.com/linrongbin16/fzfx.nvim/issues/213)) ([289b8b8](https://github.com/linrongbin16/fzfx.nvim/commit/289b8b80c1348e604f141551a1c4877aecc5315f))
* bg color ^& fix exec ([#22](https://github.com/linrongbin16/fzfx.nvim/issues/22)) ([1a86b34](https://github.com/linrongbin16/fzfx.nvim/commit/1a86b34afeaeca879f05d4f7ea5ef4698f0044b6))
* buffers ([#57](https://github.com/linrongbin16/fzfx.nvim/issues/57)) ([bd1e0dc](https://github.com/linrongbin16/fzfx.nvim/commit/bd1e0dc2432f10a7947c1718ea3cb9ce9d600f64))
* color ([5537884](https://github.com/linrongbin16/fzfx.nvim/commit/5537884769b20f1ddab63c7885323e82ea31ef0b))
* colors ([#62](https://github.com/linrongbin16/fzfx.nvim/issues/62)) ([72b2437](https://github.com/linrongbin16/fzfx.nvim/commit/72b243747f6c0418f5c6e45eba79450b1f224815))
* debug command ([b0ac732](https://github.com/linrongbin16/fzfx.nvim/commit/b0ac73244ac4ecf78671e29bffd07c538a86b3b6))
* diagnostics ([#124](https://github.com/linrongbin16/fzfx.nvim/issues/124)) ([a610762](https://github.com/linrongbin16/fzfx.nvim/commit/a610762e579eb31fdabb6f837f788cb7e3e9fc3e))
* file explorer (ls) ([#210](https://github.com/linrongbin16/fzfx.nvim/issues/210)) ([212c789](https://github.com/linrongbin16/fzfx.nvim/commit/212c789dc424e97894eef6209bb18f829b0191d4))
* files ([bf42213](https://github.com/linrongbin16/fzfx.nvim/commit/bf42213be415d19123a5a6f6ef4412756755c3b3))
* files ([362065c](https://github.com/linrongbin16/fzfx.nvim/commit/362065c6a650c88fb737bdd06807fb9b61d83244))
* git blame & general ([#102](https://github.com/linrongbin16/fzfx.nvim/issues/102)) ([21f5a62](https://github.com/linrongbin16/fzfx.nvim/commit/21f5a622494143ad270c430d72ad5e4c37996df5))
* git branches ([#68](https://github.com/linrongbin16/fzfx.nvim/issues/68)) ([7f055d5](https://github.com/linrongbin16/fzfx.nvim/commit/7f055d5549a01ffac8f2389ccf7a9315d2f44442))
* git commits ([#97](https://github.com/linrongbin16/fzfx.nvim/issues/97)) ([ded9623](https://github.com/linrongbin16/fzfx.nvim/commit/ded9623463864f8d0d07d08ac83e858a32d7ba10))
* git files ([#64](https://github.com/linrongbin16/fzfx.nvim/issues/64)) ([d83a857](https://github.com/linrongbin16/fzfx.nvim/commit/d83a857d619292a36ee736b88971a86acc2b0680))
* handle whitespaces on path ([#20](https://github.com/linrongbin16/fzfx.nvim/issues/20)) ([f05107b](https://github.com/linrongbin16/fzfx.nvim/commit/f05107b10523edfccb49403007d2b7efab8f487c))
* icon!!! ([#31](https://github.com/linrongbin16/fzfx.nvim/issues/31)) ([668a820](https://github.com/linrongbin16/fzfx.nvim/commit/668a82042e972427be541dfde5adad3d5173ed12))
* improve cwd ([#214](https://github.com/linrongbin16/fzfx.nvim/issues/214)) ([cd6042f](https://github.com/linrongbin16/fzfx.nvim/commit/cd6042fda05841a7d00321cae7323754d7bccba1))
* list_index ([#221](https://github.com/linrongbin16/fzfx.nvim/issues/221)) ([cb61fd5](https://github.com/linrongbin16/fzfx.nvim/commit/cb61fd5524a73f3cf8f871d60222c0119ae91498))
* live grep ([67c2776](https://github.com/linrongbin16/fzfx.nvim/commit/67c2776b6b3be654856db8b5537279368c9baf90))
* live grep ([#7](https://github.com/linrongbin16/fzfx.nvim/issues/7)) ([fda0337](https://github.com/linrongbin16/fzfx.nvim/commit/fda0337ec5189021ed6a5e023b75099bc4be1f91))
* log ([ffe368b](https://github.com/linrongbin16/fzfx.nvim/commit/ffe368ba848c8ae95cc8b1af967bc2443c309222))
* lsp color ([#166](https://github.com/linrongbin16/fzfx.nvim/issues/166)) ([690bf7a](https://github.com/linrongbin16/fzfx.nvim/commit/690bf7a42099c53a34534a79d10aba1083d59892))
* lsp commands ([#170](https://github.com/linrongbin16/fzfx.nvim/issues/170)) ([7589a88](https://github.com/linrongbin16/fzfx.nvim/commit/7589a8885b088a17fdeef040d0c768c10298a300))
* lsp definitions ([#150](https://github.com/linrongbin16/fzfx.nvim/issues/150)) ([10f5bfc](https://github.com/linrongbin16/fzfx.nvim/commit/10f5bfc3179729a579086fe67c3aa8ff29d66b82))
* lsp diagnostics file path color ([#125](https://github.com/linrongbin16/fzfx.nvim/issues/125)) ([f24e578](https://github.com/linrongbin16/fzfx.nvim/commit/f24e578d21809b7bed4fc0f92cb4fb922fbc1777))
* passing rg raw optoins ([c36bf8a](https://github.com/linrongbin16/fzfx.nvim/commit/c36bf8aff1bc0e425c6bd0853e3809e245a9ecca))
* please-release ([#254](https://github.com/linrongbin16/fzfx.nvim/issues/254)) ([a1d2da4](https://github.com/linrongbin16/fzfx.nvim/commit/a1d2da467596f679da0565ac7223324f23e10362))
* plugin home dir ([a55718f](https://github.com/linrongbin16/fzfx.nvim/commit/a55718f81a346de3c095174630e828cbb8a84b76))
* PR template ([#247](https://github.com/linrongbin16/fzfx.nvim/issues/247)) ([0843fb5](https://github.com/linrongbin16/fzfx.nvim/commit/0843fb56554237eeb54e1486a6e249be8796e153))
* relative window ([#172](https://github.com/linrongbin16/fzfx.nvim/issues/172)) ([01caa8b](https://github.com/linrongbin16/fzfx.nvim/commit/01caa8bc6c0b5689b79773112ad79b99adc0527a))
* restore query ([9c1ec44](https://github.com/linrongbin16/fzfx.nvim/commit/9c1ec443e7f2b9f3530eee4529f7c52a9391cefc))
* rgb color codes ([#165](https://github.com/linrongbin16/fzfx.nvim/issues/165)) ([835ca8a](https://github.com/linrongbin16/fzfx.nvim/commit/835ca8acbb7227997621e8f44e5c56702d7633a7))
* row/col win_opts ([#12](https://github.com/linrongbin16/fzfx.nvim/issues/12)) ([bd24d0a](https://github.com/linrongbin16/fzfx.nvim/commit/bd24d0a107330648ced401acdf30c02bc438d64f))
* switch unrestricted mode ([5500bb1](https://github.com/linrongbin16/fzfx.nvim/commit/5500bb176a789f88a01c3cca066c0eaa3abe4a69))
* throw error ([c4eef09](https://github.com/linrongbin16/fzfx.nvim/commit/c4eef090f92bf3f5c548f92c63e386416567cf65))
* utils ([4ab3a4f](https://github.com/linrongbin16/fzfx.nvim/commit/4ab3a4f2ad9e950f962cab727ad91cc207b3ff33))
* visual/cword ([f9fbb86](https://github.com/linrongbin16/fzfx.nvim/commit/f9fbb86798ef331a6bf42213e720cbf4f9706fce))
* windows named pipe ([62a425f](https://github.com/linrongbin16/fzfx.nvim/commit/62a425fb815bfd36bb720c08b55b50d450c306ce))
* yank/put ([#45](https://github.com/linrongbin16/fzfx.nvim/issues/45)) ([b3db7b1](https://github.com/linrongbin16/fzfx.nvim/commit/b3db7b18e0efd32a542f9af7bdd007af65801d4e))


### Bug Fixes

* `new_pipe` not working on Windows arm64 ([#160](https://github.com/linrongbin16/fzfx.nvim/issues/160)) ([6efd376](https://github.com/linrongbin16/fzfx.nvim/commit/6efd376b7d2f79d667fae69bd11d0054f9cdbd2b))
* base dir ([3dbf684](https://github.com/linrongbin16/fzfx.nvim/commit/3dbf6840ed66a2489848603781150858bcd7a95a))
* base dir ([cb72633](https://github.com/linrongbin16/fzfx.nvim/commit/cb72633721ae4e1e8addb05834dde24f1a9fa2e1))
* buffer path ([#158](https://github.com/linrongbin16/fzfx.nvim/issues/158)) ([b0dc926](https://github.com/linrongbin16/fzfx.nvim/commit/b0dc926826ae17d172d424f27bf31236686da9e1))
* buffers wrong locked ([#100](https://github.com/linrongbin16/fzfx.nvim/issues/100)) ([760b1eb](https://github.com/linrongbin16/fzfx.nvim/commit/760b1eb0ba5736dcdb2727c74d621bdf19f4c647))
* **buffers:** current buffer, doc ([#98](https://github.com/linrongbin16/fzfx.nvim/issues/98)) ([990d5bf](https://github.com/linrongbin16/fzfx.nvim/commit/990d5bfdf2c4a6979a23655110287fe787924f5d))
* check method support ([#168](https://github.com/linrongbin16/fzfx.nvim/issues/168)) ([5aec401](https://github.com/linrongbin16/fzfx.nvim/commit/5aec401fab4f91d2f6a7234389207e0d6d7f29a9))
* close spawn handler ([#209](https://github.com/linrongbin16/fzfx.nvim/issues/209)) ([0338d6d](https://github.com/linrongbin16/fzfx.nvim/commit/0338d6d45858a07fd9073c8e8e74e826c2b71090))
* compat `vim.split` on v0.5.0, refactor actions ([#184](https://github.com/linrongbin16/fzfx.nvim/issues/184)) ([fafddf5](https://github.com/linrongbin16/fzfx.nvim/commit/fafddf51e47dd3b3a07184d5841506c51ba96a91))
* depress log ([#78](https://github.com/linrongbin16/fzfx.nvim/issues/78)) ([4e0958d](https://github.com/linrongbin16/fzfx.nvim/commit/4e0958d9d5964ac61463f7770238dda6b221909f))
* directory icon ([#41](https://github.com/linrongbin16/fzfx.nvim/issues/41)) ([3326dd2](https://github.com/linrongbin16/fzfx.nvim/commit/3326dd2ddb6c348ecd7100bcead33e90a126b80b))
* edit grep ([#92](https://github.com/linrongbin16/fzfx.nvim/issues/92)) ([5f2f017](https://github.com/linrongbin16/fzfx.nvim/commit/5f2f017053b88d65e7566e49c587bbc37b3d8af8))
* expand filename to full path ([#244](https://github.com/linrongbin16/fzfx.nvim/issues/244)) ([296aaf9](https://github.com/linrongbin16/fzfx.nvim/commit/296aaf92c24da4c16fd4b317c1794bbe3f2784a1))
* filepath with whitespaces ([#219](https://github.com/linrongbin16/fzfx.nvim/issues/219)) ([4491695](https://github.com/linrongbin16/fzfx.nvim/commit/449169597bbdb70d233a4ccadb2502116bcad0dd))
* func ref ([433e5d3](https://github.com/linrongbin16/fzfx.nvim/commit/433e5d3174ad07885eeb669daf76f81c069deebb))
* fuzzy mode ([598b701](https://github.com/linrongbin16/fzfx.nvim/commit/598b701b82807d273a00b30ea292b002e3950808))
* fuzzy switch ([fcbdbbe](https://github.com/linrongbin16/fzfx.nvim/commit/fcbdbbe34e3b16b9c986ad35b99bd33cfb4c96c9))
* fzf mode query ([4a5d69f](https://github.com/linrongbin16/fzfx.nvim/commit/4a5d69fe776625e49cd23af09ed169844ab3065b))
* fzfx_base ([39aa3a8](https://github.com/linrongbin16/fzfx.nvim/commit/39aa3a870cdd4655425bb54810a2532634439f91))
* git checkout on remote branches ([#153](https://github.com/linrongbin16/fzfx.nvim/issues/153)) ([e04a06d](https://github.com/linrongbin16/fzfx.nvim/commit/e04a06db730acb802ac3a1d987fd10b52107c2d6))
* grep exclude hiddens ([#93](https://github.com/linrongbin16/fzfx.nvim/issues/93)) ([a3ae56b](https://github.com/linrongbin16/fzfx.nvim/commit/a3ae56b73cccdd1c10e7ee72efe2374268e95807))
* header ([f2f6f1c](https://github.com/linrongbin16/fzfx.nvim/commit/f2f6f1c7fa43db5e0b847c69506a4343ecf96875))
* live grep override ([#231](https://github.com/linrongbin16/fzfx.nvim/issues/231)) ([baa15e1](https://github.com/linrongbin16/fzfx.nvim/commit/baa15e1d9bc49133c0fb91a5b59262e3c020ff58))
* lock header for ls ([#211](https://github.com/linrongbin16/fzfx.nvim/issues/211)) ([3388d95](https://github.com/linrongbin16/fzfx.nvim/commit/3388d95f6b5324f01db9c65b814b62eb826cd106))
* log echo ([#55](https://github.com/linrongbin16/fzfx.nvim/issues/55)) ([1ed20c9](https://github.com/linrongbin16/fzfx.nvim/commit/1ed20c9204c91358b92a7257ff128343dc303d9b))
* lsp definitions color ([#159](https://github.com/linrongbin16/fzfx.nvim/issues/159)) ([07cca6a](https://github.com/linrongbin16/fzfx.nvim/commit/07cca6a7a11f5cfb74ba274a629db52f16a32c68))
* move plugin to autoload ([6421290](https://github.com/linrongbin16/fzfx.nvim/commit/64212903050dc6486eb4f3a0ffa53e14164daf06))
* no newline ([3641ae4](https://github.com/linrongbin16/fzfx.nvim/commit/3641ae486dba283a73d3b942d149ae7079fa61fe))
* nonumber ([#116](https://github.com/linrongbin16/fzfx.nvim/issues/116)) ([2d32add](https://github.com/linrongbin16/fzfx.nvim/commit/2d32addbf31308d0c90669d9bd34c3d06830768b))
* NotifyLevels npe ([#195](https://github.com/linrongbin16/fzfx.nvim/issues/195)) ([23ca90d](https://github.com/linrongbin16/fzfx.nvim/commit/23ca90dda56764ca5227430f8734220794d6582f))
* only setpos for last line ([#27](https://github.com/linrongbin16/fzfx.nvim/issues/27)) ([7ae74d4](https://github.com/linrongbin16/fzfx.nvim/commit/7ae74d4f25e11b8d5e36b39417e9f2847c69828f))
* packer.nvim ([#111](https://github.com/linrongbin16/fzfx.nvim/issues/111)) ([a05793a](https://github.com/linrongbin16/fzfx.nvim/commit/a05793a2358471cebb247d402afbe5c825a60d4a))
* path containing space ([#250](https://github.com/linrongbin16/fzfx.nvim/issues/250)) ([8fd2bc6](https://github.com/linrongbin16/fzfx.nvim/commit/8fd2bc6c411b863a105c92eee727ffe8447741ba))
* press ESC on fzf exit ([#59](https://github.com/linrongbin16/fzfx.nvim/issues/59)) ([8c419e5](https://github.com/linrongbin16/fzfx.nvim/commit/8c419e56058078cc7b6d825299c6667e6e21dfc5))
* prompt extra space ([#9](https://github.com/linrongbin16/fzfx.nvim/issues/9)) ([a8195f7](https://github.com/linrongbin16/fzfx.nvim/commit/a8195f7028f63270b807e20e84d620c8346c6eae))
* relative cursor window ([#176](https://github.com/linrongbin16/fzfx.nvim/issues/176)) ([55b35ca](https://github.com/linrongbin16/fzfx.nvim/commit/55b35caff324892c6ad507895e389bb42d3adb0f))
* relative window position ([#174](https://github.com/linrongbin16/fzfx.nvim/issues/174)) ([8cfb9cf](https://github.com/linrongbin16/fzfx.nvim/commit/8cfb9cfa5e9fb9f6d4f79d4359768a24ba8965e5))
* restore previous window on exit ([#54](https://github.com/linrongbin16/fzfx.nvim/issues/54)) ([fcc3f78](https://github.com/linrongbin16/fzfx.nvim/commit/fcc3f78f32c92441a3699e0d7b1dcab0445ecbe0))
* rtrim ([#161](https://github.com/linrongbin16/fzfx.nvim/issues/161)) ([8a6d6b7](https://github.com/linrongbin16/fzfx.nvim/commit/8a6d6b7d72442d46a39fa2c1306d44480f60fa19))
* set `row=0,col=0` for bang ([#53](https://github.com/linrongbin16/fzfx.nvim/issues/53)) ([bddfca3](https://github.com/linrongbin16/fzfx.nvim/commit/bddfca3911866e25977ba98d1fc4d3ce53379fe5))
* set spell=false ([#114](https://github.com/linrongbin16/fzfx.nvim/issues/114)) ([2e3a32f](https://github.com/linrongbin16/fzfx.nvim/commit/2e3a32f14a538e53c3775a24548f3a118b7288c1))
* shell opts for Windows ([#82](https://github.com/linrongbin16/fzfx.nvim/issues/82)) ([2bd1e56](https://github.com/linrongbin16/fzfx.nvim/commit/2bd1e56916bd2d04af35227f7494ad0a0bf0c0e6))
* shellslash ([#21](https://github.com/linrongbin16/fzfx.nvim/issues/21)) ([e1493ae](https://github.com/linrongbin16/fzfx.nvim/commit/e1493ae6c5c1cb4dbc598522591de0afe5cb529b))
* shellslash only for Windows ([#86](https://github.com/linrongbin16/fzfx.nvim/issues/86)) ([df6bfe0](https://github.com/linrongbin16/fzfx.nvim/commit/df6bfe0733d93d09f6e4963fc97b93fd5b98b792))
* stop reading on spawn ([#227](https://github.com/linrongbin16/fzfx.nvim/issues/227)) ([daf2731](https://github.com/linrongbin16/fzfx.nvim/commit/daf2731ea832efd25771a05e9870440189dfca7e))
* stridx ([#132](https://github.com/linrongbin16/fzfx.nvim/issues/132)) ([1cfe8c9](https://github.com/linrongbin16/fzfx.nvim/commit/1cfe8c9a29fe938fadc599e4249322fa9d2e7efa))
* trim ([0b45d2e](https://github.com/linrongbin16/fzfx.nvim/commit/0b45d2ed5c4c9f809fc2abedc73be26c55e16d81))
* trim query & rewrite popup and launch ([#29](https://github.com/linrongbin16/fzfx.nvim/issues/29)) ([107b07f](https://github.com/linrongbin16/fzfx.nvim/commit/107b07f9021320be7f7b6bdca919910b99b66799))
* visual select ([11e9119](https://github.com/linrongbin16/fzfx.nvim/commit/11e91199ca82482dd418e47776dbe77098dfeb8c))
* visual select ([3a5dd76](https://github.com/linrongbin16/fzfx.nvim/commit/3a5dd769333d69c10eef090b8e83018d16b06865))
* windows git log pretty ([#77](https://github.com/linrongbin16/fzfx.nvim/issues/77)) ([d2ed804](https://github.com/linrongbin16/fzfx.nvim/commit/d2ed804bb58e6fd3ec4c9d6d2cce98fb4ac019f2))
* windows named pipe ([#50](https://github.com/linrongbin16/fzfx.nvim/issues/50)) ([099e59e](https://github.com/linrongbin16/fzfx.nvim/commit/099e59e17460580acb162d70780624ac8b786bcc))


### Performance Improvements

* async file io with fs_read ([#135](https://github.com/linrongbin16/fzfx.nvim/issues/135)) ([aabf6c8](https://github.com/linrongbin16/fzfx.nvim/commit/aabf6c88eccf1d0964eb29c5c1c6eb3ee4c3290c))
* async io ([#133](https://github.com/linrongbin16/fzfx.nvim/issues/133)) ([d66d7b3](https://github.com/linrongbin16/fzfx.nvim/commit/d66d7b3636951d328dc51eac1be24b1a3552487a))
* backup ([3e7a199](https://github.com/linrongbin16/fzfx.nvim/commit/3e7a199f0f37b3ebc5906d66420e373a2ce9c2f5))
* bind toggle ([#71](https://github.com/linrongbin16/fzfx.nvim/issues/71)) ([0da7adf](https://github.com/linrongbin16/fzfx.nvim/commit/0da7adf6c343cde4f19ed2a30de0d596f8841120))
* command_list previewer ([#182](https://github.com/linrongbin16/fzfx.nvim/issues/182)) ([78ae874](https://github.com/linrongbin16/fzfx.nvim/commit/78ae874c51a6405e894160cd500b4ac5d2511d14))
* comments ([#28](https://github.com/linrongbin16/fzfx.nvim/issues/28)) ([13f05c6](https://github.com/linrongbin16/fzfx.nvim/commit/13f05c6cac52c9f55a5085633aaef3af22dd2065))
* detect batcat, fdfind first ([#13](https://github.com/linrongbin16/fzfx.nvim/issues/13)) ([ec2a807](https://github.com/linrongbin16/fzfx.nvim/commit/ec2a807a352b4d52e5fcd2cdb7b1f892110435c5))
* don't normalize path for Windows ([#44](https://github.com/linrongbin16/fzfx.nvim/issues/44)) ([9261d4a](https://github.com/linrongbin16/fzfx.nvim/commit/9261d4ab3bf01c71994b9880a242811df1983e4d))
* dynamic passing ([#84](https://github.com/linrongbin16/fzfx.nvim/issues/84)) ([711e7c9](https://github.com/linrongbin16/fzfx.nvim/commit/711e7c9f3dc1a48f66e0d02a8db90dc27b6955ce))
* file explorer & test ([#215](https://github.com/linrongbin16/fzfx.nvim/issues/215)) ([0468619](https://github.com/linrongbin16/fzfx.nvim/commit/046861978a47cd966f6bc918667fb811d1c90990))
* fzf default command ([#11](https://github.com/linrongbin16/fzfx.nvim/issues/11)) ([502df8e](https://github.com/linrongbin16/fzfx.nvim/commit/502df8eb125af580541da8fed701a6e8e95a5fa2))
* ggrep,gfind ([#94](https://github.com/linrongbin16/fzfx.nvim/issues/94)) ([dd510f8](https://github.com/linrongbin16/fzfx.nvim/commit/dd510f89d630ee1ba872a6711b8484ba13d41e27))
* git branches ([#75](https://github.com/linrongbin16/fzfx.nvim/issues/75)) ([667a94b](https://github.com/linrongbin16/fzfx.nvim/commit/667a94b38426632bb8ec8ca8cb1f587a8e4222c5))
* log ([#109](https://github.com/linrongbin16/fzfx.nvim/issues/109)) ([b6a7857](https://github.com/linrongbin16/fzfx.nvim/commit/b6a7857d88aa50b61a1324f9326006b608e8c9b5))
* lsp definitions ([#154](https://github.com/linrongbin16/fzfx.nvim/issues/154)) ([3418aef](https://github.com/linrongbin16/fzfx.nvim/commit/3418aefad1bff78494e67ac54f3644cf1269b1d8))
* migrate buffers ([#113](https://github.com/linrongbin16/fzfx.nvim/issues/113)) ([4da588b](https://github.com/linrongbin16/fzfx.nvim/commit/4da588bb0a759232698117c1be69ebf2f7f84232))
* move nvim,fzf executable check before open win ([#25](https://github.com/linrongbin16/fzfx.nvim/issues/25)) ([da6c446](https://github.com/linrongbin16/fzfx.nvim/commit/da6c446bf3eebfbb5d619833ed3c419a60daa5dd))
* path separator ([#51](https://github.com/linrongbin16/fzfx.nvim/issues/51)) ([3f783fd](https://github.com/linrongbin16/fzfx.nvim/commit/3f783fdccf8b974bed07e2e20520a53c27c98703))
* preview up/down keys ([#73](https://github.com/linrongbin16/fzfx.nvim/issues/73)) ([b9d115a](https://github.com/linrongbin16/fzfx.nvim/commit/b9d115aafb652b39c409e237a85b2c6469827c07))
* provider command ([c92b150](https://github.com/linrongbin16/fzfx.nvim/commit/c92b1509be7fcebdfdc19c1732b8fa20ef4505b0))
* provider switch ([#96](https://github.com/linrongbin16/fzfx.nvim/issues/96)) ([c36e378](https://github.com/linrongbin16/fzfx.nvim/commit/c36e378f8f95a099f16dcdca52cb5f1acf0812dd))
* reduce CommandConfig ([#251](https://github.com/linrongbin16/fzfx.nvim/issues/251)) ([ac78df6](https://github.com/linrongbin16/fzfx.nvim/commit/ac78df62c0e8d5fa1d2c2a11492827b2ca3f1b7d))
* reduce ESC keys & better multi keys ([#61](https://github.com/linrongbin16/fzfx.nvim/issues/61)) ([e159895](https://github.com/linrongbin16/fzfx.nvim/commit/e159895e4eab5c39d7f6e391f3b048fce85a8136))
* remove fzf/rg mode ([5bff616](https://github.com/linrongbin16/fzfx.nvim/commit/5bff6163c778ae308503bf5bdc64cd0c58d86068))
* remove internal env var ([e3b2e49](https://github.com/linrongbin16/fzfx.nvim/commit/e3b2e49cf9f7c8765cf55a01df2633188079881b))
* remove unused import ([33703c9](https://github.com/linrongbin16/fzfx.nvim/commit/33703c965c2a544ce8adb138650b0e1cafcd31de))
* setup legacy ([ebbed25](https://github.com/linrongbin16/fzfx.nvim/commit/ebbed25cddcae73383c0239407bf9c90371916c7))
* shellslash ([#91](https://github.com/linrongbin16/fzfx.nvim/issues/91)) ([2663cd4](https://github.com/linrongbin16/fzfx.nvim/commit/2663cd4d4ec4778dc55b2271838b2ec7454a1c3a))
* socket server ([#39](https://github.com/linrongbin16/fzfx.nvim/issues/39)) ([5613c56](https://github.com/linrongbin16/fzfx.nvim/commit/5613c5662870f27fe7ef45b9a955f0402dd3dff8))
* use 'buffer' instead 'edit' for buffers ([#67](https://github.com/linrongbin16/fzfx.nvim/issues/67)) ([4e74d79](https://github.com/linrongbin16/fzfx.nvim/commit/4e74d79108155a864723e131d2f9d9ff2f5cb9b0))
* use uv spawn ([#181](https://github.com/linrongbin16/fzfx.nvim/issues/181)) ([7fe84c6](https://github.com/linrongbin16/fzfx.nvim/commit/7fe84c606ed5847108035f3dded7745ad61f1450))
* uv.spawn ([#128](https://github.com/linrongbin16/fzfx.nvim/issues/128)) ([5d54505](https://github.com/linrongbin16/fzfx.nvim/commit/5d54505d9f06fe1fada283024ce38d7213f3761e))
* win_opts row/col ([#23](https://github.com/linrongbin16/fzfx.nvim/issues/23)) ([f035673](https://github.com/linrongbin16/fzfx.nvim/commit/f0356732db5801b424234223d4f306a25db0d35c))


### Reverts

* lower minimal required version v0.6 ([#245](https://github.com/linrongbin16/fzfx.nvim/issues/245)) ([89eb334](https://github.com/linrongbin16/fzfx.nvim/commit/89eb334df7920a75386b659cd007a3ec5ea6fe13))


### Break Changes

* 2023-08-17
  * Break: re-bind keys 'ctrl-e', 'ctrl-a' to 'toggle', 'toggle-all', remove 'ctrl-d'(deselect), 'alt-a'(deselect-all).
  * Break: re-bind key 'ctrl-l' (toggle-preview) to 'alt-p'.
* 2023-08-19
  * Break: refactor configs schema for general fzf-based searching commands.
* 2023-08-28
  * Deprecate: migrate 'git_commits' (`FzfxGCommits`) configs to new schema.
* 2023-08-30
  * Deprecate: migrate 'buffers' (`FzfxBuffers`) configs to new schema.
* 2023-09-11
  * Deprecate: migrate 'git_branches' (`FzfxGBranches`) configs to new schema.
* 2023-09-12
  * Deprecate: migrate 'git_files' (`FzfxGFiles`) configs to new schema.
* 2023-09-19
  * Deprecate: migrate 'live_grep' (`FzfxLiveGrep`) configs to new schema.
  * Deprecate: migrate 'files' (`FzfxFiles`) configs new schema.
* 2023-09-26
  * Break: drop support for Neovim v0.5.0, require minimal version &ge; v0.6.0.
* 2023-09-27
  * Minor break: move 'context_maker' option from 'providers' to 'other_opts' (in group config).
  * Minor break: drop support for 'line_type'/'line_delimiter'/'line_pos' option (in provider config).
* 2023-10-07
  * Deprecate: migrate 'GroupConfig' class to lua table.
* 2023-10-08
  - Deprecate: migrate 'InteractionConfig' class to lua table.
