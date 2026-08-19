import ActivityKit
import Foundation

struct RideAttributes: ActivityAttributes {
    public typealias RideStatus = ContentState

    // Static — set once at creation, never changes
    let driverName: String
    let carModel: String
    let plateNumber: String
    let driverImagePath: String

    // Dynamic — updated in real time
    public struct ContentState: Codable, Hashable {
        var distanceKm: Double
        var etaMinutes: Int
        var stage: String     // "preparing" | "pickedup" | "arriving" | "delivered"
        var status: String
        var finalMessage: String
    }
}