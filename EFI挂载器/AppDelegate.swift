import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var window: NSWindow!

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {

        print("=== APP DELEGATE DID FINISH LAUNCHING ===")
        print("=== BEFORE VIEW CONTROLLER ===")

        let viewController = ViewController()

        print("=== AFTER VIEW CONTROLLER ===")

        print("=== BEFORE WINDOW ===")

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

        print("=== AFTER WINDOW ===")

        window.title = "ESP / EFI 挂载器"

        print("=== AFTER TITLE ===")
        print("=== BEFORE CONTENT VIEW CONTROLLER ===")

        window.contentViewController = viewController

        print("=== AFTER CONTENT VIEW CONTROLLER ===")
        window.isReleasedWhenClosed = false

        print("=== BEFORE CENTER ===")

        window.center()

        print("=== AFTER CENTER ===")
        print("=== BEFORE MAKE KEY ===")

        window.makeKeyAndOrderFront(nil)

        print("=== AFTER MAKE KEY ===")

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        print("=== VIEW CONTROLLER LOADED ===")
        print("window count =", NSApp.windows.count)
        print("window visible =", window.isVisible)
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        true
    }
}
