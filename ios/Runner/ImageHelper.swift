import Foundation
import UIKit

struct ImageHelper {

    static let appGroupID = "group.com.example.dynamicIslandFlutter"

    /// Save image data to App Group shared container
    /// Called from Flutter before starting the Live Activity
    static func saveImageToAppGroup(
        imageData: Data,
        fileName: String
    ) -> String? {
        guard let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
        else {
            print("ImageHelper: App Group container not found")
            return nil
        }

        let fileURL = container
            .appendingPathComponent("DriverImages")
            .appendingPathComponent(fileName)

        do {
            // Create directory if needed
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try imageData.write(to: fileURL)
            print("ImageHelper: Saved to \(fileURL.path)")
            return fileURL.path
        } catch {
            print("ImageHelper: Failed to save — \(error)")
            return nil
        }
    }

    /// Load image from App Group shared container
    /// Called from the Widget Extension SwiftUI view
    static func loadImageFromAppGroup(fileName: String) -> UIImage? {
        guard let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
        else { return nil }

        let fileURL = container
            .appendingPathComponent("DriverImages")
            .appendingPathComponent(fileName)

        guard let data = try? Data(contentsOf: fileURL) else {
            print("ImageHelper: File not found at \(fileURL.path)")
            return nil
        }
        return UIImage(data: data)
    }

    /// Clean up images older than 24 hours — call on app launch
    static func cleanExpiredAssets() {
        guard let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
        else { return }

        let dir = container.appendingPathComponent("DriverImages")
        guard let files = try? FileManager.default
            .contentsOfDirectory(at: dir,
                includingPropertiesForKeys: [.creationDateKey])
        else { return }

        let cutoff = Date().addingTimeInterval(-86400) // 24 hours
        for file in files {
            if let created = try? file.resourceValues(
                forKeys: [.creationDateKey]).creationDate,
               created < cutoff {
                try? FileManager.default.removeItem(at: file)
                print("ImageHelper: Cleaned \(file.lastPathComponent)")
            }
        }
    }
}