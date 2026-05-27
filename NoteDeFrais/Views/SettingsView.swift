import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showDiscovery = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Restaurant") {
                    TextField("Nom du restaurant", text: $settings.restaurantName)
                    TextField("Adresse", text: $settings.restaurantAddress, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Téléphone", text: $settings.restaurantPhone)
                        .keyboardType(.phonePad)
                    TextField("SIRET", text: $settings.siret)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("N° TVA intracom.", text: $settings.tvaNumber)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                }

                Section {
                    HStack {
                        Text("Cible")
                        Spacer()
                        Text(settings.printerTarget.isEmpty ? "Non configurée" : settings.printerTarget)
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                            .multilineTextAlignment(.trailing)
                    }
                    if !settings.printerName.isEmpty {
                        HStack {
                            Text("Nom")
                            Spacer()
                            Text(settings.printerName)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button {
                        showDiscovery = true
                    } label: {
                        Label("Rechercher sur le Wi-Fi", systemImage: "magnifyingglass")
                    }
                    NavigationLink {
                        ManualPrinterView()
                    } label: {
                        Label("Saisir l'IP manuellement", systemImage: "keyboard")
                    }
                    if !settings.printerTarget.isEmpty {
                        Button(role: .destructive) {
                            settings.printerTarget = ""
                            settings.printerName = ""
                        } label: {
                            Label("Oublier l'imprimante", systemImage: "trash")
                        }
                    }
                } header: {
                    Text("Imprimante Epson TM-m30III")
                } footer: {
                    Text("L'iPhone et l'imprimante doivent être sur le même réseau Wi-Fi.")
                }
            }
            .navigationTitle("Réglages")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("OK") { dismiss() }
                        .bold()
                }
            }
            .sheet(isPresented: $showDiscovery) {
                DiscoveryView()
            }
        }
    }
}

struct ManualPrinterView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var ipAddress: String = ""

    var body: some View {
        Form {
            Section {
                TextField("192.168.1.42", text: $ipAddress)
                    .keyboardType(.decimalPad)
                    .autocorrectionDisabled()
            } header: {
                Text("Adresse IP de l'imprimante")
            } footer: {
                Text("Vous la trouvez sur le ticket de configuration de l'imprimante (bouton FEED enfoncé à la mise sous tension).")
            }
            Section {
                Button("Enregistrer") {
                    let trimmed = ipAddress.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    settings.printerTarget = "TCP:" + trimmed
                    if settings.printerName.isEmpty {
                        settings.printerName = "TM-m30III"
                    }
                    dismiss()
                }
                .disabled(ipAddress.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .navigationTitle("Saisie manuelle")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if settings.printerTarget.hasPrefix("TCP:") {
                ipAddress = String(settings.printerTarget.dropFirst(4))
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings.shared)
}
