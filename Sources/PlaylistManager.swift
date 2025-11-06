import Foundation
import AppKit
import Combine

class PlaylistManager: ObservableObject {
    static let shared = PlaylistManager()
    
    @Published var tracks: [Track] = []
    @Published var currentIndex: Int = -1
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // No automatic playback on index change to prevent feedback loops
    }
    
    var currentTrack: Track? {
        guard currentIndex >= 0 && currentIndex < tracks.count else { return nil }
        return tracks[currentIndex]
    }
    
    func addTrack(_ track: Track) {
        // Ensure this runs on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.tracks.append(track)
            if self.currentIndex == -1 {
                // Delay slightly to ensure UI updates complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.playTrack(at: 0)
                }
            }
        }
    }
    
    func addTracks(_ newTracks: [Track]) {
        // Ensure this runs on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let wasEmpty = self.tracks.isEmpty
            self.tracks.append(contentsOf: newTracks)
            
            // Only auto-play if playlist was empty
            if wasEmpty && !self.tracks.isEmpty {
                // Delay slightly to ensure UI updates complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.playTrack(at: 0)
                }
            }
        }
    }
    
    func removeTrack(at index: Int) {
        guard index >= 0 && index < tracks.count else { return }
        tracks.remove(at: index)
        
        if tracks.isEmpty {
            currentIndex = -1
            AudioPlayer.shared.stop()
        } else if index == currentIndex {
            // Removed current track, play next one (or previous if last)
            currentIndex = min(index, tracks.count - 1)
        } else if index < currentIndex {
            currentIndex -= 1
        }
    }
    
    func clearPlaylist() {
        tracks.removeAll()
        currentIndex = -1
        AudioPlayer.shared.stop()
    }
    
    func playTrack(at index: Int) {
        guard index >= 0 && index < tracks.count else { return }
        currentIndex = index
        let track = tracks[index]
        AudioPlayer.shared.loadTrack(track)
        
        // Wait a moment for track to load before playing (loadTrack is now async)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            AudioPlayer.shared.play()
        }
    }
    
    func next() {
        guard !tracks.isEmpty else { return }
        let nextIndex = (currentIndex + 1) % tracks.count
        playTrack(at: nextIndex)
    }
    
    func previous() {
        guard !tracks.isEmpty else { return }
        let prevIndex = currentIndex > 0 ? currentIndex - 1 : tracks.count - 1
        playTrack(at: prevIndex)
    }
    
    func showFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.mp3, .init(filenameExtension: "flac")].compactMap { $0 }
        
        panel.begin { [weak self] response in
            guard let self = self else { return }
            if response == .OK {
                // Create tracks on background queue to avoid blocking
                DispatchQueue.global(qos: .userInitiated).async {
                    let newTracks = panel.urls.map { Track(url: $0) }
                    // Add tracks on main queue
                    self.addTracks(newTracks)
                }
            }
        }
    }
    
    func showFolderPicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        
        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                self?.addTracksFromFolder(url)
            }
        }
    }
    
    private func addTracksFromFolder(_ folder: URL) {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: folder, includingPropertiesForKeys: nil) else {
            return
        }
        
        var newTracks: [Track] = []
        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            if ext == "mp3" || ext == "flac" {
                newTracks.append(Track(url: fileURL))
            }
        }
        
        addTracks(newTracks)
    }
}

