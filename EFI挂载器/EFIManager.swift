import Foundation
import AppKit

final class EFIManager {

    static let shared = EFIManager()

    private let diskutil = "/usr/sbin/diskutil"

    private init() {}

    private func run(
        _ arguments: [String]
    ) -> (
        output: String,
        error: String,
        status: Int32
    ) {

        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL =
            URL(fileURLWithPath: diskutil)

        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {

            try process.run()
            process.waitUntilExit()

            let outputData =
                outputPipe.fileHandleForReading
                    .readDataToEndOfFile()

            let errorData =
                errorPipe.fileHandleForReading
                    .readDataToEndOfFile()

            return (
                String(
                    data: outputData,
                    encoding: .utf8
                ) ?? "",

                String(
                    data: errorData,
                    encoding: .utf8
                ) ?? "",

                process.terminationStatus
            )

        } catch {

            return (
                "",
                error.localizedDescription,
                -1
            )
        }
    }

    // MARK: - EFI 扫描

    func scanEFI() -> [EFIInfo] {

        let result = run([
            "list",
            "-plist"
        ])

        guard result.status == 0,
              let data =
                result.output.data(using: .utf8),
              let plist =
                try? PropertyListSerialization
                    .propertyList(
                        from: data,
                        options: [],
                        format: nil
                    ) as? [String: Any],
              let disks =
                plist["AllDisksAndPartitions"]
                    as? [[String: Any]]
        else {
            return []
        }

        var list: [EFIInfo] = []

        for disk in disks {

            guard let wholeDisk =
                    disk["DeviceIdentifier"] as? String,
                  let partitions =
                    disk["Partitions"] as? [[String: Any]]
            else {
                continue
            }

            let info = run([
                "info",
                "-plist",
                wholeDisk
            ])

            guard info.status == 0,
                  let infoData =
                    info.output.data(using: .utf8),
                  let diskInfo =
                    try? PropertyListSerialization
                        .propertyList(
                            from: infoData,
                            options: [],
                            format: nil
                        ) as? [String: Any]
            else {
                continue
            }

            // 只接受真实物理磁盘。
            // DMG / Shared Support 等虚拟磁盘会被过滤。
            let virtualOrPhysical =
                diskInfo["VirtualOrPhysical"]
                    as? String ?? ""

            guard virtualOrPhysical
                    .lowercased() == "physical"
            else {
                continue
            }

            let internalDisk =
                getInternalStatus(diskInfo)

            let diskName =
                diskInfo["MediaName"] as? String ??
                diskInfo["VolumeName"] as? String ??
                wholeDisk

    

            let diskSize: UInt64 = {
                if let value = diskInfo["Size"] as? UInt64 {
                    return value
                }

                if let value = diskInfo["Size"] as? Int64 {
                    return UInt64(max(0, value))
                }

                if let value = diskInfo["Size"] as? NSNumber {
                    return value.uint64Value
                }

                return 0
            }()

            for partition in partitions {

                guard let identifier =
                        partition["DeviceIdentifier"]
                            as? String
                else {
                    continue
                }

                let content =
                    partition["Content"] as? String ?? ""

                guard content.uppercased() == "EFI"
                else {
                    continue
                }

                let volumeName =
                    partition["VolumeName"]
                        as? String ?? "EFI"

                let size =
                    partition["Size"] as? UInt64 ??
                    UInt64(
                        partition["Size"]
                            as? Int64 ?? 0
                    )

                let mountPoint =
                    getMountPoint(identifier)

                list.append(
                    EFIInfo(
                        identifier: identifier,
                        wholeDisk: wholeDisk,
                        diskName: diskName,
                        volumeName: volumeName,
                        diskSize: diskSize,
                        size: size,
                        isInternal: internalDisk,
                        isMounted: mountPoint != nil,
                        mountPoint: mountPoint
                    )
                )
            }
        }

        return list
    }

    private func getInternalStatus(
        _ diskInfo: [String: Any]
    ) -> Bool {

        if let value =
            diskInfo["Internal"] as? Bool {
            return value
        }

        if let value =
            diskInfo["DeviceInternal"] as? Bool {
            return value
        }

        if let value =
            diskInfo["Removable"] as? Bool {
            return !value
        }

        if let value =
            diskInfo["Ejectable"] as? Bool {
            return !value
        }

        return false
    }

    // MARK: - 挂载点

    func getMountPoint(
        _ identifier: String
    ) -> String? {

        let result = run([
            "info",
            "-plist",
            identifier
        ])

        guard result.status == 0,
              let data =
                result.output.data(using: .utf8),
              let plist =
                try? PropertyListSerialization
                    .propertyList(
                        from: data,
                        options: [],
                        format: nil
                    ) as? [String: Any]
        else {
            return nil
        }

        if let mountPoint =
            plist["MountPoint"] as? String,
           !mountPoint.isEmpty {

            return mountPoint
        }

        return nil
    }

    // MARK: - 管理员授权执行 diskutil

    private func runAsAdministrator(
        _ arguments: [String]
    ) -> (
        output: String,
        error: String,
        status: Int32
    ) {

        let escapedArguments =
            arguments.map { argument in
                "'" + argument
                    .replacingOccurrences(
                        of: "'",
                        with: "'\\''"
                    ) + "'"
            }
            .joined(separator: " ")

        let command =
            "\(diskutil) \(escapedArguments)"

        let script =
            "do shell script " +
            quotedAppleScriptString(command) +
            " with administrator privileges"

        let process = Process()

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL =
            URL(fileURLWithPath: "/usr/bin/osascript")

        process.arguments = [
            "-e",
            script
        ]

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {

            try process.run()
            process.waitUntilExit()

            let outputData =
                outputPipe.fileHandleForReading
                    .readDataToEndOfFile()

            let errorData =
                errorPipe.fileHandleForReading
                    .readDataToEndOfFile()

            return (
                String(
                    data: outputData,
                    encoding: .utf8
                ) ?? "",

                String(
                    data: errorData,
                    encoding: .utf8
                ) ?? "",

                process.terminationStatus
            )

        } catch {

            return (
                "",
                error.localizedDescription,
                -1
            )
        }
    }

    private func quotedAppleScriptString(
        _ string: String
    ) -> String {

        let escaped =
            string
                .replacingOccurrences(
                    of: "\\",
                    with: "\\\\"
                )
                .replacingOccurrences(
                    of: "\"",
                    with: "\\\""
                )

        return "\"\(escaped)\""
    }

    // MARK: - 挂载

    func mount(
        _ efi: EFIInfo
    ) -> Result<String, Error> {

        if let existing =
            getMountPoint(efi.identifier) {

            return .success(existing)
        }

        let result =
            runAsAdministrator([
                "mount",
                efi.identifier
            ])

        guard result.status == 0 else {

            let message =
                result.error.isEmpty
                ? result.output
                : result.error

            return .failure(
                NSError(
                    domain: "EFI挂载器",
                    code: Int(result.status),
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            message.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                    ]
                )
            )
        }

        // 挂载成功后不再立即调用 getMountPoint()。
        // 实际挂载路径由后续 refresh() 扫描后获取。
        return .success("")
    }

    // MARK: - 卸载

    func unmount(
        _ efi: EFIInfo
    ) -> Result<Void, Error> {

        let result =
            run([
                "unmount",
                efi.identifier
            ])

        guard result.status == 0 else {

            let message =
                result.error.isEmpty
                ? result.output
                : result.error

            return .failure(
                NSError(
                    domain: "EFI挂载器",
                    code: Int(result.status),
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            message.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                    ]
                )
            )
        }

        return .success(())
    }

    // MARK: - 一键推出

    func unmountAll(
        _ list: [EFIInfo]
    ) -> Result<Void, Error> {

        let mounted = list.filter {
            getMountPoint($0.identifier) != nil
        }

        guard !mounted.isEmpty else {
            return .success(())
        }

        for efi in mounted {

            let result = run([
                "unmount",
                efi.identifier
            ])

            guard result.status == 0 else {

                let message =
                    result.error.isEmpty
                    ? result.output
                    : result.error

                return .failure(
                    NSError(
                        domain: "EFI挂载器",
                        code: Int(result.status),
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                message.trimmingCharacters(
                                    in: .whitespacesAndNewlines
                                )
                        ]
                    )
                )
            }
        }

        return .success(())
    }

    // MARK: - 打开 EFI

    func open(
        _ efi: EFIInfo
    ) -> Bool {

        guard let path =
            getMountPoint(efi.identifier)
        else {
            return false
        }

        return NSWorkspace.shared.open(
            URL(fileURLWithPath: path)
        )
    }

    // MARK: - 一键挂载

    func mountAll(
        _ list: [EFIInfo]
    ) -> Result<[String], Error> {

        let unmounted = list.filter {
            getMountPoint($0.identifier) == nil
        }

        guard !unmounted.isEmpty else {

            let paths = list.compactMap {
                getMountPoint($0.identifier)
            }

            return .success(paths)
        }

        let arguments = unmounted.map {
            $0.identifier
        }

        let shellCommands = arguments.map {
            "\(diskutil) mount \($0)"
        }

        let command =
            shellCommands.joined(separator: " && ")

        let script =
            "do shell script " +
            quotedAppleScriptString(command) +
            " with administrator privileges"

        let process = Process()

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL =
            URL(fileURLWithPath: "/usr/bin/osascript")

        process.arguments = [
            "-e",
            script
        ]

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return .failure(error)
        }

        guard process.terminationStatus == 0 else {

            let errorData =
                errorPipe.fileHandleForReading
                    .readDataToEndOfFile()

            let message =
                String(
                    data: errorData,
                    encoding: .utf8
                ) ?? "一键挂载失败。"

            return .failure(
                NSError(
                    domain: "EFI挂载器",
                    code: Int(process.terminationStatus),
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            message.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                    ]
                )
            )
        }

        let paths = list.compactMap {
            getMountPoint($0.identifier)
        }

        return .success(paths)
    }


    // MARK: - 废纸篓占用

    func getTrashSize(
        _ mountPoint: String
    ) -> UInt64 {

        let trashPath =
            mountPoint + "/.Trashes"

        let fileManager =
            FileManager.default

        guard
            fileManager.fileExists(atPath: trashPath)
        else {
            return 0
        }

        var totalSize: UInt64 = 0

        guard
            let enumerator =
                fileManager.enumerator(
                    at: URL(fileURLWithPath: trashPath),
                    includingPropertiesForKeys: [
                        .fileSizeKey,
                        .isRegularFileKey
                    ]
                )
        else {
            return 0
        }

        for case let url as URL in enumerator {

            guard
                let values =
                    try? url.resourceValues(
                        forKeys: [
                            .fileSizeKey,
                            .isRegularFileKey
                        ]
                    ),
                values.isRegularFile == true,
                let size = values.fileSize
            else {
                continue
            }

            totalSize += UInt64(size)
        }

        return totalSize
    }

}
