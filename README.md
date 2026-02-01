## what it is about
this is neovim plug to enable hytra mode with ease with which-key
with main features like to hytra mode
1. register a group of keymaps 
2. unregister a group of keymaps
5. auto gen text-objects keymap with current file type

## what it is for
1. to make some group of keymaps more convenient to hydra mode
  1. repeat action in plug:
    1. lsp diagnostics
    2. gitsigns hunk
    3. coverage uncovered line
    4. treesitter textobject such as: function, call, assignment etc.
2. disable a group of keymaps also with is show in which panel
3. assign a keymap group to a prefix with ease

## what is the requires
plugs to enhance it  
1. "folke/which-key.nvim"  for hydra mode
2. "nvim-treesitter/nvim-treesitter","nvim-treesitter/nvim-treesitter-textobjects" for textobject keymaps group auto gen.

## how to install it
	{
		"chaoszendao/hytra-which ",
		event = "VeryLazy",
        opts = {
        
        }
	},
## how to use it
if you know how to use which-key and treesitter textobjects, you already know how to use it

## comparison with others
1. nvim-hydra
  1. settings for each group
  2. complexed work with which-key

## examples the way to use it
1. command like :hydraToggle prefix|keymap lhs
2. command like :hydraOn <leader>mt
## some recommendations

