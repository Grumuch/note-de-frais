import Foundation

#if canImport(libepos2)
import libepos2

enum ReceiptBuilder {

    private static let lineWidth = 42

    static func build(receipt: Receipt, into printer: Epos2Printer) throws {
        try check(printer.addTextLang(EPOS2_LANG_FR.rawValue))
        try check(printer.addTextSmooth(EPOS2_TRUE))
        try check(printer.addTextFont(EPOS2_FONT_A.rawValue))

        // Header
        try check(printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue))
        try check(printer.addTextSize(2, 2))
        try check(printer.addText(receipt.restaurantName + "\n"))
        try check(printer.addTextSize(1, 1))
        try check(printer.addFeedLine(1))

        if !receipt.restaurantAddress.isEmpty {
            try check(printer.addText(receipt.restaurantAddress + "\n"))
        }
        if !receipt.restaurantPhone.isEmpty {
            try check(printer.addText("Tél. \(receipt.restaurantPhone)\n"))
        }
        if !receipt.siret.isEmpty {
            try check(printer.addText("SIRET : \(receipt.siret)\n"))
        }
        if !receipt.tvaNumber.isEmpty {
            try check(printer.addText("TVA : \(receipt.tvaNumber)\n"))
        }

        try check(printer.addFeedLine(1))
        try check(printer.addText(separator() + "\n"))

        // Title
        try check(printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue))
        try check(printer.addTextStyle(EPOS2_FALSE, EPOS2_FALSE, EPOS2_TRUE, EPOS2_COLOR_1.rawValue))
        try check(printer.addText("NOTE DE FRAIS\n"))
        try check(printer.addTextStyle(EPOS2_FALSE, EPOS2_FALSE, EPOS2_FALSE, EPOS2_COLOR_1.rawValue))
        try check(printer.addText(separator() + "\n"))

        // Date + meal count
        try check(printer.addTextAlign(EPOS2_ALIGN_LEFT.rawValue))
        try check(printer.addText("Date : \(ReceiptFormatter.date.string(from: receipt.date))\n"))
        let mealLabel = receipt.mealCount > 1 ? "\(receipt.mealCount) repas" : "\(receipt.mealCount) repas"
        try check(printer.addText("Prestation : \(mealLabel)\n"))
        try check(printer.addFeedLine(1))

        // VAT breakdown table
        try check(printer.addText(padded(left: "Taux", center: "Base HT", right: "TVA") + "\n"))
        try check(printer.addText(String(repeating: "-", count: lineWidth) + "\n"))
        for line in receipt.nonZeroVatLines {
            try check(printer.addText(padded(
                left: line.ratePercentString,
                center: ReceiptFormatter.amount(line.baseHT) + " €",
                right: ReceiptFormatter.amount(line.tva) + " €"
            ) + "\n"))
        }
        try check(printer.addText(separator() + "\n"))

        // Totals
        try check(printer.addText(twoCol(left: "Total HT", right: ReceiptFormatter.amount(receipt.totalHT) + " €") + "\n"))
        try check(printer.addText(twoCol(left: "Total TVA", right: ReceiptFormatter.amount(receipt.totalTVA) + " €") + "\n"))
        try check(printer.addTextStyle(EPOS2_FALSE, EPOS2_FALSE, EPOS2_TRUE, EPOS2_COLOR_1.rawValue))
        try check(printer.addTextSize(1, 2))
        try check(printer.addText(twoCol(left: "TOTAL TTC", right: ReceiptFormatter.amount(receipt.totalTTC) + " €") + "\n"))
        try check(printer.addTextSize(1, 1))
        try check(printer.addTextStyle(EPOS2_FALSE, EPOS2_FALSE, EPOS2_FALSE, EPOS2_COLOR_1.rawValue))

        try check(printer.addFeedLine(1))
        try check(printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue))
        try check(printer.addText("Merci de votre visite\n"))

        try check(printer.addFeedLine(3))
        try check(printer.addCut(EPOS2_CUT_FEED.rawValue))
    }

    private static func separator() -> String {
        String(repeating: "-", count: lineWidth)
    }

    private static func padded(left: String, center: String, right: String) -> String {
        let col = lineWidth / 3
        let l = left.padding(toLength: col, withPad: " ", startingAt: 0)
        let c = center.padding(toLength: col, withPad: " ", startingAt: 0)
        let r = String(repeating: " ", count: max(0, col - right.count)) + right
        return l + c + r
    }

    private static func twoCol(left: String, right: String) -> String {
        let space = max(1, lineWidth - left.count - right.count)
        return left + String(repeating: " ", count: space) + right
    }

    private static func check(_ result: Int32) throws {
        if result != EPOS2_SUCCESS.rawValue {
            throw PrinterError.buildFailed(result)
        }
    }
}
#endif
