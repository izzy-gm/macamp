import Foundation
import AVFoundation

struct Track: Identifiable, Equatable {
    let id = UUID()
    let url: URL?
    let title: String
    let artist: String
    let duration: TimeInterval
    let fileSize: Int64
    
    init(url: URL) {
        self.url = url
        
        // Extract metadata
        let asset = AVURLAsset(url: url)
        var trackTitle = url.deletingPathExtension().lastPathComponent
        var trackArtist = "Unknown Artist"
        var trackDuration: TimeInterval = 0
        
        // Get common metadata
        for item in asset.commonMetadata {
            if let key = item.commonKey?.rawValue, let value = item.value {
                switch key {
                case "title":
                    if let title = value as? String {
                        trackTitle = title
                    }
                case "artist":
                    if let artist = value as? String {
                        trackArtist = artist
                    }
                default:
                    break
                }
            }
        }
        
        // Get duration
        trackDuration = CMTimeGetSeconds(asset.duration)
        
        // Get file size
        var fileSize: Int64 = 0
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attributes[.size] as? Int64 {
            fileSize = size
        }
        
        self.title = trackTitle
        self.artist = trackArtist
        self.duration = trackDuration.isNaN ? 0 : trackDuration
        self.fileSize = fileSize
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedSize: String {
        let kb = Double(fileSize) / 1024.0
        if kb < 1024 {
            return String(format: "%.0f KB", kb)
        } else {
            let mb = kb / 1024.0
            return String(format: "%.1f MB", mb)
        }
    }
}

