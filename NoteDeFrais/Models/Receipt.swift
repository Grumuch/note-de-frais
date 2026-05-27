import Foundation

struct VatLine: Identifiable, Equatable {
    let id = UUID()
    let rate: Double
    let baseHT: Double

    var tva: Double { baseHT * rate }
    var totalTTC: Double { baseHT + tva }

    var ratePercentString: String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return (formatter.string(from: NSNumber(value: rate * 100)) ?? "") + " %"
    }
}

struct Receipt {
    let date: Date
    let mealCount: Int
    let vatLines: [VatLine]
    let restaurantName: String
    let restaurantAddress: String
    let restaurantPhone: String
    let siret: String
    let tvaNumber: String

    var totalHT: Double { vatLines.reduce(0) { $0 + $1.baseHT } }
    var totalTVA: Double { vatLines.reduce(0) { $0 + $1.tva } }
    var totalTTC: Double { vatLines.reduce(0) { $0 + $1.totalTTC } }

    var nonZeroVatLines: [VatLine] { vatLines.filter { $0.baseHT > 0 } }
}

enum ReceiptFormatter {
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.numberStyle = .currency
        f.currencyCode = "EUR"
        return f
    }()

    static let plainAmount: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    static let date: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "dd/MM/yyyy HH:mm"
        return f
    }()

    static func euros(_ value: Double) -> String {
        currency.string(from: NSNumber(value: value)) ?? "\(value) €"
    }

    static func amount(_ value: Double) -> String {
        plainAmount.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
