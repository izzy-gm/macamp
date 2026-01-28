# MacAmp macOS - Usage Guide

Welcome to MacAmp macOS! This guide will help you get started with your nostalgic music player.

## Getting Started

### Opening the Application

1. Open `MacAmp.xcodeproj` in Xcode
2. Build and run (⌘R) or use the command line: `xcodebuild -project MacAmp.xcodeproj -scheme MacAmp -configuration Debug build`
3. The application will launch with the classic MacAmp interface

### First Time Setup

When you first launch MacAmp, you'll see:
- Main player window with controls
- An empty playlist
- The spectrum analyzer

## Adding Music

### Method 1: File Menu
1. Click **File → Add Files...** (⌘L)
2. Select one or more MP3 or FLAC files
3. Click **Open**

### Method 2: Folder Menu
1. Click **File → Add Folder...** (⌘⇧L)
2. Select a folder containing music
3. All MP3 and FLAC files will be added recursively

### Method 3: Drag and Drop
1. Drag MP3 or FLAC files from Finder
2. Drop them directly onto the playlist area

## Player Controls

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `X` | Play/Pause |
| `V` | Stop |
| `Z` | Previous Track |
| `B` | Next Track |

### Mouse Controls

- **Play/Pause Button**: Start or pause playback
- **Stop Button**: Stop playback and reset position
- **Previous Button**: Go to previous track
- **Next Button**: Go to next track
- **Volume Slider**: Adjust volume (0-100%)
- **Position Slider**: Seek within the current track

## Interface Components

### Main Player Window

The main player window (275px wide) features:

1. **Title Bar**: Shows "MacAmp" with the classic blue gradient
2. **Display Area**: Shows currently playing track title and artist
3. **Spectrum Analyzer**: 20-band visual frequency display
4. **Time Display**: Shows current time / total duration
5. **Volume Control**: Speaker icon with slider and percentage
6. **Position Slider**: Seek bar for the current track
7. **Playback Controls**: Previous, Play/Pause, Stop, Next buttons
8. **Toggle Buttons**: 
   - **PL**: Show/hide playlist
   - **EQ**: Show/hide equalizer

### Playlist Window

The playlist section displays:
- Track number or playing indicator (🔊)
- Track title and artist
- Track duration
- Currently playing track highlighted in green

**Playlist Actions:**
- **Click a track**: Play it immediately
- **Right-click a track**: 
  - Play
  - Remove from playlist
- **Clear button** (trash icon): Remove all tracks

### Equalizer Window

10-band parametric equalizer with frequencies:
- 60 Hz
- 170 Hz
- 310 Hz
- 600 Hz
- 1 KHz
- 3 KHz
- 6 KHz
- 12 KHz
- 14 KHz
- 16 KHz

Each band can be adjusted from -12dB to +12dB.

**Reset Button**: Returns all bands to 0dB (flat response)

### Spectrum Analyzer

Real-time 20-band frequency visualization in classic MacAmp green. The bars animate based on the music being played.

## Color Scheme

MacAmp macOS uses the classic color palette:

- **Background**: Black
- **Title Bar**: Blue gradient (#163862 → #2659A5)
- **Display**: Dark green background with bright green text (#00FF80)
- **Buttons**: Dark gray (#333333) with highlights
- **Playlist**: Near-black background with white text
- **Selected**: Blue highlight (#2659A5)
- **Spectrum**: Bright green (#00FF80)

## Supported Formats

### Currently Supported
- **MP3**: Full support via AVFoundation
- **FLAC**: Full support via AVFoundation

### Metadata Support
The player reads and displays:
- Track title
- Artist name
- Duration
- File size

## Tips and Tricks

1. **Window Management**: The main player window has a fixed width (275px) to maintain the classic MacAmp look, but the playlist and equalizer can be toggled on/off.

2. **Playlist Organization**: Tracks are played in the order they appear in the playlist. Currently, there's no shuffle or repeat mode (feel free to add these features!).

3. **Audio Quality**: The app uses AVFoundation's audio engine with a 10-band parametric equalizer, providing high-quality audio processing.

4. **Performance**: The spectrum analyzer currently uses simulated data. For production use, you could implement real FFT analysis using AVAudioEngine taps.

## Troubleshooting

### Music Won't Play
- Ensure the file is a valid MP3 or FLAC
- Check that the file isn't corrupted
- Make sure system volume isn't muted

### Files Won't Open
- Verify the app has necessary permissions in System Settings → Privacy & Security
- The app is sandboxed and requires user-selected file access

### No Sound
- Check the volume slider in the player (should be 75% by default)
- Verify system audio output is working
- Check that the track actually loaded (duration should show in display)

## Technical Details

### Architecture
- **SwiftUI**: Modern declarative UI framework
- **AVFoundation**: Professional audio playback engine
- **AVAudioEngine**: Real-time audio processing pipeline
- **Combine**: Reactive programming for state management

### Audio Pipeline
```
Audio File → AVAudioPlayerNode → 10-Band EQ → Main Mixer → Output
```

### Sandbox Permissions
The app requests:
- `com.apple.security.files.user-selected.read-only`: To read user-selected audio files
- `com.apple.security.assets.music.read-only`: To access music library (optional)

## Development

Want to contribute or customize?

### Key Files
- `MacAmpApp.swift`: Application entry point
- `AudioPlayer.swift`: Core audio engine
- `PlaylistManager.swift`: Playlist logic
- `MainPlayerView.swift`: Main UI
- `MacAmpColors.swift`: Color definitions

### Adding Features

Some ideas for enhancements:
- Shuffle and repeat modes
- Playlist save/load
- Keyboard shortcuts customization
- Skins/themes support
- More audio formats (AAC, WAV, OGG)
- Real FFT spectrum analyzer
- Playlist search/filter
- Album artwork display
- Mini-player mode
- Global media key support
- Last.fm scrobbling

## Credits

Built with ❤️ as a tribute to the legendary MacAmp player that shaped a generation of music lovers.

"It really whips the llama's ass!" - Justin Frankel

## License

MIT License - See LICENSE file for details

