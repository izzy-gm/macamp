import Foundation
import AVFoundation
import Combine

class AudioPlayer: NSObject, ObservableObject {
    static let shared = AudioPlayer()
    
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 0.75
    @Published var currentTrack: Track?
    @Published var spectrumData: [Float] = Array(repeating: 0, count: 20)
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFile: AVAudioFile?
    private var eqNode: AVAudioUnitEQ?
    private var timer: Timer?
    private var shouldAutoAdvance = true
    
    override init() {
        super.init()
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        // Setup 10-band equalizer
        eqNode = AVAudioUnitEQ(numberOfBands: 10)
        
        // Configure EQ bands (Winamp-style frequencies)
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
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func loadTrack(_ track: Track) {
        print("Loading track: \(track.title)")
        
        // Prevent auto-advance when manually loading a track
        shouldAutoAdvance = false
        
        // Stop current playback and reset
        playerNode?.stop()
        playerNode?.reset()
        stopTimer()
        isPlaying = false
        currentTime = 0
        
        currentTrack = track
        
        guard let url = track.url else { 
            print("Track URL is nil")
            return 
        }
        
        do {
            audioFile = try AVAudioFile(forReading: url)
            duration = Double(audioFile!.length) / audioFile!.fileFormat.sampleRate
            print("Track loaded successfully, duration: \(duration)")
        } catch {
            print("Failed to load audio file: \(error)")
            audioFile = nil
        }
    }
    
    func play() {
        guard let player = playerNode,
              let file = audioFile,
              let engine = audioEngine else { 
            print("Play failed: missing player, file, or engine")
            return 
        }
        
        // Restart engine if needed
        if !engine.isRunning {
            do {
                try engine.start()
                print("Engine started")
            } catch {
                print("Failed to start engine: \(error)")
                return
            }
        }
        
        // If already playing, just resume
        if isPlaying {
            print("Already playing")
            return
        }
        
        // Stop and reset player node to clear any scheduled buffers
        player.stop()
        player.reset()
        
        // Re-enable auto-advance
        shouldAutoAdvance = true
        
        // Schedule the entire file
        player.scheduleFile(file, at: nil) { [weak self] in
            DispatchQueue.main.async {
                print("Track completed")
                self?.handleTrackCompletion()
            }
        }
        
        player.volume = volume
        player.play()
        isPlaying = true
        startTimer()
        print("Playback started")
    }
    
    func pause() {
        guard isPlaying else { return }
        print("Pausing playback")
        playerNode?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func resume() {
        guard let player = playerNode, !isPlaying else { return }
        print("Resuming playback")
        player.play()
        isPlaying = true
        startTimer()
    }
    
    func stop() {
        print("Stopping playback")
        playerNode?.stop()
        isPlaying = false
        currentTime = 0
        stopTimer()
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
        stop()
        
        let sampleRate = file.fileFormat.sampleRate
        let startFrame = AVAudioFramePosition(time * sampleRate)
        
        guard startFrame < file.length else { return }
        
        player.scheduleSegment(
            file,
            startingFrame: startFrame,
            frameCount: AVAudioFrameCount(file.length - startFrame),
            at: nil
        ) { [weak self] in
            DispatchQueue.main.async {
                self?.handleTrackCompletion()
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
        currentTime = Double(playerTime.sampleTime) / sampleRate
    }
    
    private func updateSpectrum() {
        // Simulate spectrum data for visualization
        // In a production app, you'd use AVAudioEngine tap to get real FFT data
        spectrumData = (0..<20).map { _ in
            isPlaying ? Float.random(in: 0...1) : 0
        }
    }
    
    private func handleTrackCompletion() {
        isPlaying = false
        stopTimer()
        // Only auto-advance if we didn't manually switch tracks
        if shouldAutoAdvance {
            PlaylistManager.shared.next()
        }
    }
}

