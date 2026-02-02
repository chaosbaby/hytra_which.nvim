# Specification: Refine Hydra Activation

## Background
Currently, any textobject jump mapping (e.g., `<leader>mm`) explicitly calls `wk.show(..., { loop = true })`, forcing the user into Hydra mode even if they only wanted a single jump.

## Requirements
1.  **Direct Jumps**: Pressing `<leader>m[key]` (where key is a textobject like `m`, `f`) should perform the jump and **not** enter the persistent Hydra mode.
2.  **Explicit Activation**: Only a designated trigger key (default `<leader>mx`) should enter the persistent Hydra mode.
3.  **Persistence within Hydra**: Once in Hydra mode (via `<leader>mx`), pressing textobject keys should perform the jump and **stay** in the Hydra menu.

## Design
- Remove `wk.show({ keys = prefix, loop = true })` from the individual textobject mappings in `M.register_buffer_ts`.
- Rely on `which-key`'s `loop = true` behavior initiated by the trigger key in `M.activate`.
