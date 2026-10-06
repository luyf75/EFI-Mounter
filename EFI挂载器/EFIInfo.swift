import Foundation

struct EFIInfo {

    let identifier: String
    let wholeDisk: String
    let diskName: String
    let volumeName: String
    let diskSize: UInt64
    let size: UInt64
    let availableSize: UInt64?
    let isInternal: Bool

    var isMounted: Bool
    var mountPoint: String?

    var typeName: String {
        isInternal ? "内置硬盘" : "外置设备"
    }

    var partitionTypeText: String {
        "ESP / EFI"
    }

    var diskSizeText: String {

        let gb =
            Double(diskSize) /
            1_000_000_000.0

        if gb >= 1.0 {
            return String(
                format: "%.1f GB",
                gb
            )
        }

        let mb =
            Double(diskSize) /
            1_000_000.0

        return String(
            format: "%.0f MB",
            mb
        )
    }

    var availableSizeText: String {

        guard let availableSize else {
            return "—"
        }

        let gb =
            Double(availableSize) /
            1_000_000_000.0

        if gb >= 1.0 {
            return String(
                format: "%.1f GB",
                gb
            )
        }

        let mb =
            Double(availableSize) /
            1_000_000.0

        return String(
            format: "%.0f MB",
            mb
        )
    }

    var sizeText: String {

        let gb =
            Double(size) /
            1_000_000_000.0

        if gb >= 1.0 {
            return String(
                format: "%.1f GB",
                gb
            )
        }

        let mb =
            Double(size) /
            1_000_000.0

        return String(
            format: "%.0f MB",
            mb
        )
    }

    var statusText: String {

        if let path = mountPoint,
           isMounted {

            return "已挂载：\(path)"
        }

        return "未挂载"
    }
}
