import Foundation
import AVFoundation
import Combine
import MediaPlayer
import Accelerate

class AudioPlayer: NSObject, ObservableObject {
    static let shared = AudioPlayer()
    
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 0.75
    @Published var currentTrack: Track?
    @Published var spectrumData: [Float] = Array(repeating: 0, count: 20)
    @Published var currentLyrics: [LyricLine] = []
    @Published var currentLyricText: String?
    @Published var currentBitrate: Int = 0
    @Published var currentSampleRate: Double = 0
    @Published var currentChannels: Int = 0
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFile: AVAudioFile?
    private var eqNode: AVAudioUnitEQ?
    private var timer: Timer?
    private var shouldAutoAdvance = true
    private var seekOffset: TimeInterval = 0  // Tracks position when seeking
    private var scheduleGeneration: Int = 0  // Counter to track which schedule is current
    private let audioQueue = DispatchQueue(label: "com.macamp.audio", qos: .userInteractive)

    // FFT properties for real spectrum analysis
    private var fftSetup: vDSP_DFT_Setup?
    private let fftSize = 2048
    private var fftWindow: [Float] = []
    private var fftRealBuffer: [Float] = []
    private var fftImagBuffer: [Float] = []
    private var fftMagnitudes: [Float] = []
    private var smoothedSpectrum: [Float] = Array(repeating: 0, count: 20)
    
    override init() {
        super.init()
        setupAudioEngine()
        setupRemoteCommands()
    }

    deinit {
        // Remove audio tap
        audioEngine?.mainMixerNode.removeTap(onBus: 0)

        // Destroy FFT setup
        if let fftSetup = fftSetup {
            vDSP_DFT_DestroySetup(fftSetup)
        }
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        // Setup 10-band equalizer
        eqNode = AVAudioUnitEQ(numberOfBands: 10)
        
        // Configure EQ bands (MacAmp-style frequencies)
        let frequencies: [Float] = [60, 170, 310, 600, 1000, 3000, 6000, 12000, 14000, 16000]
        for (index, frequency) in frequencies.enumerated() {
            let band = eqNode!.bands[index]
            band.frequency = frequency
            band.bandwidth = 1.0
            band.bypass = false
            band.filterType = .parametric
            band.gain = 0
        }
        
        guard let engine = audioEngine, let player = playerNode, let eq = eqNode else { return }
        
        engine.attach(player)
        engine.attach(eq)
        
        // Connect nodes: player -> eq -> mainMixer -> output
        engine.connect(player, to: eq, format: nil)
        engine.connect(eq, to: engine.mainMixerNode, format: nil)
        
        do {
            try engine.start()
        } catch {
            // Failed to start audio engine
        }

        // Initialize FFT for spectrum analysis
        setupFFT()
        installAudioTap()
    }

    private func setupFFT() {
        // Create DFT setup for real-to-complex transform
        fftSetup = vDSP_DFT_zrop_CreateSetup(nil, vDSP_Length(fftSize), .FORWARD)

        // Pre-allocate Hann window to reduce spectral leakage
        fftWindow = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&fftWindow, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))

        // Pre-allocate FFT buffers
        fftRealBuffer = [Float](repeating: 0, count: fftSize)
        fftImagBuffer = [Float](repeating: 0, count: fftSize)
        fftMagnitudes = [Float](repeating: 0, count: fftSize / 2)
    }

    private func installAudioTap() {
        guard let engine = audioEngine else { return }

        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        let bufferSize = AVAudioFrameCount(fftSize)

        engine.mainMixerNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let fftSetup = fftSetup,
              let channelData = buffer.floatChannelData else { return }

        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }

        // Get samples from first channel (mono or left channel of stereo)
        let samples = channelData[0]

        // Copy samples and apply Hann window
        var windowedSamples = [Float](repeating: 0, count: fftSize)
        let sampleCount = min(frameLength, fftSize)

        for i in 0..<sampleCount {
            windowedSamples[i] = samples[i] * fftWindow[i]
        }

        // Prepare split complex buffers for FFT
        var realInput = [Float](repeating: 0, count: fftSize)
        var imagInput = [Float](repeating: 0, count: fftSize)
        var realOutput = [Float](repeating: 0, count: fftSize)
        var imagOutput = [Float](repeating: 0, count: fftSize)

        // Copy windowed samples to real input (imaginary stays zero)
        for i in 0..<fftSize {
            realInput[i] = windowedSamples[i]
        }

        // Perform DFT
        vDSP_DFT_Execute(fftSetup, &realInput, &imagInput, &realOutput, &imagOutput)

        // Calculate magnitudes for first half (Nyquist)
        let halfSize = fftSize / 2
        var magnitudes = [Float](repeating: 0, count: halfSize)

        // Scale factor: normalize by FFT size to get proper amplitude
        let scaleFactor = 2.0 / Float(fftSize)

        for i in 0..<halfSize {
            let real = realOutput[i]
            let imag = imagOutput[i]
            // Scale magnitude to normalize FFT output
            magnitudes[i] = sqrtf(real * real + imag * imag) * scaleFactor
        }

        // Convert to decibels
        // Reference: 1.0 = 0dB (full scale)
        // Typical range: -60dB (quiet) to 0dB (loud)
        var scaledMagnitudes = [Float](repeating: 0, count: halfSize)

        for i in 0..<halfSize {
            // Add small epsilon to avoid log(0)
            let mag = max(magnitudes[i], 1e-10)
            // Convert to dB: 20 * log10(magnitude)
            scaledMagnitudes[i] = 20.0 * log10f(mag)
        }

        // Bin into 20 logarithmic frequency bands
        let bands = binToLogarithmicBands(scaledMagnitudes, sampleRate: buffer.format.sampleRate)

        // Apply smoothing and update on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Smooth the spectrum for visual appeal (attack/decay)
            let attackRate: Float = 0.7
            let decayRate: Float = 0.3

            for i in 0..<20 {
                if bands[i] > self.smoothedSpectrum[i] {
                    self.smoothedSpectrum[i] = self.smoothedSpectrum[i] * (1 - attackRate) + bands[i] * attackRate
                } else {
                    self.smoothedSpectrum[i] = self.smoothedSpectrum[i] * (1 - decayRate) + bands[i] * decayRate
                }
            }

            self.spectrumData = self.smoothedSpectrum
        }
    }

    private func binToLogarithmicBands(_ magnitudes: [Float], sampleRate: Double) -> [Float] {
        let bandCount = 20
        var bands = [Float](repeating: 0, count: bandCount)

        let nyquist = sampleRate / 2.0
        let binCount = magnitudes.count
        let minFreq: Double = 20.0
        let maxFreq: Double = min(20000.0, nyquist)

        // Calculate logarithmic frequency boundaries for 20 bands
        let logMin = log10(minFreq)
        let logMax = log10(maxFreq)
        let logStep = (logMax - logMin) / Double(bandCount)

        for band in 0..<bandCount {
            let freqLow = pow(10, logMin + Double(band) * logStep)
            let freqHigh = pow(10, logMin + Double(band + 1) * logStep)

            // Convert frequencies to FFT bin indices
            let binLow = Int((freqLow / nyquist) * Double(binCount))
            let binHigh = Int((freqHigh / nyquist) * Double(binCount))

            let startBin = max(0, min(binLow, binCount - 1))
            let endBin = max(startBin, min(binHigh, binCount - 1))

            // Average the magnitudes in this frequency range
            var sum: Float = 0
            var count = 0

            for bin in startBin...endBin {
                sum += magnitudes[bin]
                count += 1
            }

            if count > 0 {
                // Convert from dB to 0.0-1.0 range
                // Dynamic range: -50dB (silence) to 0dB (full scale)
                // Narrower range = more sensitive/responsive display
                let avgDb = sum / Float(count)
                let minDb: Float = -50.0
                let maxDb: Float = 0.0
                let normalized = (avgDb - minDb) / (maxDb - minDb)
                bands[band] = max(0, min(1, normalized))
            }
        }

        return bands
    }
    
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            DispatchQueue.main.async {
                if !self.isPlaying {
                    if self.currentTime > 0 && self.audioFile != nil {
                        self.resume()
                    } else {
                        self.play()
                    }
                }
            }
            return .success
        }
        
        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            DispatchQueue.main.async {
                if self.isPlaying {
                    self.pause()
                }
            }
            return .success
        }
        
        // Toggle play/pause command
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            DispatchQueue.main.async {
                self.togglePlayPause()
            }
            return .success
        }
        
        // Next track command
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            DispatchQueue.main.async {
                PlaylistManager.shared.next()
            }
            return .success
        }
        
        // Previous track command
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            DispatchQueue.main.async {
                PlaylistManager.shared.previous()
            }
            return .success
        }
    }
    
    func loadTrack(_ track: Track) {
        
        // Execute on audio queue to ensure serialization
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            // CRITICAL: Stop and cleanup everything first
            DispatchQueue.main.async {
                self.stopTimer()
                self.isPlaying = false
            }
            
            // Small delay to ensure timer is stopped
            Thread.sleep(forTimeInterval: 0.02)
            
            // Completely destroy and recreate the player node to ensure clean state
            if let player = self.playerNode, let engine = self.audioEngine, let _ = self.eqNode {
                engine.disconnectNodeOutput(player)
                engine.detach(player)
                player.stop()
                player.reset()
            }
            
            // Create a fresh player node
            self.playerNode = AVAudioPlayerNode()
            
            // Reattach to engine
            if let player = self.playerNode, let engine = self.audioEngine, let eq = self.eqNode {
                engine.attach(player)
                engine.connect(player, to: eq, format: nil)
            }
            
            // Reset state on main thread
            DispatchQueue.main.async {
                self.currentTime = 0
                self.shouldAutoAdvance = false
                self.audioFile = nil
                self.currentTrack = track
                self.currentLyrics = []
                self.currentLyricText = nil
                // Reset audio info until new file loads
                self.currentBitrate = 0
                self.currentSampleRate = 0
                self.currentChannels = 0
            }
            
            // Load lyrics asynchronously
            if let url = track.url {
                LyricsParser.loadLyrics(for: url, artist: track.artist, title: track.title, duration: track.duration) { [weak self] lyrics in
                    DispatchQueue.main.async {
                        self?.currentLyrics = lyrics ?? []
                    }
                }
            }
            
            guard let url = track.url else { 
                return 
            }
            
            do {
                let newFile = try AVAudioFile(forReading: url)
                let newDuration = Double(newFile.length) / newFile.fileFormat.sampleRate
                let format = newFile.fileFormat

                // Extract audio info
                let sampleRate = format.sampleRate
                let channels = Int(format.channelCount)

                // Calculate bitrate from file size and duration (most reliable method)
                var bitrate = 0
                if newDuration > 0 {
                    if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                       let fileSize = attrs[.size] as? UInt64 {
                        // bitrate = (file size in bits) / (duration in seconds) / 1000 for kbps
                        let rawBitrate = Int((Double(fileSize) * 8.0) / newDuration / 1000.0)
                        bitrate = self.roundToStandardBitrate(rawBitrate)
                    }
                }

                DispatchQueue.main.async {
                    self.audioFile = newFile
                    self.duration = newDuration
                    self.currentSampleRate = sampleRate
                    self.currentChannels = channels
                    self.currentBitrate = bitrate
                    self.updateNowPlayingInfo()
                }
            } catch {
                DispatchQueue.main.async {
                    self.audioFile = nil
                    self.currentBitrate = 0
                    self.currentSampleRate = 0
                    self.currentChannels = 0
                }
            }
        }
    }
    
    private func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func play() {
        // Execute on audio queue to ensure serialization
        audioQueue.async { [weak self] in
            guard let self = self else { return }

            guard let player = self.playerNode,
                  let file = self.audioFile,
                  let engine = self.audioEngine else {
                return
            }

            // If already playing, don't schedule again
            if self.isPlaying {
                return
            }

            // Restart engine if needed
            if !engine.isRunning {
                do {
                    try engine.start()
                } catch {
                    return
                }
            }

            // Increment generation to invalidate any pending completion handlers
            self.scheduleGeneration += 1
            let currentGeneration = self.scheduleGeneration

            // CRITICAL: Ensure player is completely stopped
            player.stop()
            player.reset()

            // Re-enable auto-advance
            self.shouldAutoAdvance = true

            let sampleRate = file.fileFormat.sampleRate

            // Check if we should resume from a seek position
            if self.seekOffset > 0 {
                // Schedule from the seek position
                let startFrame = AVAudioFramePosition(self.seekOffset * sampleRate)
                let remainingFrames = file.length - startFrame

                if startFrame < file.length && remainingFrames > 0 {
                    player.scheduleSegment(
                        file,
                        startingFrame: startFrame,
                        frameCount: AVAudioFrameCount(remainingFrames),
                        at: nil
                    ) { [weak self] in
                        DispatchQueue.main.async {
                            guard let self = self, currentGeneration == self.scheduleGeneration else { return }
                            self.handleTrackCompletion()
                        }
                    }
                }
            } else {
                // Reset seek offset and play from start
                self.seekOffset = 0

                // Schedule the entire file
                player.scheduleFile(file, at: nil) { [weak self] in
                    DispatchQueue.main.async {
                        guard let self = self, currentGeneration == self.scheduleGeneration else { return }
                        self.handleTrackCompletion()
                    }
                }
            }

            player.volume = self.volume
            player.play()

            DispatchQueue.main.async {
                self.isPlaying = true
                self.startTimer()
                self.updateNowPlayingInfo()
            }
        }
    }
    
    func pause() {
        guard isPlaying else { return }
        playerNode?.pause()
        isPlaying = false
        stopTimer()
        updateNowPlayingInfo()
    }
    
    func resume() {
        guard !isPlaying else { return }

        // If we have a seek offset, use play() which properly schedules from that position
        // This handles the case where user seeked while paused
        if seekOffset > 0 {
            play()
            return
        }

        guard let player = playerNode else { return }
        player.play()
        isPlaying = true
        startTimer()
        updateNowPlayingInfo()
    }
    
    func stop() {
        shouldAutoAdvance = false
        playerNode?.stop()
        isPlaying = false
        currentTime = 0
        seekOffset = 0  // Reset seek offset
        stopTimer()
        updateNowPlayingInfo()

        // Reset spectrum
        smoothedSpectrum = Array(repeating: 0, count: 20)
        spectrumData = smoothedSpectrum
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            // If we have a current time, resume; otherwise start from beginning
            if currentTime > 0 && audioFile != nil {
                resume()
            } else {
                play()
            }
        }
    }
    
    func seek(to time: TimeInterval) {
        guard let file = audioFile,
              let player = playerNode else { return }

        let wasPlaying = isPlaying

        // Increment generation to invalidate any pending completion handlers
        scheduleGeneration += 1
        let currentGeneration = scheduleGeneration

        // Stop playback but preserve shouldAutoAdvance state
        player.stop()
        isPlaying = false
        stopTimer()

        let sampleRate = file.fileFormat.sampleRate
        let startFrame = AVAudioFramePosition(time * sampleRate)

        guard startFrame < file.length else { return }

        // Store the seek offset - player time will be relative to this
        seekOffset = time

        // Re-enable auto-advance for when track completes
        shouldAutoAdvance = true

        player.scheduleSegment(
            file,
            startingFrame: startFrame,
            frameCount: AVAudioFrameCount(file.length - startFrame),
            at: nil
        ) { [weak self] in
            DispatchQueue.main.async {
                // Only handle completion if this is still the current schedule
                guard let self = self, currentGeneration == self.scheduleGeneration else { return }
                self.handleTrackCompletion()
            }
        }

        currentTime = time

        if wasPlaying {
            player.play()
            isPlaying = true
            startTimer()
        }
    }
    
    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        playerNode?.volume = volume
    }
    
    func setEQBand(_ band: Int, gain: Float) {
        guard let eq = eqNode, band < eq.bands.count else { return }
        eq.bands[band].gain = gain
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateCurrentTime()
            self?.updateSpectrum()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateCurrentTime() {
        guard let player = playerNode,
              let lastRenderTime = player.lastRenderTime,
              let playerTime = player.playerTime(forNodeTime: lastRenderTime),
              let file = audioFile else { return }

        let sampleRate = file.fileFormat.sampleRate
        // playerTime.sampleTime is relative to when player started
        // Add seekOffset to get absolute position in file
        let relativeTime = Double(playerTime.sampleTime) / sampleRate
        currentTime = seekOffset + relativeTime

        // Clamp to duration to avoid overshooting
        if currentTime > duration {
            currentTime = duration
        }

        // Update current lyric based on playback time
        updateCurrentLyric()
    }
    
    private func updateCurrentLyric() {
        guard !currentLyrics.isEmpty else {
            if currentLyricText != nil {
                currentLyricText = nil
            }
            return
        }
        
        let newLyric = LyricsParser.getCurrentLyric(lyrics: currentLyrics, currentTime: currentTime)
        if newLyric != currentLyricText {
            currentLyricText = newLyric
        }
    }
    
    private func updateSpectrum() {
        // Spectrum is now updated via audio tap callback (processAudioBuffer)
        // This method handles decay when not playing
        if !isPlaying {
            // Decay spectrum to zero when stopped/paused
            let decayRate: Float = 0.15
            var hasActivity = false

            for i in 0..<20 {
                if smoothedSpectrum[i] > 0.01 {
                    smoothedSpectrum[i] *= (1 - decayRate)
                    hasActivity = true
                } else {
                    smoothedSpectrum[i] = 0
                }
            }

            if hasActivity {
                spectrumData = smoothedSpectrum
            }
        }
    }
    
    private func handleTrackCompletion() {
        // Set currentTime to duration so progress bar reaches the end
        currentTime = duration
        seekOffset = 0

        isPlaying = false
        stopTimer()

        // Only auto-advance if we didn't manually switch tracks
        if shouldAutoAdvance {
            PlaylistManager.shared.next()
        }
    }

    /// Rounds raw bitrate to nearest standard bitrate for cleaner display
    /// For lossy formats (< 500 kbps), rounds to common values
    /// For lossless formats (>= 500 kbps), shows actual value
    private func roundToStandardBitrate(_ rawBitrate: Int) -> Int {
        // Standard lossy bitrates
        let standardBitrates = [32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320]

        // For high bitrates (lossless), return as-is
        if rawBitrate >= 500 {
            return rawBitrate
        }

        // Find the closest standard bitrate
        var closest = standardBitrates[0]
        var minDiff = abs(rawBitrate - closest)

        for bitrate in standardBitrates {
            let diff = abs(rawBitrate - bitrate)
            if diff < minDiff {
                minDiff = diff
                closest = bitrate
            }
        }

        return closest
    }
}

