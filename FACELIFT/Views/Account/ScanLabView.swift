import SwiftUI

/// Debug-only: pick how scans are read, then scan several times without moving and compare
/// how much each score wobbles.
struct ScanLabView: View {
    @State private var lab = ScanLab.shared
    @State private var viewing: ScanLab.Mode = ScanLab.shared.mode

    var body: some View {
        List {
            Section {
                Picker("Read scans with", selection: $lab.mode) {
                    ForEach(ScanLab.Mode.allCases) { mode in
                        Text("\(mode.title) (\(mode.costNote))").tag(mode)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("Read scans with")
            } footer: {
                Text("For the steadiness test: scan 5 times in a row in the same spot and light, without moving. Then check the spread below.")
            }

            Section {
                Picker("Show results for", selection: $viewing) {
                    ForEach(ScanLab.Mode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                let count = lab.runs.filter { $0.mode == viewing }.count
                let rows = lab.spread(for: viewing)
                if rows.isEmpty {
                    Text("No scans with this setup yet.")
                        .foregroundStyle(.secondary)
                } else {
                    let average = Double(rows.map { $0.high - $0.low }.reduce(0, +)) / Double(rows.count)
                    LabeledContent("Scans", value: "\(count)")
                    LabeledContent("Average spread", value: String(format: "%.1f points", average))
                    ForEach(rows, id: \.marker) { row in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.marker.replacingOccurrences(of: "_", with: " ").capitalized)
                                Text(row.source == "youcam" ? "YouCam" : "Claude")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(row.low) to \(row.high)")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                            Text("±\(row.high - row.low)")
                                .monospacedDigit()
                                .fontWeight(.semibold)
                                .foregroundStyle(row.high - row.low > 6 ? .red : .primary)
                                .frame(width: 44, alignment: .trailing)
                        }
                    }
                }
            } header: {
                Text("Steadiness")
            } footer: {
                Text("Spread is the highest score minus the lowest across scans. Red means it moved more than 6 points.")
            }

            if lab.runs.contains(where: \.youcamFailed) {
                Section {
                    Text("Some scans couldn't reach YouCam (often out of units), so Claude read every marker on those.")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Clear test results", role: .destructive) { lab.clear() }
            }
        }
        .navigationTitle("Scan Lab")
        .navigationBarTitleDisplayMode(.inline)
    }
}
