import SwiftUI

// MARK: - Modern Animated Spectrum Visualizer
struct ClassicVisualizerView: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    @State private var peakHeights: [CGFloat] = Array(repeating: 0, count: 15)
    @State private var peakHoldTimer: [TimeInterval] = Array(repeating: 0, count: 15)
    @State private var smoothedHeights: [CGFloat] = Array(repeating: 0, count: 15)
    
    let columns = 15
    let barWidth: CGFloat = 4.5
    let barSpacing: CGFloat = 0.8
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let totalWidth = size.width
                let barWidth = (totalWidth - CGFloat(columns - 1) * barSpacing) / CGFloat(columns)
                
                for col in 0..<columns {
                    let spectrumIndex = min(col, audioPlayer.spectrumData.count - 1)
                    
                    // Use smoothed height for smoother animation
                    let barHeight = col < smoothedHeights.count ? smoothedHeights[col] : 0
                    
                    let x = CGFloat(col) * (barWidth + barSpacing)
                    let y = size.height - barHeight
                    
                    // Draw main bar - color based on HEIGHT position, not gradient within bar
                    let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
                    
                    // Determine color based on how high the bar reaches in the OVERALL spectrum
                    let heightPercent = barHeight / size.height
                    let barColor: Color
                    
                    if heightPercent < 0.30 {
                        // Bottom 30% - Green only
                        barColor = Color(red: 0.0, green: 1.0, blue: 0.0)
                    } else if heightPercent < 0.50 {
                        // 30-50% - Yellow-green
                        barColor = Color(red: 0.5, green: 1.0, blue: 0.0)
                    } else if heightPercent < 0.70 {
                        // 50-70% - Yellow
                        barColor = Color(red: 1.0, green: 1.0, blue: 0.0)
                    } else if heightPercent < 0.85 {
                        // 70-85% - Orange
                        barColor = Color(red: 1.0, green: 0.5, blue: 0.0)
                    } else {
                        // 85-100% - Red (only the loudest!)
                        barColor = Color(red: 1.0, green: 0.0, blue: 0.0)
                    }
                    
                    context.fill(
                        Path(barRect),
                        with: .color(barColor)
                    )
                    
                    // Draw peak indicator (grey bar at the top)
                    if col < peakHeights.count && peakHeights[col] > 2 {
                        let peakY = size.height - peakHeights[col]
                        let peakRect = CGRect(x: x, y: peakY - 1, width: barWidth, height: 2)
                        
                        // Grey peak indicator
                        context.fill(
                            Path(peakRect),
                            with: .color(Color(red: 0.6, green: 0.6, blue: 0.6))
                        )
                    }
                }
                
                // Draw blue dotted baseline at the bottom (boundary marker)
                let dotSpacing: CGFloat = 3
                let dotSize: CGFloat = 1
                for i in stride(from: 0, to: size.width, by: dotSpacing) {
                    let dotRect = CGRect(x: i, y: size.height - 1, width: dotSize, height: dotSize)
                    context.fill(
                        Path(ellipseIn: dotRect),
                        with: .color(Color(red: 0.2, green: 0.4, blue: 0.8))
                    )
                }
            }
            .background(Color.black)
            .onChange(of: audioPlayer.spectrumData) { newData in
                updatePeaks(newData: newData, height: geometry.size.height)
            }
        }
    }
    
    private func updatePeaks(newData: [Float], height: CGFloat) {
        let currentTime = Date().timeIntervalSince1970
        let smoothingFactor: CGFloat = 0.3 // Lower = smoother/slower (0.3 = 30% new, 70% old)
        let amplitudeScale: CGFloat = 0.95 // Balanced amplitude - mostly green/yellow with occasional orange/red
        
        for i in 0..<min(columns, newData.count) {
            let targetHeight = CGFloat(newData[i]) * height * amplitudeScale
            
            // Smooth the bar height changes (slower rise and fall)
            if i < smoothedHeights.count {
                let currentSmoothed = smoothedHeights[i]
                
                // Rise quickly, fall slowly
                if targetHeight > currentSmoothed {
                    smoothedHeights[i] = currentSmoothed + (targetHeight - currentSmoothed) * 0.5 // Rise at 50% speed
                } else {
                    smoothedHeights[i] = currentSmoothed + (targetHeight - currentSmoothed) * smoothingFactor // Fall at 30% speed
                }
            }
            
            // Update peak if current value is higher
            if targetHeight > peakHeights[i] {
                peakHeights[i] = targetHeight
                peakHoldTimer[i] = currentTime
            }
            // Decay peak slowly after hold time
            else if currentTime - peakHoldTimer[i] > 0.8 {
                peakHeights[i] = max(peakHeights[i] - 1.5, 0) // Slower decay
            }
        }
    }
}

// Keep old one for compatibility but unused
struct SpectrumView: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    
    var body: some View {
        ClassicVisualizerView()
    }
}

struct SpectrumBar: View {
    let value: Float
    let height: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            WinampColors.spectrumDot,
                            WinampColors.spectrumDot.opacity(0.7),
                            WinampColors.spectrumDot.opacity(0.4)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(height: CGFloat(value) * height * 0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

