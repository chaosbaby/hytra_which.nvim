# Implementation Plan: Dynamic Textobject Analysis and Toggle

## Step 1: Add State Management
- Add `M.state` to `lua/hytra-which/init.lua` to track the mode (`refined` vs `full`).
- Store `prefix` and `trigger` in `M.state` for easy re-registration.

## Step 2: Implement Buffer Capture Detection
- Implement `M.get_actual_captures(bufnr)` using `vim.treesitter.query`.
- This function will return a map of capture names to `true` for those found in the buffer.

## Step 3: Update Registration Logic
- Modify `M.register_buffer_ts` to use `M.get_actual_captures` when in `refined` mode.
- Ensure `M.register_buffer_ts` can be called multiple times to refresh mappings.

## Step 4: Add Toggle Functionality
- Implement `M.toggle_mode(bufnr)`.
- Register the toggle keymap (e.g., `<leader>mz`) in `M.register_buffer_ts`.

## Step 5: Integration and Testing
- Update `M.setup_ts` to initialize state.
- Verify that switching modes updates the which-key menu.
