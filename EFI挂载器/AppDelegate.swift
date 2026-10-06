import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var window: NSWindow!

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {

        NSApp.appearance = nil

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

        setupMainMenu()
    }


    private func setupMainMenu() {

        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        let aboutItem = NSMenuItem(
            title: "关于 EFI挂载器",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        appMenu.addItem(aboutItem)

        appMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "退出 EFI挂载器",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenu.addItem(quitItem)

        NSApp.mainMenu = mainMenu
    }

    @objc
    private func showAbout() {

        let alert = NSAlert()

        if let iconURL = Bundle.main.url(
            forResource: "EFI图标",
            withExtension: "icns"
        ),
        let appIcon = NSImage(contentsOf: iconURL) {
            alert.icon = appIcon
        }

        alert.messageText = "EFI挂载器"

        let contentView = NSView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: 420,
                height: 210
            )
        )

        func makeLabel(
            _ text: String,
            y: CGFloat
        ) -> NSTextField {

            let label = NSTextField(
                labelWithString: text
            )

            label.frame = NSRect(
                x: 0,
                y: y,
                width: 420,
                height: 24
            )

            label.alignment = .center
            label.font = NSFont.systemFont(ofSize: 13)

            return label
        }

        contentView.addSubview(
            makeLabel(
                "EFI 分区一键挂载工具",
                y: 158
            )
        )

        contentView.addSubview(
            makeLabel(
                "版本 1.2.0",
                y: 136
            )
        )

        contentView.addSubview(
            makeLabel(
                "最低支持 macOS 11.0",
                y: 114
            )
        )

        contentView.addSubview(
            makeLabel(
                "作者：没气儿的青蛙",
                y: 76
            )
        )

        contentView.addSubview(
            makeLabel(
                "邮箱：386701036@qq.com",
                y: 54
            )
        )

        let githubButton = NSButton()
        githubButton.frame = NSRect(
            x: 0,
            y: 30,
            width: 420,
            height: 24
        )

        githubButton.isBordered = false
        githubButton.alignment = .center
        githubButton.target = self
        githubButton.action = #selector(openGitHub)

        let githubTitle = NSMutableAttributedString(
            string: "GitHub：github.com/luyf75",
            attributes: [
                .font: NSFont.systemFont(ofSize: 13),
                .foregroundColor: NSColor.systemBlue
            ]
        )

        githubButton.attributedTitle = githubTitle
        contentView.addSubview(githubButton)

        let projectButton = NSButton()
        projectButton.frame = NSRect(
            x: 0,
            y: 8,
            width: 420,
            height: 24
        )

        projectButton.isBordered = false
        projectButton.alignment = .center
        projectButton.target = self
        projectButton.action = #selector(openProject)

        let projectTitle = NSMutableAttributedString(
            string: "项目地址：github.com/luyf75/EFI-Mounter",
            attributes: [
                .font: NSFont.systemFont(ofSize: 13),
                .foregroundColor: NSColor.systemBlue
            ]
        )

        projectButton.attributedTitle = projectTitle
        contentView.addSubview(projectButton)

        alert.accessoryView = contentView
        alert.alertStyle = .informational
        alert.addButton(withTitle: "好")

        alert.runModal()
    }

    @objc
    private func openGitHub() {
        NSWorkspace.shared.open(
            URL(string: "https://github.com/luyf75")!
        )
    }

    @objc
    private func openProject() {
        NSWorkspace.shared.open(
            URL(string: "https://github.com/luyf75/EFI-Mounter")!
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        true
    }
}
