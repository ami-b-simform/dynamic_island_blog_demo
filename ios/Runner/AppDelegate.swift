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

    // MARK: - Shared Preamble

    /// Every Live Activity handler needs the same two things: iOS 16.2+ and a
    /// dictionary of arguments. This resolves both and reports the right error
    /// to Flutter, so each handler below starts at the interesting line.
    @discardableResult
    private func withActivityArgs(
        _ call: FlutterMethodCall,
        _ result: @escaping FlutterResult,
        _ body: ([String: Any]) -> Void
    ) -> Bool {
        guard #available(iOS 16.2, *) else {
            result(FlutterError(
                code: "UNSUPPORTED",
                message: "Live Activities require iOS 16.2+",
                details: nil
            ))
            return false
        }

        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Missing arguments",
                details: nil
            ))
            return false
        }

        body(args)
        return true
    }

    /// Look up a running activity by the id Flutter holds.
    @available(iOS 16.2, *)
    private func activity(
        for args: [String: Any],
        _ result: @escaping FlutterResult
    ) -> Activity<RideAttributes>? {
        guard let activityId = args["activityId"] as? String,
              let activity = activities[activityId] as? Activity<RideAttributes>
        else {
            result(FlutterError(
                code: "NOT_FOUND",
                message: "Activity not found",
                details: nil
            ))
            return nil
        }
        return activity
    }

    // MARK: - Start Activity

    private func startActivity(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        withActivityArgs(call, result) { args in
            guard #available(iOS 16.2, *) else { return }

            // Live Activities can be switched off per-app in Settings. Without
            // this check `request` throws a generic error that's hard to place.
            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                result(FlutterError(
                    code: "NOT_ENABLED",
                    message: "Live Activities are disabled for this app. "
                        + "Enable them in Settings → Dynamic Island Demo.",
                    details: nil
                ))
                return
            }

            // Priority rule: a new ride replaces any existing live activity.
            //
            // Clear the dictionary *synchronously*, before the new activity is
            // stored below. Doing it inside the Task would let `removeAll()`
            // run after the new entry was added and wipe it, so every later
            // `updateActivity` would report "Activity not found".
            let previous = self.activities.values
                .compactMap { $0 as? Activity<RideAttributes> }
            self.activities.removeAll()

            Task {
                for existing in previous {
                    await existing.end(nil, dismissalPolicy: .immediate)
                }
            }

            let attributes = RideAttributes(
                driverName:      args["driverName"]      as? String ?? "",
                carModel:        args["carModel"]        as? String ?? "",
                plateNumber:     args["plateNumber"]     as? String ?? "",
                driverImagePath: args["driverImagePath"] as? String ?? ""
            )

            let contentState = RideAttributes.ContentState(
                distanceKm: args["distanceKm"] as? Double ?? 0,
                etaMinutes: args["etaMinutes"] as? Int    ?? 0,
                stage:      args["stage"]      as? String ?? "preparing",
                status:     args["status"]     as? String ?? ""
            )

            do {
                let activity = try Activity<RideAttributes>.request(
                    attributes: attributes,
                    contentState: contentState,
                    pushType: nil
                )
                self.activities[activity.id] = activity
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
    }

    // MARK: - Update Activity

    private func updateActivity(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        withActivityArgs(call, result) { args in
            guard #available(iOS 16.2, *),
                  let activity = self.activity(for: args, result) else { return }

            let newState = RideAttributes.ContentState(
                distanceKm: args["distanceKm"] as? Double ?? 0,
                etaMinutes: args["etaMinutes"] as? Int    ?? 0,
                stage:      args["stage"]      as? String ?? "preparing",
                status:     args["status"]     as? String ?? ""
            )

            Task {
                await activity.update(using: newState)
                print("AppDelegate: Activity updated — stage: \(newState.stage)")
                result(nil)
            }
        }
    }

    // MARK: - End Activity

    private func endActivity(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        withActivityArgs(call, result) { args in
            guard #available(iOS 16.2, *),
                  let activity = self.activity(for: args, result) else { return }

            guard let activityId = args["activityId"] as? String else { return }

            // The widget reads `status`, so the closing line goes there.
            let finalState = RideAttributes.ContentState(
                distanceKm: 0,
                etaMinutes: 0,
                stage:      "delivered",
                status:     args["finalMessage"] as? String ?? "Done"
            )

            Task {
                // Show the final state for 5 seconds, then dismiss.
                await activity.end(
                    using: finalState,
                    dismissalPolicy: .after(
                        Date.now.addingTimeInterval(5)
                    )
                )
                self.activities.removeValue(forKey: activityId)
                print("AppDelegate: Activity ended — \(activityId)")
                result(nil)
            }
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

        // Flutter assets are packaged inside App.framework, not the main
        // bundle, so look there first. `lookupKey` turns
        // "assets/images/driver1.jpeg" into the bundled asset key.
        let key = FlutterDartProject.lookupKey(forAsset: assetPath)
        let resolvedPath =
            Bundle.main.path(forResource: key, ofType: nil)
            ?? Bundle(identifier: "io.flutter.flutter.app")?
                .path(forResource: key, ofType: nil)
            ?? assetPath

        guard let imageData = FileManager.default
            .contents(atPath: resolvedPath)
        else {
            result(FlutterError(
                code: "NOT_FOUND",
                message: "Image not found: \(assetPath)",
                details: nil
            ))
            return
        }

        result(ImageHelper.saveImageToAppGroup(
            imageData: imageData,
            fileName: fileName
        ))
    }
}
