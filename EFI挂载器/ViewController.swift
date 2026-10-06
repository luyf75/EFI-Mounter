import Cocoa

final class ViewController: NSViewController {

    private let tableView = NSTableView()
    private let scrollView = NSScrollView()

    private let mountAllButton = NSButton(
        title: "一键挂载",
        target: nil,
        action: nil
    )

    private let refreshButton = NSButton(
        title: "刷新",
        target: nil,
        action: nil
    )

    private let unmountAllButton = NSButton(
        title: "一键推出",
        target: nil,
        action: nil
    )

    private let statusLabel = NSTextField(
        labelWithString: ""
    )

    private let detailHintLabel: NSTextField = {
        let label = NSTextField(
            labelWithString: "💡 双击EFI分区对应行的任意区域，可查看详细信息"
        )
        label.font = NSFont.systemFont(ofSize: 32, weight: .bold)
        label.textColor = .controlAccentColor
        label.alignment = .center
        label.alignment = .center
        label.maximumNumberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private var efiList: [EFIInfo] = []

    // MARK: - v1.1 自动刷新

    private var autoRefreshTimer: Timer?
    private var isRefreshing = false

    // 用于避免旧的后台刷新结果覆盖刚完成的挂载/推出操作
    private var refreshGeneration = 0

    override func loadView() {
        view = NSView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: 1200,
                height: 650
            )
        )
    }

    override func viewDidLoad() {

        print("=== VIEW DID LOAD START ===")

        super.viewDidLoad()

        print("=== BEFORE SETUP UI ===")

        setupUI()

        print("=== AFTER SETUP UI ===")

        print("=== BEFORE REFRESH ===")

        refresh()

        print("=== AFTER REFRESH ===")

        startAutoRefresh()
        registerWorkspaceNotifications()
    }

    deinit {
        autoRefreshTimer?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    private func startAutoRefresh() {
        autoRefreshTimer?.invalidate()

        autoRefreshTimer = Timer.scheduledTimer(
            withTimeInterval: 3.0,
            repeats: true
        ) { [weak self] _ in
            self?.refreshIfNeeded()
        }

        RunLoop.main.add(
            autoRefreshTimer!,
            forMode: .common
        )
    }

    private func registerWorkspaceNotifications() {
        let center = NSWorkspace.shared.notificationCenter

        center.addObserver(
            self,
            selector: #selector(workspaceDiskChanged(_:)),
            name: NSWorkspace.didMountNotification,
            object: nil
        )

        center.addObserver(
            self,
            selector: #selector(workspaceDiskChanged(_:)),
            name: NSWorkspace.didUnmountNotification,
            object: nil
        )

        center.addObserver(
            self,
            selector: #selector(workspaceDiskChanged(_:)),
            name: NSWorkspace.didPerformFileOperationNotification,
            object: nil
        )
    }

    @objc
    private func workspaceDiskChanged(_ notification: Notification) {
        refreshIfNeeded()
    }

    private func refreshIfNeeded() {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true
        refresh()
    }

    private func setupUI() {

        print("=== SETUP UI START ===")

        mountAllButton.target = self
        mountAllButton.action = #selector(mountAll)

        refreshButton.target = self
        refreshButton.action = #selector(refresh)

        unmountAllButton.target = self
        unmountAllButton.action = #selector(unmountAll)

        mountAllButton.bezelStyle = .rounded
        refreshButton.bezelStyle = .rounded
        unmountAllButton.bezelStyle = .rounded


        statusLabel.font = NSFont.systemFont(ofSize: 13)
        statusLabel.textColor = .secondaryLabelColor

        view.addSubview(mountAllButton)
        view.addSubview(refreshButton)
        view.addSubview(unmountAllButton)
        view.addSubview(statusLabel)
        view.addSubview(detailHintLabel)
        view.addSubview(scrollView)

        print("=== BEFORE SETUP TABLE ===")

        setupTableView()

        print("=== AFTER SETUP TABLE ===")

        print("=== BEFORE CONSTRAINTS ===")

        updateLayout()

        print("=== AFTER CONSTRAINTS ===")
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        updateLayout()
    }

    private func updateLayout() {

        let width = view.bounds.width
        let height = view.bounds.height

        let topY = height - 52

        mountAllButton.frame = NSRect(
            x: 20,
            y: topY,
            width: 110,
            height: 32
        )

        refreshButton.frame = NSRect(
            x: 140,
            y: topY,
            width: 80,
            height: 32
        )

        unmountAllButton.frame = NSRect(
            x: 230,
            y: topY,
            width: 90,
            height: 32
        )

        statusLabel.frame = NSRect(
            x: 340,
            y: topY + 5,
            width: max(200, width - 360),
            height: 22
        )

        detailHintLabel.frame = NSRect(
            x: 20,
            y: 35,
            width: max(600, width - 40),
            height: 38
        )

        scrollView.frame = NSRect(
            x: 20,
            y: 100,
            width: max(600, width - 40),
            height: max(220, height - 170)
        )
    }

    private func setupTableView() {

        let columns: [
            (String, String, CGFloat)
        ] = [
            ("type", "类型", 100),
            ("name", "磁盘名称", 180),
            ("disk", "磁盘", 80),
            ("diskSize", "磁盘容量", 100),
            ("efi", "ESP / EFI", 120),
            ("size", "EFI容量", 90),
            ("available", "EFI可用", 90),
            ("status", "状态", 100),
            ("action", "操作", 150)
        ]

        for item in columns {
            let column = NSTableColumn(
                identifier: NSUserInterfaceItemIdentifier(item.0)
            )

            column.title = item.1
            column.width = item.2
            column.minWidth = item.2

            let headerCell = NSTableHeaderCell()
            headerCell.stringValue = item.1
            headerCell.alignment = .center

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            headerCell.attributedStringValue = NSAttributedString(
                string: item.1,
                attributes: [
                    .font: NSFont.boldSystemFont(
                        ofSize: NSFont.systemFontSize + 1
                    ),
                    .foregroundColor: NSColor.labelColor,
                    .paragraphStyle: paragraphStyle
                ]
            )

            column.headerCell = headerCell

            tableView.addTableColumn(column)
        }

        tableView.delegate = self
        tableView.dataSource = self

        tableView.headerView = NSTableHeaderView()

        tableView.rowHeight = 36

        tableView.intercellSpacing = NSSize(
            width: 8,
            height: 0
        )

        tableView.gridStyleMask = [
            .solidHorizontalGridLineMask
        ]

        tableView.usesAlternatingRowBackgroundColors = true

        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true

        tableView.doubleAction = #selector(showEFIDetail(_:))
        tableView.target = self

        scrollView.borderType = .bezelBorder

        tableView.reloadData()
    }

    @objc
    private func refresh() {

        let generation = self.refreshGeneration

        DispatchQueue.global(qos: .userInitiated).async {

            let list = EFIManager.shared.scanEFI()

            DispatchQueue.main.async {

                // 如果刷新开始后用户进行了挂载/推出操作，
                // 当前扫描结果可能已经过时，不能覆盖最新 UI 状态。
                guard generation == self.refreshGeneration else {
                    self.isRefreshing = false
                    return
                }

                self.efiList = list
                self.tableView.reloadData()

                let totalCount = list.count
                let internalCount = list.filter { $0.isInternal }.count
                let externalCount = totalCount - internalCount

                self.statusLabel.stringValue =
                    "已检测到 \(totalCount) 个 EFI 分区：内置 EFI 分区 \(internalCount) 个，外置 EFI 分区 \(externalCount) 个"

                let hasMounted =
                    list.contains { $0.isMounted }

                let hasUnmounted =
                    list.contains { !$0.isMounted }

                self.mountAllButton.isEnabled =
                    hasUnmounted

                self.unmountAllButton.isEnabled =
                    hasMounted

                self.isRefreshing = false
            }
        }
    }

    @objc
    private func mountAll() {

        mountAllButton.isEnabled = false

        let list = efiList

        DispatchQueue.global(qos: .userInitiated).async {

            let paths = EFIManager.shared.mountAll(list)

            DispatchQueue.main.async {

                self.mountAllButton.isEnabled = true

                self.refresh()

                let message =
                    paths.isEmpty
                    ? "没有新的 EFI 被挂载。"
                    : paths.joined(separator: "\n")

                self.showAlert(
                    title: "一键挂载完成",
                    message: message
                )
            }
        }
    }

    @objc
    private func unmountAll() {

        unmountAllButton.isEnabled = false

        let list = efiList

        DispatchQueue.global(qos: .userInitiated).async {

            let success =
                EFIManager.shared.unmountAll(list)

            DispatchQueue.main.async {

                self.unmountAllButton.isEnabled = true

                self.refresh()

                self.showAlert(
                    title: success
                        ? "一键推出完成"
                        : "一键推出失败",
                    message: success
                        ? "所有已挂载的 EFI 已推出。"
                        : "部分 EFI 可能没有成功推出。"
                )
            }
        }
    }

    private func showAlert(
        title: String,
        message: String
    ) {

        let alert = NSAlert()

        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational

        alert.addButton(withTitle: "确定")

        alert.runModal()
    }
    
    // MARK: - EFI 详细信息

    @objc
    private func showEFIDetail(_ sender: Any?) {

        let row = tableView.clickedRow

        guard row >= 0,
              row < efiList.count
        else {
            return
        }

        let efi = efiList[row]

        let detailViewController = EFIDetailViewController(
            efi: efi
        )

        let window = NSWindow(
            contentViewController: detailViewController
        )

        window.title = "EFI详细信息"
        window.styleMask = [
            .titled,
            .closable,
            .miniaturizable
        ]
        window.setContentSize(
            NSSize(width: 360, height: 410)
        )
        window.center()
        window.isReleasedWhenClosed = false

        let controller = NSWindowController(
            window: window
        )

        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // 窗口已经显示后，再后台获取最新 EFI 数据
        DispatchQueue.global(qos: .userInitiated).async {

            let latestList = EFIManager.shared.scanEFI()

            guard let latestEFI = latestList.first(
                where: { $0.identifier == efi.identifier }
            )
            else {
                return
            }

            DispatchQueue.main.async {
                detailViewController.updateEFI(latestEFI)
            }
        }
    }

}

extension ViewController:
    NSTableViewDataSource,
    NSTableViewDelegate {

    func numberOfRows(
        in tableView: NSTableView
    ) -> Int {
        efiList.count
    }

    func tableView(
        _ tableView: NSTableView,
        viewFor tableColumn: NSTableColumn?,
        row: Int
    ) -> NSView? {

        guard row >= 0,
              row < efiList.count
        else {
            return nil
        }

        let efi = efiList[row]

        let identifier =
            tableColumn?.identifier.rawValue ?? ""

        if identifier == "action" {

            let container = NSView(
                frame: NSRect(
                    x: 0,
                    y: 0,
                    width: tableColumn?.width ?? 110,
                    height: tableView.rowHeight
                )
            )

            let actionButton = NSButton(
                title: efi.isMounted ? "推出" : "挂载",
                target: self,
                action: #selector(actionButton(_:))
            )

            actionButton.bezelStyle = .rounded
            actionButton.tag = row
            actionButton.frame = NSRect(
                x: 8,
                y: 4,
                width: 60,
                height: tableView.rowHeight - 8
            )

            let openButton = NSButton(
                title: "打开",
                target: self,
                action: #selector(openEFIButton(_:))
            )

            openButton.bezelStyle = .rounded
            openButton.tag = row
            openButton.frame = NSRect(
                x: 82,
                y: 4,
                width: 60,
                height: tableView.rowHeight - 8
            )

            // 未挂载时不能打开 EFI
            openButton.isEnabled = efi.isMounted

            container.addSubview(actionButton)
            container.addSubview(openButton)

            return container
        }

        let cellView = NSTableCellView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: tableColumn?.width ?? 100,
                height: tableView.rowHeight
            )
        )

        let cell = NSTextField(
            labelWithString: ""
        )

        cell.translatesAutoresizingMaskIntoConstraints = false
        cell.lineBreakMode = .byTruncatingTail
        cell.maximumNumberOfLines = 1

        cellView.addSubview(cell)

        NSLayoutConstraint.activate([
            cell.centerYAnchor.constraint(
                equalTo: cellView.centerYAnchor
            ),
            cell.leadingAnchor.constraint(
                equalTo: cellView.leadingAnchor,
                constant: 4
            ),
            cell.trailingAnchor.constraint(
                equalTo: cellView.trailingAnchor,
                constant: -4
            )
        ])

        cell.alignment = .center

        switch identifier {

        case "type":
            cell.stringValue = efi.typeName

        case "name":
            cell.stringValue = efi.diskName
            cell.alignment = .left

        case "disk":
            cell.stringValue = efi.wholeDisk

        case "diskSize":
            cell.stringValue = efi.diskSizeText

        case "efi":
            cell.stringValue = efi.identifier

        case "size":
            cell.stringValue = efi.sizeText

        case "available":
            cell.stringValue = efi.availableSizeText

        case "status":
            cell.stringValue = efi.statusText

        default:
            break
        }

        if identifier == "name" {
            cell.alignment = .left
        }

        return cellView
    }

    @objc
    private func actionButton(
        _ sender: NSButton
    ) {

        let row = sender.tag

        guard row >= 0,
              row < efiList.count
        else {
            return
        }

        let efi = efiList[row]

        // 操作开始时，使之前已经启动的后台刷新结果失效
        self.refreshGeneration += 1

        // 操作过程中立即禁用当前按钮，避免重复操作
        sender.isEnabled = false

        DispatchQueue.global(qos: .userInitiated).async {

            if efi.isMounted {

                let result = EFIManager.shared.unmount(efi)

                DispatchQueue.main.async {

                    sender.isEnabled = true

                    switch result {

                    case .success:

                        // 立即更新当前行状态
                        self.efiList[row].isMounted = false
                        self.efiList[row].mountPoint = nil
                        self.tableView.reloadData()

                        // 后台完整扫描校正真实状态
                        self.refreshIfNeeded()

                    case .failure(let error):

                        self.showAlert(
                            title: "EFI 推出失败",
                            message: error.localizedDescription
                        )
                    }
                }

                return
            }

            let result = EFIManager.shared.mount(efi)

            DispatchQueue.main.async {

                sender.isEnabled = true

                switch result {

                case .success(let path):

                    // 立即更新当前行状态
                    self.efiList[row].isMounted = true
                    self.efiList[row].mountPoint =
                        path.isEmpty ? nil : path
                    self.tableView.reloadData()

                    // 后台完整扫描校正真实状态
                    self.refreshIfNeeded()

                case .failure(let error):

                    self.showAlert(
                        title: "EFI 挂载失败",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    @objc
    private func openEFIButton(
        _ sender: NSButton
    ) {

        let row = sender.tag

        guard row >= 0,
              row < efiList.count
        else {
            return
        }

        let efi = efiList[row]

        guard efi.isMounted,
              let mountPoint = efi.mountPoint,
              !mountPoint.isEmpty
        else {
            return
        }

        NSWorkspace.shared.open(
            URL(fileURLWithPath: mountPoint)
        )
    }
}

// MARK: - EFI Detail Window

private final class EFIDetailViewController: NSViewController {

    private var efi: EFIInfo

    private var valueFields: [NSTextField] = []

    private let mountPathField = NSTextField(
        labelWithString: ""
    )

    private let copyButton = NSButton(
        title: "复制挂载路径",
        target: nil,
        action: nil
    )

    init(efi: EFIInfo) {
        self.efi = efi
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: 360,
                height: 380
            )
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // ============================================================
        // 上半区域：EFI 基本信息
        // 整个区域独立，以窗口中心为基准水平居中
        // ============================================================

        let windowWidth: CGFloat = 360

        let labelWidth: CGFloat = 85
        let columnGap: CGFloat = 10
        let valueWidth: CGFloat = 185

        let infoGroupWidth =
            labelWidth +
            columnGap +
            valueWidth

        // 标签右边缘固定在窗口中心线
        let centerX: CGFloat = 180
        let labelX = centerX - labelWidth

        let rows: [(String, String)] = [
            ("类型", efi.typeName),
            ("磁盘名称", efi.diskName),
            ("物理磁盘", efi.wholeDisk),
            ("EFI分区", efi.identifier),
            ("磁盘容量", efi.diskSizeText),
            ("EFI容量", efi.sizeText),
            ("EFI可用", efi.availableSizeText),
            ("分区类型", efi.partitionTypeText),
            ("状态", efi.isMounted ? "已挂载" : "未挂载")
        ]

        let firstRowY: CGFloat = 332
        let rowHeight: CGFloat = 24
        let rowSpacing: CGFloat = 6

        for (index, row) in rows.enumerated() {

            let y =
                firstRowY -
                CGFloat(index) *
                (rowHeight + rowSpacing)

            let label = NSTextField(
                labelWithString: row.0
            )

            label.font = NSFont.boldSystemFont(
                ofSize: 13
            )

            label.alignment = .right

            label.frame = NSRect(
                x: labelX,
                y: y,
                width: labelWidth,
                height: rowHeight
            )

            let value = NSTextField(
                labelWithString: row.1
            )

            valueFields.append(value)

            value.alignment = .left
            value.lineBreakMode =
                .byTruncatingTail
            value.frame = NSRect(
                x: centerX +
                    columnGap,
                y: y,
                width: valueWidth,
                height: rowHeight
            )

            view.addSubview(label)
            view.addSubview(value)
        }

        // ============================================================
        // 下半区域：挂载路径
        // 与上半区域完全独立
        // ============================================================

        let pathLabelWidth: CGFloat = 70
        let pathGap: CGFloat = 8
        let pathFieldWidth: CGFloat = 205

        let pathGroupWidth =
            pathLabelWidth +
            pathGap +
            pathFieldWidth

        let pathGroupX =
            (windowWidth - pathGroupWidth) / 2

        let pathY: CGFloat = 46

        let pathTitle = NSTextField(
            labelWithString: "挂载路径"
        )

        pathTitle.font = NSFont.boldSystemFont(
            ofSize: 13
        )

        pathTitle.alignment = .right

        pathTitle.frame = NSRect(
            x: pathGroupX,
            y: pathY - 4,
            width: pathLabelWidth,
            height: 24
        )

        mountPathField.stringValue =
            efi.mountPoint ?? "未挂载"

        mountPathField.isEditable = false
        mountPathField.isBordered = true
        mountPathField.lineBreakMode =
            .byTruncatingMiddle

        mountPathField.frame = NSRect(
            x: pathGroupX +
                pathLabelWidth +
                pathGap,
            y: pathY,
            width: pathFieldWidth,
            height: 24
        )

        view.addSubview(pathTitle)
        view.addSubview(mountPathField)

        // 复制按钮独立居中于窗口
        copyButton.target = self
        copyButton.action = #selector(copyMountPath)
        copyButton.bezelStyle = .rounded

        let buttonWidth: CGFloat = 105
        let buttonHeight: CGFloat = 30

        copyButton.frame = NSRect(
            x: (windowWidth - buttonWidth) / 2,
            y: 2,
            width: buttonWidth,
            height: buttonHeight
        )

        copyButton.isEnabled =
            efi.mountPoint != nil &&
            !(efi.mountPoint?.isEmpty ?? true)

        view.addSubview(copyButton)
    }

    func updateEFI(_ updatedEFI: EFIInfo) {

        efi = updatedEFI

        guard valueFields.count == 9 else {
            return
        }

        let values = [
            efi.typeName,
            efi.diskName,
            efi.wholeDisk,
            efi.identifier,
            efi.diskSizeText,
            efi.sizeText,
            efi.availableSizeText,
            efi.partitionTypeText,
            efi.isMounted ? "已挂载" : "未挂载"
        ]

        for (index, value) in values.enumerated() {
            valueFields[index].stringValue = value
        }

        mountPathField.stringValue =
            efi.mountPoint ?? "未挂载"

        copyButton.isEnabled =
            efi.mountPoint != nil &&
            !(efi.mountPoint?.isEmpty ?? true)
    }

    @objc
    private func copyMountPath() {

        guard let path = efi.mountPoint,
              !path.isEmpty
        else {
            return
        }

        NSPasteboard.general.clearContents()

        NSPasteboard.general.setString(
            path,
            forType: .string
        )

        copyButton.title = "已复制"

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.2
        ) { [weak self] in
            self?.copyButton.title = "复制挂载路径"
        }
    }
}

