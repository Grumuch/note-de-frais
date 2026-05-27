import Foundation
import Combine

@MainActor
final class ReceiptViewModel: ObservableObject {
    @Published var date: Date = Date()
    @Published var mealCount: Int = 2
    @Published var ht55: Double = 0
    @Published var ht10: Double = 0
    @Published var ht20: Double = 0

    var totalHT: Double { ht55 + ht10 + ht20 }
    var totalTVA: Double { ht55 * 0.055 + ht10 * 0.10 + ht20 * 0.20 }
    var totalTTC: Double { totalHT + totalTVA }

    var canPrint: Bool {
        mealCount > 0 && totalHT > 0
    }

    func buildReceipt(settings: AppSettings) -> Receipt {
        let lines = [
            VatLine(rate: 0.055, baseHT: ht55),
            VatLine(rate: 0.10, baseHT: ht10),
            VatLine(rate: 0.20, baseHT: ht20)
        ]
        return Receipt(
            date: date,
            mealCount: mealCount,
            vatLines: lines,
            restaurantName: settings.restaurantName,
            restaurantAddress: settings.restaurantAddress,
            restaurantPhone: settings.restaurantPhone,
            siret: settings.siret,
            tvaNumber: settings.tvaNumber
        )
    }

    func reset() {
        date = Date()
        mealCount = 2
        ht55 = 0
        ht10 = 0
        ht20 = 0
    }
}
