# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Native macOS music player recreating the classic Winamp experience. Built with SwiftUI and AVFoundation (no external dependencies).

- **Requirements**: macOS 13.0+, Xcode 15.0+
- **Current Version**: 1.1.0

## Build Commands

```bash
# Build and run (debug)
./build.sh --run

# Build release
./build.sh --release

# Clean build
./build.sh --clean --run

# Version bump
./bump-version.sh [major|minor|patch]

# Xcode command line
xcodebuild -project Winamp.xcodeproj -scheme Winamp -configuration Debug build
```

## Architecture

### Core Components (Sources/)

| File | Purpose |
|------|---------|
| `AudioPlayer.swift` | Singleton audio engine wrapping AVAudioEngine with 10-band EQ |
| `PlaylistManager.swift` | Singleton managing playlist state, shuffle, repeat, file access |
| `MainPlayerView.swift` | Main UI (3,300+ LOC) - player controls, spectrum, display |
| `Track.swift` | Audio track model with metadata extraction |

### Key Patterns

**Singleton State Management**
- `AudioPlayer.shared` - all audio playback and EQ control
- `PlaylistManager.shared` - playlist and file operations
- Both conform to `ObservableObject` with `@Published` properties

**Audio Pipeline**
```
AVAudioFile → AVAudioPlayerNode → AVAudioUnitEQ (10-band) → MainMixer → Output
                                                                ↓
                                                          Audio Tap (FFT)
                                                                ↓
                                                         Spectrum Display
```

**Security-Scoped Bookmarks**
- App is sandboxed with user-selected file access
- Bookmarks persisted in UserDefaults for cross-session access
- Special handling for network volumes via `statfs()` MNT_LOCAL check

**Async Patterns**
- Audio operations dispatched to `audioQueue` (serial, userInteractive QoS)
- File scanning and metadata extraction on background threads
- UI updates dispatched to main thread

### Keyboard Shortcuts (defined in WinampApp.swift)

| Key | Action |
|-----|--------|
| X | Play/Pause |
| V | Stop |
| Z | Previous |
| B | Next |
| ⌘L | Add Files |
| ⌘⇧L | Add Folder |

## Development Notes

- CI auto-bumps patch version on main branch pushes (see `.github/workflows/build.yml`)
- Spectrum analyzer uses real FFT via Apple Accelerate framework (vDSP) with logarithmic frequency binning
- Supports MP3, FLAC, WAV, M4A, AAC, AIFF playback; M3U playlist import/export
- LRC lyrics files parsed and displayed during playback
- Single-instance app: opening files activates existing instance instead of launching new one
- Playlist supports drag and drop reordering (flat view only, disabled during search)
- Real bitrate display calculated from file size and duration
