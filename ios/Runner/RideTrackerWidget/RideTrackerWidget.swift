import ActivityKit
import WidgetKit
import SwiftUI
import UIKit

private let appGroupID = "group.com.example.dynamicIslandFlutter"

private func loadImageFromAppGroup(fileName: String) -> UIImage? {
    guard let container = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    else { return nil }

    let fileURL = container
        .appendingPathComponent("DriverImages")
        .appendingPathComponent(fileName)

    guard let data = try? Data(contentsOf: fileURL) else { return nil }
    return UIImage(data: data)
}

// MARK: - Live Activity Widget

struct RideTrackerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(
            for: RideAttributes.self
        ) { context in
            // Lock Screen / Banner view
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view — user long presses
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                }
            } compactLeading: {
                // Compact left — driver photo
                CompactLeadingView(context: context)
            } compactTrailing: {
                // Compact right — distance or ETA
                CompactTrailingView(context: context)
            } minimal: {
                // Minimal — tiny dot
                MinimalView(context: context)
            }
            .widgetURL(URL(string: "dynamicisland://tracking"))
            .keylineTint(stageColor(context.state.stage))
        }
    }
}

// MARK: - Compact Views

struct CompactLeadingView: View {
    let context: ActivityViewContext<RideAttributes>

    var body: some View {
        if let image = loadImageFromAppGroup(
            fileName: URL(fileURLWithPath:
                context.attributes.driverImagePath
            ).lastPathComponent
        ) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 26, height: 26)
                .clipShape(Circle())
                .padding(.leading, 4)
        } else {
            Image(systemName: "car.fill")
                .foregroundColor(stageColor(context.state.stage))
                .font(.system(size: 14))
                .padding(.leading, 4)
        }
    }
}

struct CompactTrailingView: View {
    let context: ActivityViewContext<RideAttributes>

    var body: some View {
        if context.state.stage == "delivered" {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 14))
                .padding(.trailing, 4)
        } else {
            Text(String(format: "%.1f km",
                context.state.distanceKm))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(stageColor(context.state.stage))
                .padding(.trailing, 4)
        }
    }
}

// MARK: - Minimal View

struct MinimalView: View {
    let context: ActivityViewContext<RideAttributes>

    var body: some View {
        Image(systemName: "car.fill")
            .foregroundColor(stageColor(context.state.stage))
            .font(.system(size: 10))
    }
}

// MARK: - Expanded Views

struct ExpandedLeadingView: View {
    let context: ActivityViewContext<RideAttributes>

    var body: some View {
        HStack(spacing: 8) {
            // Driver photo
            if let image = loadImageFromAppGroup(
                fileName: URL(fileURLWithPath:
                    context.attributes.driverImagePath
                ).lastPathComponent
            ) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                stageColor(context.state.stage),
                                lineWidth: 2
                            )
                    )
            } else {
                Circle()
                    .fill(stageColor(context.state.stage)
                        .opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(
                                stageColor(context.state.stage))
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.driverName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text(context.attributes.carModel)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.leading, 8)
    }
}

struct ExpandedTrailingView: View {
    let context: ActivityViewContext<RideAttributes>

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(String(format: "%.1f km",
                context.state.distanceKm))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(stageColor(context.state.stage))
            Text("\(context.state.etaMinutes) min")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.trailing, 8)
    }
}

struct ExpandedBottomView: View {
    let context: ActivityViewContext<RideAttributes>

    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(stageColor(context.state.stage))
                        .frame(
                            width: geo.size.width * progressValue(
                                context.state.stage),
                            height: 4
                        )
                        .animation(.easeInOut(duration: 0.5),
                            value: context.state.stage)
                }
            }
            .frame(height: 4)

            // Stage label
            HStack {
                Image(systemName: stageIcon(context.state.stage))
                    .foregroundColor(stageColor(context.state.stage))
                    .font(.system(size: 11))
                Text(context.state.status)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                Text(context.attributes.plateNumber)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}

// MARK: - Lock Screen View

struct LockScreenView: View {
    let context: ActivityViewContext<RideAttributes>

    var body: some View {
        HStack(spacing: 14) {
            // Driver photo
            if let image = loadImageFromAppGroup(
                fileName: URL(fileURLWithPath:
                    context.attributes.driverImagePath
                ).lastPathComponent
            ) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                stageColor(context.state.stage),
                                lineWidth: 2
                            )
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.driverName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(context.state.status)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(stageColor(context.state.stage))
                            .frame(
                                width: geo.size.width * progressValue(
                                    context.state.stage),
                                height: 3
                            )
                    }
                }
                .frame(height: 3)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f",
                    context.state.distanceKm))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(stageColor(context.state.stage))
                Text("km away")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.85))
    }
}

// MARK: - Placeholder Widget (required)

struct RideTrackerWidget: Widget {
    let kind: String = "RideTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { _ in
            Text("Ride Tracker")
        }
        .configurationDisplayName("Ride Tracker")
        .description("Live ride tracking in Dynamic Island")
        .supportedFamilies([.systemSmall])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }
    func getSnapshot(in context: Context,
        completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }
    func getTimeline(in context: Context,
        completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        completion(Timeline(entries: [SimpleEntry(date: Date())],
            policy: .never))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

// MARK: - Helpers

func stageColor(_ stage: String) -> Color {
    switch stage {
    case "preparing":  return Color(red: 0.42, green: 0.28, blue: 1.0)
    case "pickedup":   return Color(red: 0.04, green: 0.52, blue: 1.0)
    case "arriving":   return Color(red: 1.0,  green: 0.62, blue: 0.04)
    case "delivered":  return Color(red: 0.19, green: 0.82, blue: 0.35)
    default:           return .white
    }
}

func stageIcon(_ stage: String) -> String {
    switch stage {
    case "preparing":  return "clock.fill"
    case "pickedup":   return "bag.fill"
    case "arriving":   return "location.fill"
    case "delivered":  return "checkmark.circle.fill"
    default:           return "car.fill"
    }
}

func progressValue(_ stage: String) -> Double {
    switch stage {
    case "preparing":  return 0.25
    case "pickedup":   return 0.55
    case "arriving":   return 0.80
    case "delivered":  return 1.0
    default:           return 0.0
    }
}
