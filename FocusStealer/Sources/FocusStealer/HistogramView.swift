import SwiftUI
import FocusStealerLib

struct HistogramView: View {
    let items: [(appName: String, duration: TimeInterval)]

    private var maxDuration: TimeInterval {
        items.map(\.duration).max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 8) {
                    // App name
                    Text(item.appName)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(width: 70, alignment: .leading)

                    // Bar
                    GeometryReader { geometry in
                        let barWidth = (item.duration / maxDuration) * geometry.size.width
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentColor)
                            .frame(width: max(barWidth, 4))
                    }
                    .frame(height: 12)

                    // Duration
                    Text(formatDuration(item.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 55, alignment: .trailing)
                }
                .frame(height: 20)
            }
        }
    }
}
