import SwiftUI

struct DiscoveryView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @StateObject private var discovery = PrinterDiscovery()

    var body: some View {
        NavigationStack {
            List {
                if let error = discovery.lastError {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    if discovery.devices.isEmpty {
                        HStack {
                            ProgressView()
                            Text("Recherche en cours…")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ForEach(discovery.devices) { device in
                            Button {
                                settings.printerTarget = device.target
                                settings.printerName = device.name
                                discovery.stop()
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(device.name).font(.headline)
                                    Text(device.ipAddress).font(.footnote).foregroundStyle(.secondary)
                                    Text(device.target).font(.caption).foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Imprimantes détectées")
                } footer: {
                    Text("Si rien n'apparaît, vérifiez que l'imprimante est allumée, connectée au Wi-Fi, et que votre iPhone est sur le même réseau.")
                }
            }
            .navigationTitle("Recherche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        discovery.stop()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        discovery.stop()
                        discovery.start()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear { discovery.start() }
            .onDisappear { discovery.stop() }
        }
    }
}

#Preview {
    DiscoveryView()
        .environmentObject(AppSettings.shared)
}
