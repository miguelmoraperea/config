-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)

    use 'wbthomason/packer.nvim'
    use 'EdenEast/nightfox.nvim'
    use 'scrooloose/nerdtree'
    use 'junegunn/rainbow_parentheses.vim'
    use 'preservim/nerdcommenter'

    use 'neovim/nvim-lspconfig'
    use 'hrsh7th/cmp-nvim-lsp'
    use 'hrsh7th/cmp-buffer'
    use 'hrsh7th/cmp-path'
    use 'hrsh7th/cmp-cmdline'
    use 'hrsh7th/nvim-cmp'
    use 'L3MON4D3/LuaSnip'

    use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
    use 'nvim-treesitter/playground'
    use 'nvim-treesitter/completion-treesitter'

    use 'euclidianAce/BetterLua.vim'
    use 'nvim-lua/plenary.nvim'

    use 'ThePrimeagen/harpoon'

    use 'nvim-lua/popup.nvim'
    use 'nvim-lua/plenary.nvim'
    use 'nvim-telescope/telescope.nvim'
    use 'nvim-telescope/telescope-fzy-native.nvim'

    use 'mhinz/vim-signify'
    use 'norcalli/nvim-colorizer.lua'

    use { 'sindrets/diffview.nvim', requires = 'nvim-lua/plenary.nvim' }
    use 'kyazdani42/nvim-web-devicons'

    use 'tpope/vim-fugitive'
    use 'dstein64/vim-startuptime'

    use 'jose-elias-alvarez/null-ls.nvim'

    use 'simrat39/symbols-outline.nvim'

end)
