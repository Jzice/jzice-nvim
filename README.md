# jzice-nvim

## Info

Neovim lua config in one file.

![pic1](./img/pic1.png)

## Require

* neovim > 0.7.0
* git
* rg

## Feature

* plugin manager: packer
* theme: molokai
* ui: nvim-tree + symbols-outline + lualine(statusline)
* lspconfig + lsp-installer + nvim-cmp
* telescope + anyjump + lspsaga
* hop + vim-eft
* nvim-autopairs
* nvim-notify
* vim-fugitive+lazygit + gitsigns
* ...

## Usage

1. curl 'https://raw.githubusercontent.com/jzice/jzice-nvim/main/lua/jzice-nvim/init.lua' > ~/.config/nvim/init.lua
2. start nvim first to install packer auto
3. nvim +PackerSync

## config

```
require('jzice-nvim').setup({
    theme = 'molokai',
    settings = {
      ...
    },
    packer = {
        git = {
            default_url_format = 'https://github.com/%s',
        },
    },
})
```


## Plugin list

* any-jump.vim
* bufdelete.nvim
* bufferline.nvim
* cmp-buffer
* cmp-cmdline
* cmp-nvim-lsp
* cmp-nvim-lsp-signature-help
* cmp-path
* cmp-under-comparator
* cmp-vsnip
* cmp_luasnip
* Comment.nvim
* DrawIt
* friendly-snippets
* gist-vim
* git-blame.nvim
* gitsigns.nvim
* GoldenView.Vim
* goyo.vim (not loaded)
* hop.nvim
* indent-blankline.nvim
* lazygit.nvim
* leetcode.vim
* limelight.vim
* lsp_signature.nvim
* lspkind.nvim
* lspsaga.nvim
* lualine.nvim
* LuaSnip
* neoformat
* NrrwRgn
* nvim-autopairs
* nvim-cmp
* nvim-dap
* nvim-dap-go
* nvim-dap-python
* nvim-dap-ui
* nvim-dap-virtual-text
* nvim-lightbulb
* nvim-lsp-installer
* nvim-lsp-notify
* nvim-lspconfig
* nvim-notify
* nvim-tree.lua
* nvim-treesitter
* nvim-ts-context-commentstring
* nvim-ts-rainbow
* nvim-web-devicons
* orgmode
* packer.nvim (not loaded)
* plenary.nvim
* salt-vim (not loaded)
* symbols-outline.nvim
* telescope-symbols.nvim
* telescope.nvim
* todo-comments.nvim
* undotree
* vim-arsync
* vim-better-default
* vim-choosewin
* vim-colorschemes
* vim-dispatch 
* vim-easy-align
* vim-eft
* vim-expand-region
* vim-floaterm
* vim-fugitive
* vim-hardtime
* Vim-Jinja2-Syntax 
* vim-matchup
* vim-repeat
* vim-rooter
* vim-startify
* vim-surround
* vim-translator
* vim-visual-multi
* vim-vsnip
* vim-zenroom2
* VimVLanguage
* vimwiki
* vista.vim 
* which-key.nvim

