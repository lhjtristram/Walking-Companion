import SwiftUI

struct CoachingSettingsView: View {
    @Environment(UserSettings.self) private var settings

    var body: some View {
        @Bindable var s = settings

        Form {
            Section("Cadence Target") {
                HStack {
                    Text("Target")
                    Spacer()
                    Text("\(settings.cadenceTarget) spm")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $s.cadenceTarget.asDouble, in: 80...160, step: 5)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Guidelines")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Casual walking: 90–110 spm\nBrisk walking: 110–130 spm\nPower walking: 130–160 spm")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Alert Settings") {
                Picker("Alert Type", selection: $s.alertType) {
                    ForEach(UserSettings.AlertType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }

                HStack {
                    Text("Grace Period")
                    Spacer()
                    Text("\(Int(settings.graceInterval))s")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $s.graceInterval, in: 5...60, step: 5)
                Text("How long cadence must be below target before an alert fires.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Audio") {
                Toggle("Auto-play on walk start", isOn: $s.autoPlayOnWalkStart)
            }
        }
        .navigationTitle("Coaching Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Convenience binding adapter Int ↔ Double for Slider
private extension Binding where Value == Int {
    var asDouble: Binding<Double> {
        Binding<Double>(
            get: { Double(wrappedValue) },
            set: { wrappedValue = Int($0) }
        )
    }
}
