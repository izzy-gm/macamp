import SwiftUI
import AppKit

@main
struct MacAmpApp: App {
    @StateObject private var audioPlayer = AudioPlayer.shared
    @StateObject private var playlistManager = PlaylistManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("MacAmp", id: "main-window") {
            // Use your real ContentView here - unchanged.
            ContentView()
                .environmentObject(audioPlayer)
                .environmentObject(playlistManager)
                .preferredColorScheme(.dark)
                .background(Color.clear) // ensure SwiftUI root isn't forcing an opaque fill
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 275, height: 116)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Playback") {
                Button("Play/Pause") { audioPlayer.togglePlayPause() }
                    .keyboardShortcut("x", modifiers: [])
                Button("Stop") { audioPlayer.stop() }
                    .keyboardShortcut("v", modifiers: [])
                Button("Previous Track") { playlistManager.previous() }
                    .keyboardShortcut("z", modifiers: [])
                Button("Next Track") { playlistManager.next() }
                    .keyboardShortcut("b", modifiers: [])
            }
            CommandMenu("File") {
                Button("Add Files...") { playlistManager.showFilePicker() }
                    .keyboardShortcut("l", modifiers: [.command])
                Button("Add Folder...") { playlistManager.showFolderPicker() }
                    .keyboardShortcut("l", modifiers: [.command, .shift])
            }
        }
    }
}

// Small, transparent icon view that sits in the titlebar and handles dragging
final class TitlebarIconView: NSView {
    private let imageView: NSImageView

    init(image: NSImage? = nil, size: CGFloat = 14, paddingRight: CGFloat = 6) {
        imageView = NSImageView()
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        let img = image ?? (NSApp.applicationIconImage ?? NSImage(named: NSImage.applicationIconName))
        imageView.image = img
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyDown
        imageView.wantsLayer = true
        imageView.layer?.backgroundColor = NSColor.clear.cgColor

        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: size),
            imageView.heightAnchor.constraint(equalToConstant: size),
            trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: paddingRight)
        ])
    }

    required init?(coder: NSCoder) {
        imageView = NSImageView()
        super.init(coder: coder)
    }

    override var isFlipped: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        guard let win = window else { super.mouseDown(with: event); return }
        if event.clickCount == 2 {
            win.performMiniaturize(nil)
            return
        }
        win.performDrag(with: event)
    }

    override func hitTest(_ point: NSPoint) -> NSView? { self }
}

final class TitlebarIconAccessory: NSTitlebarAccessoryViewController {
    init(icon: NSImage? = nil, iconSize: CGFloat = 14, paddingRight: CGFloat = 6) {
        super.init(nibName: nil, bundle: nil)
        let v = TitlebarIconView(image: icon, size: iconSize, paddingRight: paddingRight)
        self.view = v
        self.layoutAttribute = .left // we'll position it relative to traffic lights after showing the window
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

final class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override init(contentRect: NSRect, styleMask: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: styleMask, backing: backingStoreType, defer: flag)
        // Transparent window
        isOpaque = false
        backgroundColor = .clear
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false // we'll use the tiny icon for drag
        hasShadow = true
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Tracks whether files were opened with the app (via right-click "Open With" or drag to dock)
    static var filesOpenedOnLaunch = false
    /// Tracks if the app has fully launched (to distinguish initial launch from subsequent file opens)
    static var appHasLaunched = false
    /// URLs to open (stored if we need to pass them to existing instance)
    static var pendingURLs: [URL] = []

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Check if another instance of this app is already running
        let dominated = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
        let others = dominated.filter { $0 != NSRunningApplication.current }

        if !others.isEmpty {
            // Another instance is running - activate it and quit this one
            if let existingApp = others.first {
                existingApp.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            }

            // The existing instance will receive the open URLs via Apple Events
            // We just need to quit this instance
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        AppDelegate.handleOpenURLs(urls, isInitialLaunch: !AppDelegate.appHasLaunched)
    }

    /// Prevent app from creating new instances when clicking dock icon
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // Show the main window if it was closed
            sender.windows.first?.makeKeyAndOrderFront(nil)
        }
        return true
    }

    /// Static method to handle file opens - clears playlist and plays (for "Open with" behavior)
    static func handleOpenURLs(_ urls: [URL], isInitialLaunch: Bool = false) {
        // Mark that files were opened with the app (for startup sound logic)
        if isInitialLaunch {
            filesOpenedOnLaunch = true
        }

        // Filter for supported audio files
        let supportedExtensions = ["mp3", "flac", "wav", "m4a", "aac", "aiff", "aif"]
        let audioURLs = urls.filter { supportedExtensions.contains($0.pathExtension.lowercased()) }

        guard !audioURLs.isEmpty else { return }

        // Stop any current playback
        AudioPlayer.shared.stop()

        // Clear the existing playlist
        PlaylistManager.shared.clearPlaylist()

        // Add files to playlist and play the first one
        let tracks = audioURLs.map { Track(url: $0) }

        // Add tracks to playlist
        PlaylistManager.shared.addTracks(tracks)

        // Play the first opened file
        if !tracks.isEmpty {
            PlaylistManager.shared.playTrack(at: 0)
        }
    }

    /// Adds files to playlist without clearing (for "Add to MacAmp Playlist" service)
    static func addToPlaylist(_ urls: [URL]) {
        // Filter for supported audio files
        let supportedExtensions = ["mp3", "flac", "wav", "m4a", "aac", "aiff", "aif"]
        let audioURLs = urls.filter { supportedExtensions.contains($0.pathExtension.lowercased()) }

        guard !audioURLs.isEmpty else { return }

        // Add files to playlist
        let tracks = audioURLs.map { Track(url: $0) }
        PlaylistManager.shared.addTracks(tracks)

        // Bring app to front
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Service handler for "Add to MacAmp Playlist" context menu
    @objc func addToPlaylistService(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let urls = pboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            error.pointee = "Could not read files from pasteboard" as NSString
            return
        }

        AppDelegate.addToPlaylist(urls)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Mark app as fully launched
        AppDelegate.appHasLaunched = true

        // Register as services provider for "Add to MacAmp Playlist" context menu
        NSApp.servicesProvider = self

        guard let originalWindow = NSApplication.shared.windows.first else { return }

        let style: NSWindow.StyleMask = [
            .titled, .closable, .miniaturizable, .resizable, .fullSizeContentView
        ]

        let customWindow = KeyableWindow(contentRect: originalWindow.frame, styleMask: style, backing: .buffered, defer: false)

        // preserve NSHostingController if present
        if let contentVC = originalWindow.contentViewController {
            customWindow.contentViewController = contentVC
        } else if let contentView = originalWindow.contentView {
            customWindow.contentView = contentView
            contentView.frame = customWindow.contentView?.bounds ?? .zero
            contentView.autoresizingMask = [.width, .height]
        }

        // make sure the window content is transparent and composited
        customWindow.titlebarAppearsTransparent = true
        customWindow.isOpaque = false
        customWindow.backgroundColor = .clear
        customWindow.contentView?.wantsLayer = true
        // Clear any background layer color on the hosting view
        customWindow.contentView?.layer?.backgroundColor = NSColor.clear.cgColor

        customWindow.contentMinSize = NSSize(width: 275, height: 100)
        customWindow.contentMaxSize = NSSize(width: 20000, height: 20000)

        customWindow.title = originalWindow.title
        customWindow.level = originalWindow.level
        customWindow.collectionBehavior = originalWindow.collectionBehavior

        // Add small icon accessory (left-aligned by default)
        let accessory = TitlebarIconAccessory(icon: nil, iconSize: 14, paddingRight: 6)
        customWindow.addTitlebarAccessoryViewController(accessory)

        // Show the custom window and close original
        customWindow.makeKeyAndOrderFront(nil)
        originalWindow.close()

        // After the window is visible, attempt to position the accessory to the right of the traffic lights.
        DispatchQueue.main.async { [weak customWindow] in
            guard let win = customWindow else { return }

            guard let closeBtnSuperview = win.standardWindowButton(.closeButton)?.superview else {
                return
            }

            // Position accessory relative to the traffic-lights container
            accessory.view.translatesAutoresizingMaskIntoConstraints = false
            let gap: CGFloat = 6
            NSLayoutConstraint.activate([
                accessory.view.centerYAnchor.constraint(equalTo: closeBtnSuperview.centerYAnchor),
                accessory.view.leadingAnchor.constraint(equalTo: closeBtnSuperview.trailingAnchor, constant: gap)
            ])
        }
    }
}
