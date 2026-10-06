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
        labelWithString: "正在扫描 EFI..."
    )

    private var efiList: [EFIInfo] = []

    // MARK: - v1.1 自动刷新

    private var autoRefreshTimer: Timer?
    private var isRefreshing = false

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

        scrollView.frame = NSRect(
            x: 20,
            y: 20,
            width: max(600, width - 40),
            height: max(300, height - 90)
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
            ("status", "状态", 150),
            ("action", "操作", 110)
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
    private func refresh(
        completion: (() -> Void)? = nil
    ) {

        statusLabel.stringValue = "正在扫描 EFI..."

        DispatchQueue.global(qos: .userInitiated).async {

            let list = EFIManager.shared.scanEFI()

            DispatchQueue.main.async {

                self.efiList = list
                self.tableView.reloadData()

                self.statusLabel.stringValue =
                    "检测到 \(list.count) 个 EFI 分区"

                let hasMounted =
                    list.contains { $0.isMounted }

                let hasUnmounted =
                    list.contains { !$0.isMounted }

                self.mountAllButton.isEnabled =
                    hasUnmounted

                self.unmountAllButton.isEnabled =
                    hasMounted

                self.isRefreshing = false

                completion?()
            }
        }
    }

    @objc
    private func mountAll() {

        mountAllButton.isEnabled = false

        let list = efiList

        DispatchQueue.global(qos: .userInitiated).async {

            let result = EFIManager.shared.mountAll(list)

            DispatchQueue.main.async {

                self.mountAllButton.isEnabled = true

                self.refresh()

                switch result {

                case .success(let paths):

                    let message =
                        paths.isEmpty
                        ? "没有新的 EFI 被挂载。"
                        : paths.joined(separator: "\n")

                    self.showAlert(
                        title: "一键挂载完成",
                        message: message
                    )

                case .failure(let error):

                    self.showAlert(
                        title: "一键挂载失败",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    @objc
    private func unmountAll() {

        unmountAllButton.isEnabled = false

        let list = efiList

        DispatchQueue.global(qos: .userInitiated).async {

            let result =
                EFIManager.shared.unmountAll(list)

            DispatchQueue.main.async {

                self.unmountAllButton.isEnabled = true

                self.refresh()

                switch result {

                case .success:

                    self.showAlert(
                        title: "一键推出完成",
                        message: "所有已挂载的 EFI 已推出。"
                    )

                case .failure(let error):

                    self.showAlert(
                        title: "一键推出失败",
                        message: error.localizedDescription
                    )
                }
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

        let detailViewController =
            EFIDetailViewController(
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
            NSSize(width: 360, height: 420)
        )
        window.center()
        window.isReleasedWhenClosed = false

        let controller =
            NSWindowController(
                window: window
            )

        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(
            ignoringOtherApps: true
        )

        // 窗口先立即显示，再后台刷新 EFI 数据
        let identifier = efi.identifier

        DispatchQueue.global(qos: .utility).async {

            let latestEFI =
                EFIManager.shared.scanEFI().first {
                    $0.identifier == identifier
                }

            guard let latestEFI = latestEFI else {
                return
            }

            DispatchQueue.main.async {

                detailViewController.updateEFI(
                    latestEFI
                )
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

            let button = NSButton(
                title: efi.isMounted ? "推出" : "挂载",
                target: self,
                action: #selector(actionButton(_:))
            )

            button.bezelStyle = .rounded

            button.tag = row

            return button
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

        if efi.isMounted {

            switch EFIManager.shared.unmount(efi) {

            case .success:

                refresh()

            case .failure(let error):

                showAlert(
                    title: "EFI 推出失败",
                    message: error.localizedDescription
                )
            }

            return
        }

        switch EFIManager.shared.mount(efi) {

        case .success:

            refresh {

                guard let mountedEFI =
                        self.efiList.first(
                            where: {
                                $0.identifier == efi.identifier
                            }
                        ),
                      let path =
                        mountedEFI.mountPoint,
                      !path.isEmpty
                else {
                    return
                }

                NSWorkspace.shared.open(
                    URL(fileURLWithPath: path)
                )
            }

        case .failure(let error):

            showAlert(
                title: "EFI 挂载失败",
                message: error.localizedDescription
            )
        }
    }
}


// MARK: - EFI Detail Window

private final class EFIDetailViewController: NSViewController {

    private var efi: EFIInfo

    private let mountPathField = NSTextField(
        labelWithString: ""
    )

    private let availableValueLabel = NSTextField(
        labelWithString: ""
    )

    private let statusValueLabel = NSTextField(
        labelWithString: ""
    )

    private let trashValueLabel = NSTextField(
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

    func updateEFI(_ newEFI: EFIInfo) {

        self.efi = newEFI

        availableValueLabel.stringValue =
            newEFI.availableSizeText

        statusValueLabel.stringValue =
            newEFI.isMounted ? "已挂载" : "未挂载"

        mountPathField.stringValue =
            newEFI.mountPoint ?? "未挂载"

        trashValueLabel.stringValue =
            newEFI.isMounted ? "计算中…" : "未挂载"

        guard
            newEFI.isMounted,
            let mountPoint = newEFI.mountPoint,
            !mountPoint.isEmpty
        else {
            return
        }

        DispatchQueue.global(qos: .utility).async {

            let trashSize =
                EFIManager.shared.getTrashSize(mountPoint)

            let trashText =
                ByteCountFormatter.string(
                    fromByteCount: Int64(trashSize),
                    countStyle: .file
                )

            DispatchQueue.main.async {

                guard self.efi.identifier == newEFI.identifier else {
                    return
                }

                self.trashValueLabel.stringValue =
                    trashText
            }
        }
    }

    override func loadView() {
        view = NSView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: 360,
                height: 420
            )
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // ============================================================
        // 上半区域：EFI 基本信息
        // 整个区域独立，以窗口中心为基准水平居中
        // ============================================================

        availableValueLabel.stringValue =
            efi.availableSizeText

        statusValueLabel.stringValue =
            efi.isMounted ? "已挂载" : "未挂载"

        trashValueLabel.stringValue =
            efi.isMounted ? "计算中…" : "未挂载"

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
            ("状态", efi.isMounted ? "已挂载" : "未挂载"),
            ("废纸篓占用", "计算中…")
        ]

        let firstRowY: CGFloat = 365
        let rowHeight: CGFloat = 24
        let rowSpacing: CGFloat = 3

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

            if row.0 == "EFI可用" {
                availableValueLabel.frame = value.frame
                availableValueLabel.alignment = .left
                availableValueLabel.lineBreakMode =
                    .byTruncatingTail
                view.addSubview(availableValueLabel)
                value.removeFromSuperview()
            }

            if row.0 == "状态" {
                statusValueLabel.frame = value.frame
                statusValueLabel.alignment = .left
                statusValueLabel.lineBreakMode =
                    .byTruncatingTail
                view.addSubview(statusValueLabel)
                value.removeFromSuperview()
            }


            if row.0 == "废纸篓占用" {
                trashValueLabel.frame = value.frame
                trashValueLabel.alignment = .left
                trashValueLabel.lineBreakMode =
                    .byTruncatingTail
                view.addSubview(trashValueLabel)
                value.removeFromSuperview()
            }

        }

        // ============================================================
        // 后台计算 EFI 废纸篓占用
        // 只在打开详情窗口时计算一次
        // ============================================================

        if efi.isMounted,
           let mountPoint = efi.mountPoint,
           !mountPoint.isEmpty {

            DispatchQueue.global(qos: .utility).async {

                let trashSize =
                    EFIManager.shared.getTrashSize(mountPoint)

                let trashText =
                    ByteCountFormatter.string(
                        fromByteCount: Int64(trashSize),
                        countStyle: .file
                    )

                DispatchQueue.main.async {
                    self.trashValueLabel.stringValue = trashText
                }
            }

        } else {

            trashValueLabel.stringValue = "未挂载"
        }

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

        let pathY: CGFloat = 68

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
            y: 28,
            width: buttonWidth,
            height: buttonHeight
        )

        copyButton.isEnabled =
            efi.mountPoint != nil &&
            !(efi.mountPoint?.isEmpty ?? true)

        view.addSubview(copyButton)
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

