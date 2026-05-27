import SwiftUI

struct ReceiptPreviewView: View {
    let receipt: Receipt

    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var isPrinting = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private let printer = PrinterService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    receiptCard
                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
                    if let successMessage {
                        Label(successMessage, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Aperçu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await print() }
                    } label: {
                        if isPrinting {
                            ProgressView()
                        } else {
                            Label("Imprimer", systemImage: "printer.fill")
                        }
                    }
                    .disabled(isPrinting || !settings.isPrinterConfigured)
                }
            }
        }
    }

    private var receiptCard: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(receipt.restaurantName.isEmpty ? "Nom du restaurant" : receipt.restaurantName)
                .font(.title3.bold())
            if !receipt.restaurantAddress.isEmpty {
                Text(receipt.restaurantAddress)
                    .multilineTextAlignment(.center)
                    .font(.footnote)
            }
            if !receipt.restaurantPhone.isEmpty {
                Text("Tél. \(receipt.restaurantPhone)")
                    .font(.footnote)
            }
            if !receipt.siret.isEmpty {
                Text("SIRET : \(receipt.siret)")
                    .font(.footnote)
            }
            if !receipt.tvaNumber.isEmpty {
                Text("TVA : \(receipt.tvaNumber)")
                    .font(.footnote)
            }

            Divider().padding(.vertical, 6)
            Text("NOTE DE FRAIS")
                .font(.headline)
            Divider().padding(.vertical, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text("Date : \(ReceiptFormatter.date.string(from: receipt.date))")
                Text("Prestation : \(receipt.mealCount) repas")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.footnote)
            .padding(.vertical, 4)

            VStack(spacing: 2) {
                HStack {
                    Text("Taux").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Base HT").frame(maxWidth: .infinity, alignment: .center)
                    Text("TVA").frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.footnote.bold())
                Divider()
                ForEach(receipt.nonZeroVatLines) { line in
                    HStack {
                        Text(line.ratePercentString).frame(maxWidth: .infinity, alignment: .leading)
                        Text(ReceiptFormatter.amount(line.baseHT) + " €").frame(maxWidth: .infinity, alignment: .center)
                        Text(ReceiptFormatter.amount(line.tva) + " €").frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .font(.footnote)
                }
            }
            .padding(.vertical, 6)

            Divider()
            totalRow("Total HT", value: receipt.totalHT)
            totalRow("Total TVA", value: receipt.totalTVA)
            totalRow("TOTAL TTC", value: receipt.totalTTC, bold: true)
            Divider().padding(.vertical, 4)
            Text("Merci de votre visite")
                .font(.footnote.italic())
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal)
        .foregroundStyle(Color.black)
    }

    @ViewBuilder
    private func totalRow(_ label: String, value: Double, bold: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(ReceiptFormatter.euros(value))
        }
        .font(bold ? .body.bold() : .footnote)
    }

    private func print() async {
        guard settings.isPrinterConfigured else {
            errorMessage = "Configurez d'abord l'imprimante dans les réglages."
            return
        }
        isPrinting = true
        errorMessage = nil
        successMessage = nil
        do {
            try await printer.printReceipt(receipt, target: settings.printerTarget)
            successMessage = "Ticket envoyé à l'imprimante."
        } catch {
            errorMessage = error.localizedDescription
        }
        isPrinting = false
    }
}

#Preview {
    let sample = Receipt(
        date: Date(),
        mealCount: 2,
        vatLines: [
            VatLine(rate: 0.10, baseHT: 22.0),
            VatLine(rate: 0.20, baseHT: 4.0)
        ],
        restaurantName: "Restaurant Le Gourmet",
        restaurantAddress: "12 rue de la Paix\n75002 Paris",
        restaurantPhone: "01 23 45 67 89",
        siret: "123 456 789 00012",
        tvaNumber: "FR12 345678900"
    )
    return ReceiptPreviewView(receipt: sample)
        .environmentObject(AppSettings.shared)
}
