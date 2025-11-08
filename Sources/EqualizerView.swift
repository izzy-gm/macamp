import SwiftUI

struct EqualizerView: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    @State private var bandValues: [Float] = Array(repeating: 0, count: 10)
    @State private var preampValue: Float = 0
    @State private var eqOn = true
    @State private var autoOn = false
    
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
                        WinampToggle(text: "AUTO", isOn: $autoOn, width: 44)
                    }
                    
                    Spacer()
                    
                    PlaylistButton(text: "PRESETS") {
                        // Show presets menu
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)
                
                // Frequency response graph
                FrequencyResponseGraph(bandValues: bandValues, preampValue: preampValue)
                    .frame(height: 40)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                
                // Sliders section with labels
                HStack(alignment: .top, spacing: 0) {
                    // dB scale labels
                    VStack(spacing: 0) {
                        Text("+12db")
                            .font(.system(size: 6, design: .monospaced))
                            .foregroundColor(WinampColors.displayText)
                        Spacer()
                        Text("+0db")
                            .font(.system(size: 6, design: .monospaced))
                            .foregroundColor(WinampColors.displayText)
                        Spacer()
                        Text("-12db")
                            .font(.system(size: 6, design: .monospaced))
                            .foregroundColor(WinampColors.displayText)
                        Spacer().frame(height: 10) // for frequency labels
                    }
                    .frame(width: 35, height: 110)
                    .padding(.trailing, 4)
                    
                    // Preamp slider
                    VStack(spacing: 2) {
                        Text("PREAMP")
                            .font(.system(size: 6, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                        
                        ClassicEQSlider(
                            value: $preampValue,
                            height: 90
                        )
                        
                        Spacer().frame(height: 10)
                    }
                    .frame(width: 25)
                    
                    Spacer(minLength: 4)
                    
                    // 10 frequency bands
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(0..<10, id: \.self) { index in
                            VStack(spacing: 2) {
                                ClassicEQSlider(
                                    value: Binding(
                                        get: { bandValues[index] },
                                        set: { newValue in
                                            bandValues[index] = newValue
                                            audioPlayer.setEQBand(index, gain: newValue * 12)
                                        }
                                    ),
                                    height: 90
                                )
                                
                                Text(frequencies[index])
                                    .font(.system(size: 6, design: .monospaced))
                                    .foregroundColor(WinampColors.displayText)
                            }
                            .frame(maxWidth: .infinity)
                            
                            if index < 9 {
                                Spacer(minLength: 1)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
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
        .frame(width: 450)
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
            ZStack(alignment: .center) {
                // Track background (narrower)
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 11, height: height)
                    .overlay(
                        // 3D inset effect
                        RoundedRectangle(cornerRadius: 1)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [WinampColors.borderDark, WinampColors.borderLight.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                // Full gradient background (green -> yellow -> red)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.8, blue: 0.0),  // Green at bottom
                                Color(red: 1.0, green: 1.0, blue: 0.0),  // Yellow at center
                                Color(red: 1.0, green: 0.0, blue: 0.0)   // Red at top
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 9, height: height)
                    .mask(
                        // Mask to show only the filled portion
                        GeometryReader { geo in
                            let normalizedValue = (CGFloat(value) + 1) / 2 // 0 to 1
                            let centerY = height / 2
                            
                            if value >= 0 {
                                // Positive value - show from center upward
                                let fillHeight = normalizedValue * centerY
                                Rectangle()
                                    .frame(width: 9, height: fillHeight)
                                    .offset(y: centerY - fillHeight)
                            } else {
                                // Negative value - show from center downward
                                let fillHeight = (1 - normalizedValue) * centerY
                                Rectangle()
                                    .frame(width: 9, height: fillHeight)
                                    .offset(y: centerY)
                            }
                        }
                    )
                
                // Center line indicator (0dB mark)
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 11, height: 1)
                    .offset(y: 0)
                
                // Thumb/handle button with "B"
                let thumbOffset = (CGFloat(value) / 2) * height
                
                ZStack {
                    // Button background with 3D effect
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [WinampColors.buttonLight, WinampColors.buttonFace],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 16, height: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(Color.black.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                    
                    // "B" label
                    Text("B")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Color.black.opacity(0.6))
                }
                .offset(y: -thumbOffset)
            }
            .frame(width: 18, height: height)
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
        .frame(width: 18, height: height)
    }
}

// MARK: - Frequency Response Graph
struct FrequencyResponseGraph: View {
    let bandValues: [Float]
    let preampValue: Float
    
    var body: some View {
        Canvas { context, size in
            // Draw grid lines
            let gridColor = Color.white.opacity(0.1)
            
            // Horizontal grid lines
            for i in 0...4 {
                let y = size.height / 4 * CGFloat(i)
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            }
            
            // Vertical grid lines
            for i in 0...10 {
                let x = size.width / 10 * CGFloat(i)
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            }
            
            // Draw the EQ curve
            var curvePath = Path()
            let midY = size.height / 2
            
            // Start point (preamp influences all)
            let preampOffset = CGFloat(preampValue) * (midY * 0.8)
            
            curvePath.move(to: CGPoint(x: 0, y: midY - preampOffset))
            
            // Draw curve through all band values
            for (index, value) in bandValues.enumerated() {
                let x = size.width / 10 * (CGFloat(index) + 0.5)
                let adjustedValue = value + preampValue
                let y = midY - (CGFloat(adjustedValue) * midY * 0.8)
                
                if index == 0 {
                    curvePath.addLine(to: CGPoint(x: x, y: y))
                } else {
                    // Use quadratic curve for smooth interpolation
                    let prevX = size.width / 10 * (CGFloat(index - 1) + 0.5)
                    let prevValue = bandValues[index - 1] + preampValue
                    let prevY = midY - (CGFloat(prevValue) * midY * 0.8)
                    let controlX = (prevX + x) / 2
                    let controlY = (prevY + y) / 2
                    
                    curvePath.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: controlX, y: controlY))
                }
            }
            
            // End point
            curvePath.addLine(to: CGPoint(x: size.width, y: midY - preampOffset))
            
            // Draw the curve with yellow/green color
            context.stroke(
                curvePath,
                with: .color(WinampColors.displayText),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            )
        }
        .background(Color.black.opacity(0.8))
        .cornerRadius(2)
    }
}
