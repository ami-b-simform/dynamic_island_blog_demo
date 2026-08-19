import ActivityKit
import Foundation

struct RideAttributes: ActivityAttributes {
    public typealias RideStatus = ContentState

    // Static attributes for an activity.
    let driverName: String
    let carModel: String
    let plateNumber: String
    let driverImagePath: String

    // Dynamic state that can be updated.
    public struct ContentState: Codable, Hashable {
        var distanceKm: Double
        var etaMinutes: Int
        var stage: String
        var status: String
        var finalMessage: String
    }
}
