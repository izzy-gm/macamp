# MacAmp

A native macOS music player inspired by the classic Winamp. Built with SwiftUI and AVFoundation with no external dependencies.

## Features

- Multi-format playback: MP3, FLAC, WAV, M4A, AAC, AIFF
- Classic Winamp-inspired interface
- Real-time spectrum analyzer with FFT visualization
- 10-band equalizer
- Playlist management with M3U import/export
- Drag-and-drop playlist reordering
- Shuffle and repeat modes
- Multiple oscilloscope visualizations
- Milkdrop visualizer with fullscreen support
- Lyrics overlay (LRC format)
- Single-instance app behavior
- Keyboard shortcuts for playback control

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later (for building)

## Building

### Using the build script

```bash
# Build and run (debug)
./build.sh --run

# Build release
./build.sh --release

# Clean build
./build.sh --clean --run
```

### Using Xcode

1. Open `MacAmp.xcodeproj` in Xcode
2. Select the Winamp scheme
3. Build and run (Cmd+R)

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| X | Play/Pause |
| V | Stop |
| Z | Previous Track |
| B | Next Track |
| Cmd+L | Add Files |
| Cmd+Shift+L | Add Folder |

## License

MIT License - Feel free to use and modify as needed.

## Acknowledgements

Based on original work by [mgreenwood1001](https://github.com/mgreenwood1001).
