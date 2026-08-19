import WidgetKit
import SwiftUI

/// The extension's entry point. `RideTrackerLiveActivity` is the Live Activity
/// that drives the Dynamic Island — it is the only one in this project.
@main
struct RideTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        RideTrackerLiveActivity()
    }
}
