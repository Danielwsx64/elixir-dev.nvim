# elixir-dev.nvim

[![Integration][integration-badge]][integration-runs]

A Neovim lua plugin for Elixir development.


## Installation

Using [plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'Danielwsx64/elixir-dev.nvim'
```

Using [packer](https://github.com/wbthomason/packer.nvim):

```
use "Danielwsx64/elixir-dev.nvim"
```

## Using

### Pipelize
```
:ElixirDev pipelize
```

![Pipelize Example](https://github.com/Danielwsx64/elixir-dev.nvim/assets/17304947/7afca688-62f1-448b-b7a3-977f71909c7b)

### Create custom keymaps

```vimscript
vim.keymap.set("n", "<leader>fp", "<CMD>ElixirDev pipelize<CR>", { desc = "Elixir Pipelize function", silent = true })
```

## Contributing

### Testing

This uses [busted][busted], [luassert][luassert] (both through
[plenary.nvim][plenary]) and [matcher_combinators][matcher_combinators] to
define tests in `test/spec/` directory. These dependencies are required only to
run tests, that's why they are installed as git submodules.

Make sure your shell is in the `./test` directory or, if it is in the root directory,
replace `make` by `make -C ./test` in the commands below.

To init the dependencies run

```bash
$ make prepare
```

To run all tests just execute

```bash
$ make test
```

If you have [entr(1)][entr] installed you may use it to run all tests whenever a
file is changed using:

```bash
$ make watch
```

In both commands you myght specify a single spec to test/watch using:

```bash
$ make test SPEC=spec/elixir_dev/pipelize_spec.lua
$ make watch SPEC=spec/elixir_dev/pipelize_spec.lua
```

# Features (TODO)

- [x] Function pipelize
- [ ] Switch anonymous function sintax (fn/&)
- [ ] Switch map keys (string/atom)
- [ ] Switch map, lists, keywords (inline/multiline)

**NOTE**: Created with help of [plugin-template][plugin-template].

[entr]: https://eradman.com/entrproject/
[busted]: https://olivinelabs.com/busted/
[luassert]: https://github.com/Olivine-Labs/luassert
[plenary]: https://github.com/nvim-lua/plenary.nvim
[matcher_combinators]: https://github.com/m00qek/matcher_combinators.lua
[plugin-template]: https://github.com/m00qek/plugin-template.nvim
[integration-badge]: https://github.com/Danielwsx64/elixir-dev.nvim/actions/workflows/integration.yml/badge.svg
[integration-runs]: https://github.com/Danielwsx64/elixir-dev.nvim/actions/workflows/integration.yml
