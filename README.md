# hytra-which.nvim

A lightweight Neovim plugin that leverages `which-key.nvim` v3's `loop` mode to provide a "Hydra-like" experience for repetitive navigation tasks.

## 🚀 Features

- **Universal Hydra Activator**: Turn any `which-key` prefix into a loop mode with a single trigger key (default: `x`).
- **Treesitter Integration**: Built-in support for Treesitter textobjects with automatic keymap generation.
- **Context Awareness**: Remembers the last jumped textobject for quick repeats.
- **Zero Overhead**: Minimalist implementation using native `which-key` capabilities.

## 📦 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "chaoszendao/hytra-which",
    dependencies = {
        "folke/which-key.nvim",
        "nvim-treesitter/nvim-treesitter",
        "nvim-treesitter/nvim-treesitter-textobjects",
    },
    opts = {
        -- Built-in Treesitter Textobjects configuration
        ts = {
            prefix = "<leader>m",
            trigger = "x"
        },
        -- Universal Activators for other groups
        groups = {
            ["<leader>h"] = "x", -- Git Hunks (gitsigns)
            ["<leader>d"] = "x", -- LSP Diagnostics
        }
    },
    config = function(_, opts)
        require("hytra-which").setup(opts)
    end
}
```

## 🛠️ Usage

### Treesitter Mode
- Press `<leader>mf` to jump to the next function.
- The `which-key` panel will remain open (Hydra mode).
- Press `j` or `k` to continue jumping to next/previous functions.
- Press `x` (or your configured trigger) to re-enter Hydra mode using the last jump target.

### Universal Mode
- If you have a group like `<leader>h` for Git hunks:
- Press `<leader>hx` to enter "Git Hydra".
- Now `j` and `k` (or whatever keys are in that group) can be pressed repeatedly.

## ⌨️ Commands

- `:HytraOn <prefix> [trigger]` - Dynamically enable Hydra mode for any key prefix.

## 📄 License

MIT