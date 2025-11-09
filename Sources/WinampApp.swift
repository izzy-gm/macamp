import SwiftUI
import AppKit

@main
struct WinampApp: App {
    @StateObject private var audioPlayer = AudioPlayer.shared
    @StateObject private var playlistManager = PlaylistManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioPlayer)
                .environmentObject(playlistManager)
                .preferredColorScheme(.dark)
                .background(Color.clear)
                // Let the window sizing be driven by the SwiftUI content.
                // Avoid forcing edgesIgnoringSafeArea / infinite frames on macOS.
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

// Custom window that can become key without needing a title bar
class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        super.setFrame(frameRect, display: flag)
        self.invalidateShadow()
    }

    override func setFrame(_ frameRect: NSRect, display displayFlag: Bool, animate animateFlag: Bool) {
        super.setFrame(frameRect, display: displayFlag, animate: animateFlag)
        self.invalidateShadow()
    }
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        // Make the window transparent
        isOpaque = false
        backgroundColor = NSColor.clear
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
    }

}

// App delegate to replace windows with our custom class
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Grab the original SwiftUI-hosted window (if any)
        guard let originalWindow = NSApplication.shared.windows.first else { return }

        // Create a new KeyableWindow with appropriate style masks.
        // Include .titled so the window system provides standard behaviors,
        // and .fullSizeContentView so content can extend into the titlebar area.
        let style: NSWindow.StyleMask = [
            .titled,
            .closable,
            .miniaturizable,
            .resizable,
            .fullSizeContentView
        ]

        let customWindow = KeyableWindow(
            contentRect: originalWindow.frame,
            styleMask: style,
            backing: .buffered,
            defer: false
        )

        // Preserve the hosting view controller (this keeps SwiftUI autosizing & layout working)
        if let contentVC = originalWindow.contentViewController {
            customWindow.contentViewController = contentVC
        } else if let contentView = originalWindow.contentView {
            // Fallback: copy the view and set autoresizing masks so it stretches
            customWindow.contentView = contentView
            contentView.frame = customWindow.contentView?.bounds ?? .zero
            contentView.autoresizingMask = [.width, .height]
        }

        // Make the titlebar look "hidden" but keep behaviors that let user drag the window
        customWindow.titlebarAppearsTransparent = true
        customWindow.isMovableByWindowBackground = true

        // Background and opacity
        customWindow.backgroundColor = NSColor.windowBackgroundColor
        customWindow.isOpaque = false
        customWindow.backgroundColor = .clear

        // Ensure the window can resize to the content and has reasonable min/max
        customWindow.contentMinSize = NSSize(width: 275, height: 100)
        customWindow.contentMaxSize = NSSize(width: 20000, height: 20000)

        // Preserve other properties
        customWindow.title = originalWindow.title
        customWindow.level = .floating
        customWindow.collectionBehavior = originalWindow.collectionBehavior

        // Show and replace
        customWindow.makeKeyAndOrderFront(nil)
        originalWindow.close()
    }
}
