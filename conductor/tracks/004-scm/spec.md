# Specification - Direct SCM Parsing

## Goal
Avoid depending on the `nvim-treesitter` query API (which might change). Instead, directly locate and parse `textobjects.scm` files from the Neovim runtime path to identify supported textobject captures.

## Requirements
1. Determine the language of the buffer (fallback to filetype).
2. Use `nvim_get_runtime_file` to find all `queries/<lang>/textobjects.scm` files.
3. Read the content of these files.
4. Extract all `@name` patterns (captures).
5. Use these captures to filter the mapping list.

## Why
This makes the plugin more resilient to upstream API changes while still providing accurate, language-specific filtering.
