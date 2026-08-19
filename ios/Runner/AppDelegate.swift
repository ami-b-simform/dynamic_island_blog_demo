import UIKit
import Flutter
import ActivityKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    private let channelName = "com.example.dynamicIslandFlutter/live_activity"
    // Store as Any so AppDelegate remains available on all iOS versions.
    private var activities: [String: Any] = [:]

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Clean expired images on every launch
        ImageHelper.cleanExpiredAssets()

        let controller = window?.rootViewController
            as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else { return }
            switch call.method {
            case "startActivity":
                self.startActivity(call: call, result: result)
            case "updateActivity":
                self.updateActivity(call: call, result: result)
            case "endActivity":
                self.endActivity(call: call, result: result)
            case "saveImageToAppGroup":
                self.saveImageToAppGroup(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }

    // MARK: - Start Activity

    private func startActivity(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard #available(iOS 16.2, *) else {
            result(FlutterError(
                code: "UNSUPPORTED",
                message: "Live Activities require iOS 16.2+",
                details: nil
            ))
            return
        }

        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Missing arguments",
                details: nil
            ))
            return
        }

        // Priority rule: a new ride replaces any existing live activity.
        if #available(iOS 16.2, *) {
            Task {
                for (_, value) in self.activities {
                    if let existing = value as? Activity<RideAttributes> {
                        await existing.end(nil, dismissalPolicy: .immediate)
                    }
                }
                self.activities.removeAll()
            }
        }

        let attributes = RideAttributes(
            driverName:      args["driverName"]      as? String ?? "",
            carModel:        args["carModel"]         as? String ?? "",
            plateNumber:     args["plateNumber"]      as? String ?? "",
            driverImagePath: args["driverImagePath"]  as? String ?? ""
        )

        let contentState = RideAttributes.ContentState(
            distanceKm:   args["distanceKm"]   as? Double ?? 0,
            etaMinutes:   args["etaMinutes"]   as? Int    ?? 0,
            stage:        args["stage"]        as? String ?? "preparing",
            status:       args["status"]       as? String ?? "",
            finalMessage: ""
        )

        do {
            let activity = try Activity<RideAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            activities[activity.id] = activity
            print("AppDelegate: Activity started — \(activity.id)")
            result(activity.id)
        } catch {
            print("AppDelegate: Failed to start — \(error)")
            result(FlutterError(
                code: "START_FAILED",
                message: error.localizedDescription,
                details: nil
            ))
        }
    }

    // MARK: - Update Activity

    private func updateActivity(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard #available(iOS 16.2, *) else {
            result(FlutterError(
                code: "UNSUPPORTED",
                message: "Live Activities require iOS 16.2+",
                details: nil
            ))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let activityId = args["activityId"] as? String,
              let activity = activities[activityId] as? Activity<RideAttributes>
        else {
            result(FlutterError(
                code: "NOT_FOUND",
                message: "Activity not found",
                details: nil
            ))
            return
        }

        let newState = RideAttributes.ContentState(
            distanceKm:   args["distanceKm"]   as? Double ?? 0,
            etaMinutes:   args["etaMinutes"]   as? Int    ?? 0,
            stage:        args["stage"]        as? String ?? "preparing",
            status:       args["status"]       as? String ?? "",
            finalMessage: ""
        )

        Task {
            await activity.update(using: newState)
            print("AppDelegate: Activity updated — stage: \(newState.stage)")
            result(nil)
        }
    }

    // MARK: - End Activity

    private func endActivity(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard #available(iOS 16.2, *) else {
            result(FlutterError(
                code: "UNSUPPORTED",
                message: "Live Activities require iOS 16.2+",
                details: nil
            ))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let activityId = args["activityId"] as? String,
              let activity = activities[activityId] as? Activity<RideAttributes>
        else {
            result(FlutterError(
                code: "NOT_FOUND",
                message: "Activity not found",
                details: nil
            ))
            return
        }

        let finalMessage = args["finalMessage"] as? String ?? "Done"

        let finalState = RideAttributes.ContentState(
            distanceKm:   0,
            etaMinutes:   0,
            stage:        "delivered",
            status:       finalMessage,
            finalMessage: finalMessage
        )

        Task {
            // Show final state for 5 seconds then dismiss
            await activity.end(
                using: finalState,
                dismissalPolicy: .after(
                    Date.now.addingTimeInterval(5)
                )
            )
            activities.removeValue(forKey: activityId)
            print("AppDelegate: Activity ended — \(activityId)")
            result(nil)
        }
    }

    // MARK: - Save Image to App Group

    private func saveImageToAppGroup(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard let args = call.arguments as? [String: Any],
              let assetPath = args["assetPath"] as? String,
              let fileName  = args["fileName"]  as? String
        else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Missing assetPath or fileName",
                details: nil
            ))
            return
        }

        // Load image from Flutter asset bundle
        let key = FlutterDartProject.lookupKey(forAsset: assetPath)

        guard let imagePath = Bundle.main.path(forResource: key, ofType: nil),
              let imageData = FileManager.default.contents(atPath: imagePath)
        else {
            // Try direct path
            guard let imageData = FileManager.default.contents(atPath: assetPath)
            else {
                result(FlutterError(
                    code: "NOT_FOUND",
                    message: "Image not found: \(assetPath)",
                    details: nil
                ))
                return
            }
            let saved = ImageHelper.saveImageToAppGroup(
                imageData: imageData,
                fileName: fileName
            )
            result(saved)
            return
        }

        let saved = ImageHelper.saveImageToAppGroup(
            imageData: imageData,
            fileName: fileName
        )
        result(saved)
    }
}
