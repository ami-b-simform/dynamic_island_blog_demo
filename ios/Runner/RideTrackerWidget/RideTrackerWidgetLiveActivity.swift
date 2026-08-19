//
//  RideTrackerWidgetLiveActivity.swift
//  RideTrackerWidget
//
//  Created by Ami Borsadia on 17/03/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RideTrackerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct RideTrackerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RideTrackerWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension RideTrackerWidgetAttributes {
    fileprivate static var preview: RideTrackerWidgetAttributes {
        RideTrackerWidgetAttributes(name: "World")
    }
}

extension RideTrackerWidgetAttributes.ContentState {
    fileprivate static var smiley: RideTrackerWidgetAttributes.ContentState {
        RideTrackerWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: RideTrackerWidgetAttributes.ContentState {
         RideTrackerWidgetAttributes.ContentState(emoji: "🤩")
     }
}
