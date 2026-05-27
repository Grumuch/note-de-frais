import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var viewModel = ReceiptViewModel()

    @State private var showSettings = false
    @State private var showPreview = false
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case mealCount, ht55, ht10, ht20
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Repas") {
                    HStack {
                        Text("Nombre de repas")
                        Spacer()
                        TextField("2", value: $viewModel.mealCount, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .mealCount)
                            .frame(width: 80)
                    }
                    DatePicker("Date", selection: $viewModel.date)
                }

                Section {
                    amountRow(label: "TVA 5,5 %", value: $viewModel.ht55, field: .ht55)
                    amountRow(label: "TVA 10 %", value: $viewModel.ht10, field: .ht10)
                    amountRow(label: "TVA 20 %", value: $viewModel.ht20, field: .ht20)
                } header: {
                    Text("Montants HT par taux de TVA")
                } footer: {
                    Text("Laissez à 0 les taux non utilisés.")
                }

                Section("Récapitulatif") {
                    totalRow("Total HT", value: viewModel.totalHT)
                    totalRow("Total TVA", value: viewModel.totalTVA)
                    totalRow("Total TTC", value: viewModel.totalTTC, emphasis: true)
                }

                Section {
                    Button {
                        focusedField = nil
                        showPreview = true
                    } label: {
                        HStack {
                            Image(systemName: "printer.fill")
                            Text("Aperçu & imprimer")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!viewModel.canPrint)
                }
            }
            .navigationTitle("Note de frais")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("OK") { focusedField = nil }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showPreview) {
                ReceiptPreviewView(receipt: viewModel.buildReceipt(settings: settings))
            }
            .onAppear {
                if !settings.isRestaurantConfigured || !settings.isPrinterConfigured {
                    showSettings = true
                }
            }
        }
    }

    @ViewBuilder
    private func amountRow(label: String, value: Binding<Double>, field: Field) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0,00", value: value, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused($focusedField, equals: field)
                .frame(width: 100)
            Text("€")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func totalRow(_ label: String, value: Double, emphasis: Bool = false) -> some View {
        HStack {
            Text(label)
                .fontWeight(emphasis ? .bold : .regular)
            Spacer()
            Text(ReceiptFormatter.euros(value))
                .fontWeight(emphasis ? .bold : .regular)
                .foregroundStyle(emphasis ? Color.primary : Color.secondary)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings.shared)
}
