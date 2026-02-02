# Implementation Plan: Refine Hydra Activation

## Step 1: Update Mapping Registration
- Modify `M.register_buffer_ts` in `lua/hytra-which/init.lua`.
- Remove the anonymous function wrapper that calls `wk.show` for textobject keys.
- Map textobject keys directly to a function that calls `M.ts_jump`.

## Step 2: Verification
- Verify that `<leader>mm` jumps once and exits.
- Verify that `<leader>mx` enters Hydra mode.
- Verify that within Hydra mode, pressing `m` jumps and keeps the menu open.
