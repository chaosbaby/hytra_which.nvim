# Workflow - Hydra-Which

## Branching Model: Git Flow
- `master`: Production-ready code.
- `develop`: Integration branch for features.
- `feature/*`: New features and tracks.
- `release/*`: Preparing for a new production release.
- `hotfix/*`: Quick fixes for production.

## Task Management: Conductor
- Each significant change or group of related tasks is managed as a **Track**.
- Tracks are registered in `conductor/tracks.md`.
- Each track has its own folder in `conductor/tracks/<track_id>/` with a `plan.md` and `spec.md`.

## Quality Control
- Manual testing in Neovim.
- Adherence to Neovim plugin directory conventions.
