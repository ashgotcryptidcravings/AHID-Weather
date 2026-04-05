import SwiftUI

struct AlertsView: View {
    let alerts: [WeatherAlert]

    var body: some View {
        VStack(spacing: 8) {
            if alerts.isEmpty {
                Text("ALL CONDITIONS NOMINAL")
                    .font(.system(size: 10, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(ThemeColors.white.opacity(0.2))
                    .frame(maxWidth: .infinity)
                    .padding(12)
            } else {
                ForEach(alerts) { alert in
                    alertBanner(alert)
                }
            }
        }
        .panelStyle()
    }

    private func alertBanner(_ alert: WeatherAlert) -> some View {
        HStack(spacing: 12) {
            Text(alert.icon)
                .font(.system(size: 16))

            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(ThemeColors.white)

                Text(alert.message)
                    .font(.system(size: 10, design: .monospaced))
                    .tracking(1)
                    .foregroundColor(ThemeColors.whiteDim)
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(ThemeColors.void2)
        .overlay(
            Rectangle()
                .fill(borderColor(for: alert.level))
                .frame(width: 3),
            alignment: .leading
        )
        .overlay(
            Rectangle()
                .stroke(ThemeColors.accent.opacity(0.3), lineWidth: 1)
        )
    }

    private func borderColor(for level: WeatherAlert.AlertLevel) -> Color {
        switch level {
        case .info: return ThemeColors.accentBright
        case .warn: return .yellow
        case .danger: return .red
        }
    }
}
