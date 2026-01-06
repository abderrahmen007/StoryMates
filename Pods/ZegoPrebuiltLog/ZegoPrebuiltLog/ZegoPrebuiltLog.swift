//
//  ZegoPrebuiltLog.swift
//  ZegoPrebuiltLog
//
//  Created by tripli on 2025/11/19.
//

import Foundation
import ZIPFoundation

public final class ZegoPrebuiltLog : NSObject {
    public static let shared = ZegoPrebuiltLog()
    
    public func write(_ content: String) {
        LogManager.sharedInstance().write(content)
    }
    
    public func zipLogFiles(_ destinationZipFileURL: URL? = nil) -> URL? {
        var actualZipFileURL: URL? = nil

        if (destinationZipFileURL == nil) {
            actualZipFileURL = getDefaultDestinationZipFileURL()
        } else {
            var isDirectory: ObjCBool = false
            let destinationExist = FileManager.default.fileExists(atPath: destinationZipFileURL!.path, isDirectory: &isDirectory)
            if (!destinationExist) {
                actualZipFileURL = destinationZipFileURL
            } else if (isDirectory.boolValue) {
                actualZipFileURL = getDefaultDestinationZipFileURL()
            } else {
                do {
                    try FileManager.default.removeItem(at: destinationZipFileURL!)
                    actualZipFileURL = destinationZipFileURL
                } catch {
                    actualZipFileURL = getDefaultDestinationZipFileURL()
                }
            }
        }

        // flush before export
        LogManager.sharedInstance().flush()
        
        let prebuiltLogFiles = getLogFileList(folderName: PREBUILT_LOG_FOLDER_NAME, fileExtensionList: ["log"])
        let rtcLogFiles = getLogFileList(folderName: "ZegoLogs", fileExtensionList: ["txt", "zip"])
        let zimLogFiles = getLogFileList(folderName: "ZIMLogs", fileExtensionList: ["txt"])
        let comboLogFiles = prebuiltLogFiles + rtcLogFiles + zimLogFiles

        do {
            let archive = try Archive(url: actualZipFileURL!, accessMode: .create)
            for path in comboLogFiles {
                let fileURL = URL(fileURLWithPath: path)
                try archive.addEntry(with: fileURL.lastPathComponent,
                                     relativeTo: fileURL.deletingLastPathComponent())
            }
        } catch {
            print("archive error: \(error)")
            return nil
        }
        
        return actualZipFileURL
    }

    private func getLogFileList(folderName: String, fileExtensionList: [String]) -> [String] {
        let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let logFolderURL = cachesURL.appendingPathComponent(folderName, isDirectory: true)
        let logURLs = (try? FileManager.default.contentsOfDirectory(
                            at: logFolderURL,
                            includingPropertiesForKeys: nil,
                            options: [])
                       )?
            .filter { fileExtensionList.contains($0.pathExtension.lowercased()) }
            ?? []
        return logURLs.map { $0.path }
    }
    
    private func getDefaultDestinationZipFileURL() -> URL {
        let df = DateFormatter()
        df.dateFormat = "HHmm"
        let fileBaseName = "prebuilt_" + df.string(from: Date()) + "_log"
        return FileManager.default.temporaryDirectory.appendingPathComponent(fileBaseName + ".zip")
    }
}
