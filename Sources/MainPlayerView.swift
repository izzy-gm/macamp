import SwiftUI

struct MainPlayerView: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    @EnvironmentObject var playlistManager: PlaylistManager
    @Binding var showPlaylist: Bool
    @Binding var showEqualizer: Bool
    @Binding var isShadeMode: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Classic Winamp title bar with logo
            ClassicTitleBar(isShadeMode: $isShadeMode)
            
            // Main content area - matching reference layout exactly
            VStack(spacing: 0) {
                // Top section: Spectrum on left, song info on right
                HStack(spacing: 6) {
                    // LEFT: Spectrum visualizer with time above it
                    VStack(spacing: 0) {
                        // Time display with play/pause indicator
                        HStack(spacing: 4) {
                            Text(audioPlayer.isPlaying ? "II" : "▶")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(WinampColors.displayText)
                            
                            Text(formatTime(audioPlayer.currentTime))
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundColor(WinampColors.displayText)
                                .shadow(color: WinampColors.displayText.opacity(0.6), radius: 3, x: 0, y: 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black)
                        
                        // Spectrum visualizer in dark box
                        ClassicVisualizerView()
                            .frame(height: 42)
                            .background(Color.black)
                    }
                    .frame(width: 185)
                    .background(Color.black)
                    .cornerRadius(4)
                    
                    // RIGHT: Song info, bitrate, sliders, and buttons
                    VStack(spacing: 4) {
                        // Song title display
                        Text(playlistManager.currentTrack?.title ?? "DJ Mike Llama • Llama Whippin' Intro")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(WinampColors.displayText)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(red: 0.1, green: 0.12, blue: 0.18))
                            .cornerRadius(3)
                        
                        // Bitrate and format info row
                        HStack(spacing: 4) {
                            // Bitrate in green box
                            Text("128")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(WinampColors.displayText)
                                .cornerRadius(3)
                            
                            Text("kbps")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.7))
                            
                            // Sample rate in green box
                            Text("44")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(WinampColors.displayText)
                                .cornerRadius(3)
                            
                            Text("kHz")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.7))
                            
                            Spacer()
                            
                            Text("mono")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.5))
                            
                            Text("stereo")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(WinampColors.displayText)
                        }
                        .padding(.horizontal, 4)
                        
                        // Sliders row with EQ/PL buttons
                        HStack(spacing: 4) {
                            // Position slider (orange/yellow)
                            ModernSlider(
                                value: Binding(
                                    get: { audioPlayer.currentTime },
                                    set: { audioPlayer.seek(to: $0) }
                                ),
                                range: 0...max(audioPlayer.duration, 1),
                                color: Color(red: 0.9, green: 0.7, blue: 0.2)
                            )
                            .frame(width: 90, height: 20)
                            
                            // Volume slider (green)
                            ModernSlider(
                                value: Binding(
                                    get: { Double(audioPlayer.volume) },
                                    set: { audioPlayer.setVolume(Float($0)) }
                                ),
                                range: 0...1,
                                color: WinampColors.displayText
                            )
                            .frame(width: 70, height: 20)
                            
                            // EQ and PL buttons
                            HStack(spacing: 2) {
                                ModernToggleButton(text: "EQ", isOn: $showEqualizer)
                                ModernToggleButton(text: "PL", isOn: $showPlaylist)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 6)
                .padding(.bottom, 4)
                
                // Large progress bar with 3D inset effect
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Inset background with 3D shadow effect
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.6))
                            .overlay(
                                // Inner shadow effect
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [Color.black.opacity(0.8), Color.white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                        
                        // Progress fill with raised 3D effect (orange/yellow gradient)
                        RoundedRectangle(cornerRadius: 7)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.98, green: 0.78, blue: 0.28),
                                        Color(red: 0.88, green: 0.68, blue: 0.18)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: max(16, geo.size.width * CGFloat(audioPlayer.currentTime / max(audioPlayer.duration, 1))))
                            .overlay(
                                // Raised bevel on progress fill
                                RoundedRectangle(cornerRadius: 7)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.5), Color.black.opacity(0.3)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .padding(2)
                    }
                    .frame(height: 20)
                    .overlay(
                        // Outer border
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.black.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                let percent = Double(drag.location.x / geo.size.width)
                                let newTime = audioPlayer.duration * percent
                                audioPlayer.seek(to: max(0, min(newTime, audioPlayer.duration)))
                            }
                    )
                }
                .frame(height: 20)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                
                // Control buttons row
                HStack(spacing: 4) {
                    // Main playback controls
                    HStack(spacing: 2) {
                        WinampButton(icon: "⏮", width: 32) { playlistManager.previous() }
                        WinampButton(icon: "▶", width: 32) { audioPlayer.play() }
                        WinampButton(icon: "⏸", width: 32) { audioPlayer.pause() }
                        WinampButton(icon: "⏹", width: 32) { audioPlayer.stop() }
                        WinampButton(icon: "⏭", width: 32) { playlistManager.next() }
                    }
                    
                    // Eject/Open button
                    WinampButton(icon: "⏏", width: 32) { playlistManager.showFilePicker() }
                    
                    Spacer()
                    
                    // Shuffle and Repeat buttons
                    HStack(spacing: 2) {
                        WinampButton(icon: "🔀", width: 60) { 
                            // Shuffle toggle
                        }
                        WinampButton(icon: "🔁", width: 32) { 
                            // Repeat toggle
                        }
                    }
                    
                    // Preferences/Settings button (orange)
                    Button(action: {}) {
                        Image(systemName: "gear.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.2))
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(WinampColors.mainBg)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if let window = NSApplication.shared.windows.first {
                            let currentLocation = NSEvent.mouseLocation
                            let newOrigin = CGPoint(
                                x: currentLocation.x - value.startLocation.x,
                                y: currentLocation.y + value.startLocation.y
                            )
                            window.setFrameOrigin(newOrigin)
                        }
                    }
            )
            .onTapGesture(count: 2) {
                isShadeMode = true
            }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
        }
        .frame(width: 450, height: 200)
        .background(WinampColors.mainBgDark)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Classic Title Bar (Modern Winamp Style)
struct ClassicTitleBar: View {
    @Binding var isShadeMode: Bool
    @State private var isDragging = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Left decorative element
            Image(systemName: "waveform")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.3))
                .frame(width: 20)
            
            // Decorative lines
            Rectangle()
                .fill(LinearGradient(
                    colors: [.white.opacity(0.5), .white.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(width: 50, height: 1)
            
            Spacer().frame(width: 10)
            
            // Title text
            Text("WINAMP")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .tracking(2)
            
            Spacer()
            
            // Decorative lines
            Rectangle()
                .fill(LinearGradient(
                    colors: [.white.opacity(0.1), .white.opacity(0.5)],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(width: 50, height: 1)
            
            // Modern window controls (matching the image style)
            HStack(spacing: 2) {
                ModernWindowButton(icon: "○", tooltip: "Minimize", action: .minimize, isShadeMode: $isShadeMode)
                ModernWindowButton(icon: "▼", tooltip: "Shade", action: .shade, isShadeMode: $isShadeMode)
                ModernWindowButton(icon: "✕", tooltip: "Close", action: .close, isShadeMode: $isShadeMode)
            }
            .padding(.trailing, 4)
        }
        .padding(.horizontal, 8)
        .frame(height: 14)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.2, blue: 0.35),
                    Color(red: 0.1, green: 0.15, blue: 0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    if let window = NSApplication.shared.windows.first {
                        let currentLocation = NSEvent.mouseLocation
                        let newOrigin = CGPoint(
                            x: currentLocation.x - value.startLocation.x,
                            y: currentLocation.y + value.startLocation.y
                        )
                        window.setFrameOrigin(newOrigin)
                    }
                }
        )
    }
}

struct ModernWindowButton: View {
    let icon: String
    let tooltip: String
    let action: WindowControlAction
    @Binding var isShadeMode: Bool
    @State private var isHovered = false
    
    var body: some View {
        Button(action: performAction) {
            Text(icon)
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(isHovered ? .white : Color(red: 0.7, green: 0.7, blue: 0.7))
                .frame(width: 14, height: 12)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isHovered ? Color.white.opacity(0.1) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    func performAction() {
        guard let window = NSApplication.shared.windows.first else { return }
        
        switch action {
        case .minimize:
            window.miniaturize(nil)
        case .shade:
            isShadeMode.toggle()
        case .close:
            window.close()
        }
    }
}

enum WindowControlAction {
    case minimize
    case shade
    case close
}

// Shade mode view - compact view with just spectrum, time, and song name
struct ShadeView: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    @EnvironmentObject var playlistManager: PlaylistManager
    @Binding var isShadeMode: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar (draggable)
            ClassicTitleBar(isShadeMode: $isShadeMode)
            
            // Compact shade content with 3D effects
            HStack(spacing: 6) {
                // Mini spectrum with 3D inset
                ClassicVisualizerView()
                    .frame(width: 50, height: 20)
                    .background(Color.black)
                    .overlay(
                        // Inner shadow effect for depth
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.black.opacity(0.8), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .cornerRadius(3)
                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                // Playback control buttons
                HStack(spacing: 2) {
                    // Previous button
                    ShadeButton(icon: "⏮") {
                        playlistManager.previous()
                    }
                    
                    // Play/Pause button
                    ShadeButton(icon: audioPlayer.isPlaying ? "⏸" : "▶") {
                        audioPlayer.togglePlayPause()
                    }
                    
                    // Next button
                    ShadeButton(icon: "⏭") {
                        playlistManager.next()
                    }
                }
                
                // Time display with 3D inset
                Text(formatTime(audioPlayer.currentTime))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(WinampColors.displayText)
                    .shadow(color: WinampColors.displayText.opacity(0.5), radius: 2, x: 0, y: 0)
                    .frame(width: 50, height: 20)
                    .background(
                        ZStack {
                            Color.black
                            // Inner shadow effect
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.black.opacity(0.8), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        }
                    )
                    .cornerRadius(3)
                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                // Song title with 3D inset
                Text(playlistManager.currentTrack?.title ?? "No Track")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(WinampColors.displayText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(
                        ZStack {
                            Color(red: 0.1, green: 0.12, blue: 0.18)
                            // Inner shadow effect
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.black.opacity(0.7), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        }
                    )
                    .cornerRadius(3)
                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                // Main background with subtle gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.18, green: 0.20, blue: 0.26),
                        Color(red: 0.15, green: 0.17, blue: 0.22)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if let window = NSApplication.shared.windows.first {
                            let currentLocation = NSEvent.mouseLocation
                            let newOrigin = CGPoint(
                                x: currentLocation.x - value.startLocation.x,
                                y: currentLocation.y + value.startLocation.y
                            )
                            window.setFrameOrigin(newOrigin)
                        }
                    }
            )
            .onTapGesture(count: 2) {
                isShadeMode = false
            }
        }
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// Compact button for shade mode with 3D effect
struct ShadeButton: View {
    let icon: String
    let action: () -> Void
    @State private var isPressed = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            isPressed = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }) {
            Text(icon)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.6), radius: 1, x: 0, y: 1)
                .frame(width: 22, height: 18)
                .background(
                    ZStack {
                        // Base button color with gradient
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: isPressed ?
                                        [Color(red: 0.15, green: 0.17, blue: 0.22), Color(red: 0.18, green: 0.20, blue: 0.26)] :
                                        isHovered ?
                                        [Color(red: 0.30, green: 0.34, blue: 0.42), Color(red: 0.24, green: 0.27, blue: 0.34)] :
                                        [Color(red: 0.26, green: 0.30, blue: 0.38), Color(red: 0.20, green: 0.23, blue: 0.30)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // 3D bevel effect
                        if !isPressed {
                            // Top-left highlight (raised)
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.35), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                            
                            // Bottom-right shadow
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.clear, Color.black.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        } else {
                            // Inverted bevel when pressed (inset)
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.black.opacity(0.7), Color.white.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        }
                    }
                )
                .overlay(
                    // Outer border
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(Color.black.opacity(0.7), lineWidth: 1)
                )
                .shadow(color: isPressed ? Color.clear : Color.black.opacity(0.4), radius: 2, x: 0, y: isPressed ? 0 : 1)
                .offset(y: isPressed ? 1 : 0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// Removed duplicate WindowControlButton - using ModernWindowButton instead

struct WindowButton: View {
    let icon: String
    let size: CGFloat
    @State private var isPressed = false
    
    var body: some View {
        Text(icon)
            .font(.system(size: size, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 12, height: 12)
            .background(isPressed ? WinampColors.buttonPressed : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
    }
}

// MARK: - LED Display
struct LEDDisplayView: View {
    @EnvironmentObject var playlistManager: PlaylistManager
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                if let track = playlistManager.currentTrack {
                    Text(track.title.uppercased())
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundColor(WinampColors.displayText)
                        .lineLimit(1)
                        .offset(x: scrollOffset)
                        .padding(.leading, 4)
                        .padding(.vertical, 4)
                } else {
                    Text("WINAMP")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(WinampColors.displayInactive)
                        .padding(.leading, 4)
                        .padding(.vertical, 4)
                }
            }
        }
        .clipped()
    }
}

struct BitrateDisplayView: View {
    var body: some View {
        HStack(spacing: 2) {
            Text("128")
                .font(.system(size: 6, design: .monospaced))
                .foregroundColor(WinampColors.displayText)
            
            Text("•")
                .font(.system(size: 5))
                .foregroundColor(WinampColors.displayInactive)
            
            Text("44")
                .font(.system(size: 6, design: .monospaced))
                .foregroundColor(WinampColors.displayText)
            
            Spacer()
            
            Text("stereo")
                .font(.system(size: 6, design: .monospaced))
                .foregroundColor(WinampColors.displayText)
        }
        .padding(.horizontal, 2)
    }
}

struct LEDTimeDisplay: View {
    let time: TimeInterval
    
    var body: some View {
        Text(formatTime(time))
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(WinampColors.displayText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(WinampColors.displayBg)
            .overlay(
                Rectangle()
                    .strokeBorder(WinampColors.borderDark, lineWidth: 1)
            )
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Classic Control Buttons
struct ClassicControlButtons: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    @EnvironmentObject var playlistManager: PlaylistManager
    @Binding var showPlaylist: Bool
    @Binding var showEqualizer: Bool
    
    var body: some View {
        HStack(spacing: 2) {
            // Previous
            WinampButton(icon: "⏮", width: 23) {
                playlistManager.previous()
            }
            
            // Play
            WinampButton(icon: "▶", width: 23) {
                audioPlayer.play()
            }
            
            // Pause
            WinampButton(icon: "⏸", width: 23) {
                audioPlayer.pause()
            }
            
            // Stop
            WinampButton(icon: "⏹", width: 23) {
                audioPlayer.stop()
            }
            
            // Next
            WinampButton(icon: "⏭", width: 23) {
                playlistManager.next()
            }
            
            // Eject (open file)
            WinampButton(icon: "⏏", width: 23) {
                playlistManager.showFilePicker()
            }
            
            Spacer()
            
            // Equalizer toggle
            WinampToggle(text: "EQ", isOn: $showEqualizer, width: 23)
            
            // Playlist toggle
            WinampToggle(text: "PL", isOn: $showPlaylist, width: 23)
        }
    }
}

struct WinampButton: View {
    let icon: String
    let width: CGFloat
    let action: () -> Void
    @State private var isPressed = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            isPressed = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }) {
            Text(icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.6), radius: 1, x: 0, y: 1)
                .frame(width: width, height: 18)
                .background(
                    ZStack {
                        // Base button color with gradient
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: isPressed ?
                                        [Color(red: 0.18, green: 0.20, blue: 0.26), Color(red: 0.22, green: 0.25, blue: 0.32)] :
                                        isHovered ?
                                        [Color(red: 0.32, green: 0.36, blue: 0.44), Color(red: 0.26, green: 0.29, blue: 0.36)] :
                                        [Color(red: 0.28, green: 0.32, blue: 0.40), Color(red: 0.22, green: 0.25, blue: 0.32)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // 3D bevel effect
                        if !isPressed {
                            // Top-left highlight (raised)
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.4), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                            
                            // Bottom-right shadow
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.clear, Color.black.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        } else {
                            // Inverted bevel when pressed (inset)
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.black.opacity(0.7), Color.white.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        }
                    }
                )
                .overlay(
                    // Outer border
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(Color.black.opacity(0.7), lineWidth: 1)
                )
                .shadow(color: isPressed ? Color.clear : Color.black.opacity(0.4), radius: 2, x: 0, y: isPressed ? 0 : 2)
                .offset(y: isPressed ? 1 : 0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct WinampToggle: View {
    let text: String
    @Binding var isOn: Bool
    let width: CGFloat
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            isOn.toggle()
        }) {
            Text(text)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(isOn ? WinampColors.displayText : .white.opacity(0.85))
                .frame(width: width, height: 18)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isOn ? WinampColors.buttonPressed : 
                              isHovered ? WinampColors.buttonHover : WinampColors.buttonFace)
                        .shadow(color: .black.opacity(0.3), radius: isOn ? 0 : 1, x: 0, y: isOn ? 0 : 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(isOn ? WinampColors.displayText.opacity(0.5) : WinampColors.borderDark, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Mono Position Slider
struct MonoSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    @State private var isDragging = false
    @State private var dragValue: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(WinampColors.mainBgDark)
                    .overlay(
                        // 3D inset effect
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(WinampColors.borderDark)
                                .frame(height: 1)
                            Spacer()
                        }
                    )
                
                // Position indicator
                let currentValue = isDragging ? dragValue : value
                let progress = (currentValue - range.lowerBound) / (range.upperBound - range.lowerBound)
                let xPosition = CGFloat(progress) * (geometry.size.width - 4)
                
                Rectangle()
                    .fill(WinampColors.displayText)
                    .frame(width: 4, height: 8)
                    .offset(x: max(0, min(xPosition, geometry.size.width - 4)))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let progress = max(0, min(1, gesture.location.x / geometry.size.width))
                        dragValue = range.lowerBound + (progress * (range.upperBound - range.lowerBound))
                    }
                    .onEnded { _ in
                        value = dragValue
                        isDragging = false
                    }
            )
        }
    }
}

// MARK: - Clutterbar (Volume/Balance)
struct ClutterbarView: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    @State private var balance: Float = 0.5
    
    var body: some View {
        HStack(spacing: 6) {
            // Volume slider
            VStack(spacing: 0) {
                Text("Volume")
                    .font(.system(size: 5))
                    .foregroundColor(.white.opacity(0.7))
                
                ClutterbarSlider(
                    value: Binding(
                        get: { audioPlayer.volume },
                        set: { audioPlayer.setVolume($0) }
                    ),
                    width: 68
                )
            }
            
            Spacer()
            
            // Balance slider
            VStack(spacing: 0) {
                Text("Balance")
                    .font(.system(size: 5))
                    .foregroundColor(.white.opacity(0.7))
                
                ClutterbarSlider(
                    value: $balance,
                    width: 38
                )
            }
        }
    }
}

struct ClutterbarSlider: View {
    @Binding var value: Float
    let width: CGFloat
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(WinampColors.mainBgDark)
                    .frame(height: 4)
                
                // Thumb
                let xPosition = CGFloat(value) * (width - 3)
                
                Rectangle()
                    .fill(WinampColors.displayText)
                    .frame(width: 3, height: 6)
                    .offset(x: max(0, min(xPosition, width - 3)))
            }
            .frame(width: width, height: 6)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let progress = max(0, min(1, gesture.location.x / width))
                        value = Float(progress)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .frame(width: width, height: 6)
    }
}

struct TimeDisplayView: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    
    var body: some View {
        HStack(spacing: 4) {
            Text(formatTime(audioPlayer.currentTime))
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(WinampColors.displayText)
                .frame(width: 50, alignment: .trailing)
            
            Text("/")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(WinampColors.displayText.opacity(0.5))
            
            Text(formatTime(audioPlayer.duration))
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(WinampColors.displayText.opacity(0.7))
                .frame(width: 50, alignment: .leading)
        }
        .padding(6)
        .background(WinampColors.displayBg)
        .cornerRadius(2)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct VolumeControlView: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 10))
                .foregroundColor(WinampColors.displayText)
            
            Slider(value: Binding(
                get: { audioPlayer.volume },
                set: { audioPlayer.setVolume($0) }
            ), in: 0...1)
            .accentColor(WinampColors.displayText)
            .frame(width: 60)
            
            Text("\(Int(audioPlayer.volume * 100))%")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(WinampColors.displayText)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct PositionSliderView: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    @State private var isDragging = false
    @State private var dragValue: Double = 0
    
    var body: some View {
        Slider(
            value: isDragging ? $dragValue : Binding(
                get: { audioPlayer.currentTime },
                set: { _ in }
            ),
            in: 0...max(audioPlayer.duration, 1),
            onEditingChanged: { dragging in
                isDragging = dragging
                if !dragging {
                    audioPlayer.seek(to: dragValue)
                }
            }
        )
        .accentColor(WinampColors.titleBarHighlight)
    }
}

struct PlaybackControlsView: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    @EnvironmentObject var playlistManager: PlaylistManager
    
    var body: some View {
        HStack(spacing: 8) {
            ControlButton(icon: "backward.end.fill") {
                playlistManager.previous()
            }
            
            ControlButton(icon: audioPlayer.isPlaying ? "pause.fill" : "play.fill") {
                audioPlayer.togglePlayPause()
            }
            
            ControlButton(icon: "stop.fill") {
                audioPlayer.stop()
            }
            
            ControlButton(icon: "forward.end.fill") {
                playlistManager.next()
            }
        }
    }
}

struct ControlButton: View {
    let icon: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isPressed ? WinampColors.buttonPressed : WinampColors.buttonFace)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct ToggleButton: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: { isOn.toggle() }) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 30, height: 20)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isOn ? WinampColors.titleBarHighlight : WinampColors.buttonFace)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// Modern slider with 3D inset effect and pause icon
struct ModernSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Inset background track with 3D effect
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.6))
                    .overlay(
                        // Inner shadow effect (top-left dark, bottom-right light)
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.black.opacity(0.8), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                
                // Progress fill with raised 3D effect
                RoundedRectangle(cornerRadius: 9)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(1.0),
                                color.opacity(0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: max(18, geometry.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.4), Color.black.opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .padding(2)
                
                // Pause icon in center
                Text("⏸")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.7))
                    .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                    .frame(maxWidth: .infinity)
            }
            .overlay(
                // Outer border
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.black.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        isDragging = true
                        let percent = Double(drag.location.x / geometry.size.width)
                        let newValue = range.lowerBound + (range.upperBound - range.lowerBound) * percent
                        value = min(max(newValue, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
    }
}

// Modern toggle button with 3D bevel effect (EQ/PL style)
struct ModernToggleButton: View {
    let text: String
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: { isOn.toggle() }) {
            Text(text)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(isOn ? .black : WinampColors.displayText)
                .frame(width: 24, height: 20)
                .background(
                    ZStack {
                        if isOn {
                            // Raised button when active
                            RoundedRectangle(cornerRadius: 3)
                                .fill(WinampColors.displayText)
                            
                            // Top highlight
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.5), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        } else {
                            // Inset button when inactive
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(red: 0.15, green: 0.17, blue: 0.22))
                            
                            // Inner shadow effect
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.black.opacity(0.6), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(Color.black.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: isOn ? Color.black.opacity(0.3) : Color.clear, radius: 1, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

