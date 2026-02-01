# Specification - Dynamic Textobject Filtering

## Goal
Automatically filter the list of Treesitter textobjects displayed in `which-key` based on what the current buffer's language actually supports. This avoids "empty operations" where a key is mapped but the underlying textobject doesn't exist for that filetype.

## Requirements
1. Detect the Treesitter language for the current buffer.
2. Query Treesitter for supported textobject captures.
3. Filter `M.defines` against supported captures.
4. Register filtered keymaps as buffer-local mappings.
5. Re-evaluate and re-register whenever a buffer's filetype changes.
