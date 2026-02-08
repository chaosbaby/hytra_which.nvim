# Implementation Plan - Fix get_buf_lang nil error

- [x] Update `lua/hydra-which/init.lua`: (Done)
    - Check if `parsers.get_buf_lang` exists before calling.
    - Fallback to `vim.bo[bufnr].filetype`.
    - Ensure `query.get_query` is also handled safely.
- [x] Update `examples/treesitter_config.lua` with the same fixes. (Done)
- [x] Verify fix by ensuring no errors are thrown. (Done)
- [x] Finalize Track 003. (Done)
