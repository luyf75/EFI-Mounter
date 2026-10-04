import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var window: NSWindow!

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {

        let viewController = ViewController()

        window = NSWindow(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: 900,
                height: 520
            ),
            styleMask: [
                .titled,
                .closable,
                .miniaturizable,
                .resizable
            ],
            backing: .buffered,
            defer: false
        )

        window.title = "ESP / EFI 挂载器"
        window.contentViewController = viewController
        window.isReleasedWhenClosed = false

        window.center()
        window.makeKeyAndOrderFront(nil)

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        true
    }
}
