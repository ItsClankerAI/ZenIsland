# Pomodoro Timer Extension

Standalone ZenIsland extension implemented only with the `ZenIsland` + `View` JavaScript API.

## Files

- `manifest.json` - extension metadata and permissions
- `index.js` - extension logic and UI (compact, minimal, expanded, full)
- `settings.json` - declarative settings schema rendered by the host app

## Notes

- No imports from this app codebase.
- Can be copied to any ZenIsland-compatible extension host.
- Designed to be packaged/distributed independently later (zip/Git release/registry).
