# Specification: Dynamic Textobject Analysis and Toggle

## Background
Currently, `hydra-which.nvim` filters textobjects based on whether the language supports them (by parsing SCM files). However, it shows all supported objects even if they don't exist in the current buffer.

## Requirements
1.  **Buffer-Specific Analysis**: Detect which textobjects actually have matches in the current buffer using Tree-sitter queries.
2.  **Refined Mode (Default)**: In this mode, only show textobjects that:
    - Are defined in `M.defines`.
    - Are supported by the language's SCM.
    - **Actually exist** in the current buffer.
3.  **Full Mode**: Show all textobjects that:
    - Are defined in `M.defines`.
    - Are supported by the language's SCM.
    (This is the current behavior).
4.  **Toggle Mechanism**:
    - Add a toggle key (default `z` after the prefix, e.g., `<leader>mz`).
    - Toggling should switch between "Refined" and "Full" modes.
    - After toggling, the which-key menu should be updated immediately.

## Design
- `M.state` table to store current mode and settings.
- `M.get_actual_captures(bufnr)`: Returns a set of capture names present in the buffer.
- `M.register_buffer_ts` will check `M.state.mode`.
- A new function `M.toggle_mode()` to update state and re-register.
