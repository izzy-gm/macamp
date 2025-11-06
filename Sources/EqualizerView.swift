import SwiftUI

struct EqualizerView: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    @State private var bandValues: [Float] = Array(repeating: 0, count: 10)
    @State private var preampValue: Float = 0
    @State private var eqOn = true
    
    let frequencies = ["70", "180", "320", "600", "1K", "3K", "6K", "12K", "14K", "16K"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Classic Winamp EQ header
            HStack(spacing: 3) {
                Image(systemName: "waveform")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 9, height: 9)
                
                Text("Winamp Equalizer")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(.white)
                
                Spacer()
                
                // No window controls - this is a sub-window
            }
            .padding(.horizontal, 5)
            .frame(height: 14)
            .background(
                LinearGradient(
                    colors: [WinampColors.titleBarHighlight, WinampColors.titleBar],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // EQ Content
            VStack(spacing: 4) {
                // ON/AUTO buttons and PRESETS
                HStack {
                    HStack(spacing: 2) {
                        WinampToggle(text: "ON", isOn: $eqOn, width: 25)
                        WinampToggle(text: "AUTO", isOn: .constant(false), width: 32)
                    }
                    
                    Spacer()
                    
                    PlaylistButton(text: "PRESETS") {
                        // Show presets menu
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)
                
                // Sliders section
                HStack(alignment: .center, spacing: 0) {
                    // Preamp slider
                    VStack(spacing: 1) {
                        Text("Preamp")
                            .font(.system(size: 6, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        
                        ClassicEQSlider(
                            value: $preampValue,
                            height: 63
                        )
                    }
                    .frame(width: 28)
                    
                    // Divider
                    Rectangle()
                        .fill(WinampColors.borderDark)
                        .frame(width: 1, height: 70)
                        .padding(.horizontal, 2)
                    
                    // 10 frequency bands
                    HStack(alignment: .center, spacing: 2) {
                        ForEach(0..<10, id: \.self) { index in
                            VStack(spacing: 1) {
                                ClassicEQSlider(
                                    value: Binding(
                                        get: { bandValues[index] },
                                        set: { newValue in
                                            bandValues[index] = newValue
                                            audioPlayer.setEQBand(index, gain: newValue * 12)
                                        }
                                    ),
                                    height: 63
                                )
                                
                                Text(frequencies[index])
                                    .font(.system(size: 5, design: .monospaced))
                                    .foregroundColor(WinampColors.displayText)
                            }
                            .frame(width: 14)
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .background(WinampColors.mainBgDark)
                
                // Reset button
                HStack {
                    Spacer()
                    PlaylistButton(text: "RESET") {
                        resetEqualizer()
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            }
            .background(WinampColors.mainBg)
        }
        .frame(width: 275)
        .background(WinampColors.mainBgDark)
    }
    
    private func resetEqualizer() {
        bandValues = Array(repeating: 0, count: 10)
        preampValue = 0
        for i in 0..<10 {
            audioPlayer.setEQBand(i, gain: 0)
        }
    }
}

// MARK: - Classic EQ Vertical Slider
struct ClassicEQSlider: View {
    @Binding var value: Float  // -1 to +1
    let height: CGFloat
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Track background
                Rectangle()
                    .fill(WinampColors.eqSliderBg)
                    .frame(width: 11, height: height)
                    .overlay(
                        // 3D inset effect
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(WinampColors.borderDark)
                                .frame(height: 1)
                            Spacer()
                            Rectangle()
                                .fill(WinampColors.borderLight.opacity(0.3))
                                .frame(height: 1)
                        }
                    )
                
                // Filled portion
                let fillHeight = (CGFloat(value) + 1) / 2 * height
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                WinampColors.eqSlider,
                                WinampColors.eqSlider.opacity(0.7)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 11, height: max(0, fillHeight))
                
                // Center line indicator
                Rectangle()
                    .fill(WinampColors.displayText)
                    .frame(width: 11, height: 1)
                    .offset(y: -(height / 2))
                
                // Thumb/handle
                let thumbOffset = (CGFloat(value) / 2) * height
                
                RoundedRectangle(cornerRadius: 1)
                    .fill(WinampColors.buttonFace)
                    .frame(width: 13, height: 5)
                    .overlay(
                        Rectangle()
                            .strokeBorder(WinampColors.borderLight, lineWidth: 1)
                    )
                    .offset(y: -(height / 2 + thumbOffset))
            }
            .frame(width: 14, height: height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        // Invert Y coordinate
                        let progress = 1 - (gesture.location.y / height)
                        let clampedProgress = max(0, min(1, progress))
                        value = Float(clampedProgress * 2 - 1)  // Convert to -1...1
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .frame(width: 14, height: height)
    }
}

