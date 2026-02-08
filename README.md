# hydra-which.nvim

[English](./README.md) | [中文](./README_zh.md)

A lightweight Neovim plugin that leverages `which-key.nvim` v3's `loop` mode to provide a "Hydra-like" experience for repetitive navigation tasks, with smart Treesitter textobject detection.

## 🚀 Features

- **Universal Hydra Activator**: Turn any `which-key` prefix into a loop mode with a single trigger key (default: `x`).
- **Smart Treesitter Integration**: 
    - **SCM Auto-Detection**: Automatically identifies supported textobjects by parsing language-specific `.scm` files.
    - **Refined Mode (Dynamic Analysis)**: Optionally filters the menu to only show textobjects that actually exist in the current buffer.
    - **Toggle Mode**: Switch between "Refined" and "Full" modes on the fly (press `z` in the menu).
- **Context Awareness**: Remembers the last jumped textobject for quick repeats.
- **Zero Overhead**: Minimalist implementation using native `which-key` capabilities.

## 📦 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "chaosbaby/hydra-which.nvim",
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
        require("hydra-which").setup(opts)
    end
}
```

## 🛠️ Usage

### Treesitter Mode
- Press `<leader>m` to open the textobject menu.
- **Smart Filtering**: Only textobjects supported by the current filetype (and optionally those existing in the buffer) are shown.
- **Jump**: Press a key (e.g., `f` for function) to jump. The menu stays open (Hydra mode).
- **Repeat**: 
    - Press `j` / `k` to jump to the **next/previous start** of the last object.
    - Press `J` / `K` to jump to the **next/previous end** of the last object.
- **Toggle**: Press `z` to toggle between **Refined** (only present in buffer) and **Full** (all supported by language) modes.
- **Re-activate**: Press `<leader>mx` to quickly re-enter the loop using the last jump target.

### Universal Mode
- If you have a group like `<leader>h` for Git hunks:
- Press `<leader>hx` to enter "Git Hydra".
- Now all keys within the `<leader>h` group (like `j`, `k` for next/prev hunk) can be pressed repeatedly without re-triggering the prefix.

## ⌨️ Commands

- `:HydraOn <prefix> [trigger]` - Dynamically enable Hydra mode for any key prefix.

## 📄 License

MIT
