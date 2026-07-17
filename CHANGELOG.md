# Changelog

All meaningful changes to Safe USB Eject by TCDOVERLORD should be recorded in this file.

The format is based on a simple versioned release history. Dates use `YYYY-MM-DD`.

## [Unreleased]

### Status

- No active development is planned.
- The project is in maintenance mode.
- Add confirmed fixes or approved features here before creating another release.

## [1.0.0] - Release date not recorded

### Added

- Batch launcher for starting the utility.
- PowerShell 5.1 or later engine.
- Automatic removable-drive detection.
- Drive selection with label, file system, size, and free-space details.
- Windows Restart Manager integration for detecting locking processes.
- Graceful application-close workflow.
- Explicitly approved optional force-close workflow.
- Protected-process safeguards.
- Lock recheck before eject.
- Volume dismount request.
- Windows Shell eject request.
- Removal verification and dated logging.
- Required `EJECT` confirmation.
- Safety documentation.
- README with architecture, execution pipeline, installation, quick start, roadmap, and support guidance.
- MIT license.

### Safety

- Force-close is not automatic.
- The utility stops when locks remain.
- Critical Windows processes are protected.
- Users are instructed to test first with a spare drive and non-critical copied files.

### Known limitations

- No graphical interface.
- No system tray launcher.
- No device serial display.
- No configurable protected-process list.
- No optional Sysinternals Handle integration.
- No signed release build.
- Automated tests are not included.

### Project status

- Version 1.0.0 is the accepted release baseline.
- Active development paused by owner choice.
- See `PROJECT_CONTINUITY.md` before resuming work.
