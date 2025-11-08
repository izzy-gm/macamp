import SwiftUI

struct WinampColors {
    // Modern Winamp color scheme (darker, sleeker)
    static let background = Color(red: 0, green: 0, blue: 0)
    
    // Title bar colors (darker blue-grey)
    static let titleBar = Color(red: 30/255, green: 40/255, blue: 60/255)
    static let titleBarInactive = Color(red: 40/255, green: 40/255, blue: 45/255)
    static let titleBarHighlight = Color(red: 40/255, green: 55/255, blue: 80/255)
    
    // Display/LCD colors (dark with bright green text)
    static let displayBg = Color(red: 8/255, green: 20/255, blue: 16/255)
    static let displayText = Color(red: 0, green: 1.0, blue: 0.5)
    static let displayInactive = Color(red: 0, green: 0.3, blue: 0.2)
    
    // Main window background (darker grey-blue)
    static let mainBg = Color(red: 50/255, green: 55/255, blue: 70/255)
    static let mainBgLight = Color(red: 65/255, green: 70/255, blue: 85/255)
    static let mainBgDark = Color(red: 35/255, green: 40/255, blue: 55/255)
    
    // Button colors (darker, more modern)
    static let buttonFace = Color(red: 70/255, green: 75/255, blue: 90/255)
    static let buttonLight = Color(red: 90/255, green: 95/255, blue: 110/255)
    static let buttonDark = Color(red: 50/255, green: 55/255, blue: 70/255)
    static let buttonPressed = Color(red: 40/255, green: 45/255, blue: 60/255)
    static let buttonHover = Color(red: 80/255, green: 85/255, blue: 100/255)
    
    // Playlist colors
    static let playlistBg = Color(red: 0, green: 0, blue: 0)
    static let playlistText = Color(red: 0, green: 1.0, blue: 0.5)
    static let playlistSelected = Color(red: 0, green: 0.4, blue: 0.2)
    static let playlistCurrentTrack = Color(red: 0, green: 0.9, blue: 0.45)
    static let playlistCurrentTrackBg = Color(red: 0.1, green: 0.2, blue: 0.5) // Dark blue background for playing track
    
    // Equalizer colors (classic Winamp orange/yellow gradient)
    static let eqSliderBg = Color(red: 20/255, green: 25/255, blue: 35/255)
    static let eqSliderTop = Color(red: 1.0, green: 0.8, blue: 0.2) // Yellow at top
    static let eqSliderBottom = Color(red: 1.0, green: 0.4, blue: 0.0) // Orange at bottom
    static let eqFrame = Color(red: 60/255, green: 65/255, blue: 80/255)
    
    // Spectrum/Visualizer
    static let spectrumBg = Color(red: 0, green: 0, blue: 0)
    static let spectrumDot = Color(red: 0, green: 1.0, blue: 0.5)
    static let spectrumPeak = Color(red: 1.0, green: 0, blue: 0)
    
    // Border colors (subtler)
    static let borderLight = Color(red: 85/255, green: 90/255, blue: 105/255)
    static let borderDark = Color(red: 30/255, green: 35/255, blue: 50/255)
    static let borderAccent = Color(red: 60/255, green: 65/255, blue: 80/255)
}

