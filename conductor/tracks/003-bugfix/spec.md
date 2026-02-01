# Specification - Fix get_buf_lang nil error

## Problem
The function `M.get_supported_captures` fails with `attempt to call field 'get_buf_lang' (a nil value)`. This suggests that `require("nvim-treesitter.parsers")` does not contain `get_buf_lang` in the user's environment.

## Goal
Make the language detection more robust by checking for the existence of `get_buf_lang` and providing fallbacks (like `vim.bo.filetype`).

## Success Criteria
1. No more `nil value` errors when opening files.
2. Textobject filtering still works if Treesitter is available.
