import ActivityKit
import Foundation

/// The data contract shared by the app and the widget extension.
///
/// This file lives in `ios/Shared/`, which is added to **both** the `Runner`
/// and `RideTrackerWidgetExtension` targets. There is exactly one copy — if you
/// add a field here, both sides see it on the next build.
struct RideAttributes: ActivityAttributes {
    public typealias RideStatus = ContentState

    // MARK: Static — set once when the activity starts, never changes

    let driverName: String
    let carModel: String
    let plateNumber: String

    /// Absolute path to the driver photo inside the App Group container.
    /// Written by the app via `ImageHelper.saveImageToAppGroup`, read back by
    /// the widget via `ImageHelper.loadImageFromAppGroup`.
    let driverImagePath: String

    // MARK: Dynamic — pushed on every update

    public struct ContentState: Codable, Hashable {
        var distanceKm: Double
        var etaMinutes: Int

        /// Drives colour, icon and progress in the widget.
        /// One of: `preparing` | `pickedup` | `arriving` | `delivered`.
        var stage: String

        /// Human-readable line shown on the Lock Screen and in the
        /// expanded Dynamic Island — e.g. "Driver is arriving".
        var status: String
    }
}
