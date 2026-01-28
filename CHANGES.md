# Recent Changes

## Fixes Applied

### ✅ Window Sizing Fixed
- Window now sizes exactly to content (275px width)
- No black space around left/right sides
- Added `.fixedSize()` to prevent extra space
- Window auto-sizes to content using `setContentSize()`

### ✅ Playlist Toggle Fixed  
- PL button now properly shows/hides the playlist window
- Fixed button binding order (was reversed)
- Playlist window fixed at 275px width × 250px height

### ✅ Frameless Window
- Removed macOS window chrome completely
- No red/yellow/green buttons visible
- Custom MacAmp-style window controls work
- Draggable blue title bar

### 🎨 Sprite System Created
- Added `MacAmpSkinSprites.swift` for using actual graphics
- Imported your MacAmp skin image as `MacAmpSkin` asset
- Defined sprite coordinates for all UI elements:
  - Buttons (Previous, Play, Pause, Stop, Next, Eject)
  - Toggle buttons (EQ, PL, Shuffle, Repeat) 
  - Sliders (Position, Volume, Balance)
  - LED numbers for time display

## Next Steps

To fully use the actual MacAmp graphics, we need to:

1. **Extract button sprites** from the skin image at specific coordinates
2. **Replace SwiftUI buttons** with bitmap images
3. **Verify sprite coordinates** match your skin layout
4. **Add pressed/hover states** for each button

The sprite system is ready - we just need to integrate it with the button views.

## How to Test

1. Build: `xcodebuild -project MacAmp.xcodeproj -scheme MacAmp build`
2. Run: `open ~/Library/Developer/Xcode/DerivedData/MacAmp-*/Build/Products/Debug/MacAmp.app`
3. Test PL button to toggle playlist
4. Verify no black space around window edges
5. Check that window is exactly 275px wide

## Known Issues

- Still using SwiftUI-generated buttons (not bitmap sprites yet)
- Need to map exact sprite coordinates from your skin image
- Button graphics need to be swapped in next iteration

