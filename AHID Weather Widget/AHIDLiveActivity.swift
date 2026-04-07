#if os(iOS)
import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Widget

struct AHIDLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AHIDActivityAttributes.self) { context in
            AHIDLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading)  { AHIDExpandedLeading(context: context) }
                DynamicIslandExpandedRegion(.trailing) { AHIDExpandedTrailing(context: context) }
                DynamicIslandExpandedRegion(.bottom)   { AHIDExpandedBottom(context: context) }
            } compactLeading: {
                AHIDCompactLeading(context: context)
            } compactTrailing: {
                AHIDCompactTrailing(context: context)
            } minimal: {
                AHIDMinimal(context: context)
            }
        }
    }
}

// MARK: - Dynamic Island — Compact

private struct AHIDCompactLeading: View {
    let context: ActivityViewContext<AHIDActivityAttributes>
    var body: some View {
        Image(systemName: context.state.icon)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(context.state.level.color)
    }
}

private struct AHIDCompactTrailing: View {
    let context: ActivityViewContext<AHIDActivityAttributes>
    var body: some View {
        Text(context.state.title)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundColor(context.state.level.color)
            .lineLimit(1)
    }
}

// MARK: - Dynamic Island — Minimal

private struct AHIDMinimal: View {
    let context: ActivityViewContext<AHIDActivityAttributes>
    var body: some View {
        Image(systemName: context.state.icon)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(context.state.level.color)
    }
}

// MARK: - Dynamic Island — Expanded

private struct AHIDExpandedLeading: View {
    let context: ActivityViewContext<AHIDActivityAttributes>
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: context.state.icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(context.state.level.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.locationName)
                    .font(.system(size: 8, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                Text(context.state.title)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(context.state.level.color)
                    .lineLimit(1)
            }
        }
        .padding(.leading, 6)
    }
}

private struct AHIDExpandedTrailing: View {
    let context: ActivityViewContext<AHIDActivityAttributes>
    var body: some View {
        Text(context.state.updatedAt, style: .time)
            .font(.system(size: 9, design: .monospaced))
            .foregroundColor(.white.opacity(0.35))
            .padding(.trailing, 6)
    }
}

private struct AHIDExpandedBottom: View {
    let context: ActivityViewContext<AHIDActivityAttributes>
    var body: some View {
        Text(context.state.body)
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(.white.opacity(0.75))
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
    }
}

// MARK: - Lock Screen Banner

private struct AHIDLockScreenView: View {
    let context: ActivityViewContext<AHIDActivityAttributes>
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: context.state.icon)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(context.state.level.color)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(context.attributes.locationName)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.white.opacity(0.45))
                    Spacer()
                    Text(context.state.updatedAt, style: .time)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.white.opacity(0.35))
                }
                Text(context.state.title)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(context.state.level.color)
                Text(context.state.body)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(Color(red: 0.07, green: 0.05, blue: 0.11))
    }
}
#endif
