# Implementation Plan - Project Renaming

## Phase 1: Repository Renaming
- [ ] Rename GitHub repository using `gh repo edit --rename hydra-which.nvim`.
- [ ] Update local git remote URL: `git remote set-url origin git@github.com:chaosbaby/hydra-which.nvim.git`.

## Phase 2: File System Changes
- [ ] Rename directory `lua/hydra-which` to `lua/hydra-which`.
- [ ] Rename file `doc/hydra-which.txt` to `doc/hydra-which.txt`.

## Phase 3: Content Updates
- [ ] Replace all occurrences of `hydra-which` with `hydra-which` (case-insensitive where appropriate).
- [ ] Replace all occurrences of `hydra-which` with `hydra-which` (especially in repo URLs and headers).
- [ ] Update `conductor/index.md`, `conductor/product.md`, etc.
- [ ] Update all previous track files to reflect the new name (optional but good for consistency).

## Phase 4: Verification
- [ ] Verify `require("hydra-which")` works (if possible).
- [ ] Check `gh repo view` to confirm renaming.
