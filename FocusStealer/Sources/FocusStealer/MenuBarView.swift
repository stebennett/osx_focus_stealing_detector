import SwiftUI
import FocusStealerLib

struct MenuBarView: View {
    @ObservedObject var store: FocusStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Currently focused section
            Section {
                if let current = store.currentAppName {
                    HStack {
                        Text(current)
                            .fontWeight(.medium)
                        Spacer()
                        Text("now")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                } else {
                    Text("None")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            } header: {
                Text("Currently Focused")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }

            Divider()
                .padding(.vertical, 4)

            // Today's usage histogram section
            Section {
                if store.todayTimeByApp.isEmpty {
                    Text("No usage data yet")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                } else {
                    HistogramView(items: store.todayTimeByApp)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            } header: {
                Text("Today's Usage")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
            }

            Divider()
                .padding(.vertical, 4)

            // Recent history section
            Section {
                if store.history.isEmpty {
                    Text("No history yet")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(store.history.prefix(10)) { event in
                                HStack {
                                    Text(event.appName)
                                    Spacer()
                                    Text("\(formatTimeOfDay(event.startTime)) · \(formatDuration(event.duration))")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }
            } header: {
                Text("Recent (today)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
            }

            Divider()
                .padding(.vertical, 4)

            // Quit button
            Button("Quit FocusStealer") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 300)
    }
}
