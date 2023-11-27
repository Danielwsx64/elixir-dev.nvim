set rtp^=./vendor/plenary.nvim/
set rtp^=./vendor/matcher_combinators.lua/
set rtp^=./vendor/nvim-treesitter/
set rtp^=../

runtime plugin/plenary.vim

lua require('plenary.busted')
lua require('matcher_combinators.luassert')

runtime plugin/nvim-treesitter

lua require('nvim-treesitter.configs').setup({sync_install = false})

" configuring the plugin
runtime plugin/elixir_dev.lua
lua require('elixir_dev').setup({ name = 'Jane Doe' })
