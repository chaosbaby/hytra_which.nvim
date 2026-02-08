# Product Definition - Hydra-Which

## Vision
Bringing Hydra to which-key.nvim: Smart Treesitter move and universal loop mode for any plugin. It leverages `which-key.nvim` v3's `loop` mode to provide a "Hydra-like" experience for repetitive navigation tasks, especially Treesitter textobjects, Git hunks, and LSP diagnostics.

## Core Features
1. **Universal Hydra Activator**: Easily turn any existing `which-key` prefix into a loop mode using a simple trigger key (defaulting to `x`).
2. **Treesitter Textobjects Support**: Automatically generate a comprehensive set of keymaps for Treesitter navigation that immediately enter loop mode upon activation.
3. **Contextual Persistence**: Remembers the last used textobject/jumper for quick repeated actions.
4. **Minimalist API**: Simple `setup` function and user commands for easy integration.

## Target Audience
Neovim users who use `which-key.nvim` and want a more efficient way to perform repetitive jumps without re-entering prefix keys.
