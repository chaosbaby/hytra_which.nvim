# Implementation Plan - Direct SCM Parsing

- [x] Implement `M.get_captures_from_scm(lang)`: (Done)
    - Locate `.scm` files in runtime.
    - Parse using regex `@([%w%._]+)`.
- [x] Update `M.get_supported_captures(bufnr)` to use the new SCM parser. (Done)
- [x] Ensure it handles language inheritance (e.g., `typescript` might inherit from `ecma`). (Done)
- [x] Update `examples/treesitter_config.lua`. (Done)
- [x] Finalize Track 004. (Done)
