import Foundation

#if canImport(libepos2)
import libepos2
#endif

enum PrinterError: LocalizedError {
    case sdkUnavailable
    case initFailed(Int32)
    case connectFailed(Int32)
    case sendFailed(Int32)
    case buildFailed(Int32)
    case statusError(String)

    var errorDescription: String? {
        switch self {
        case .sdkUnavailable:
            return "SDK Epson non installé. Voir le README pour ajouter libepos2.xcframework au projet."
        case .initFailed(let code):
            return "Initialisation imprimante impossible (code \(code))."
        case .connectFailed(let code):
            return "Connexion impossible à l'imprimante (code \(code)). Vérifiez l'IP et que l'iPhone est sur le même Wi-Fi."
        case .sendFailed(let code):
            return "Envoi du ticket échoué (code \(code))."
        case .buildFailed(let code):
            return "Erreur lors de la construction du ticket (code \(code))."
        case .statusError(let msg):
            return "Imprimante en erreur : \(msg)"
        }
    }
}

final class PrinterService {

    func printReceipt(_ receipt: Receipt, target: String) async throws {
        #if canImport(libepos2)
        try await Task.detached(priority: .userInitiated) {
            try self.printReceiptSync(receipt, target: target)
        }.value
        #else
        throw PrinterError.sdkUnavailable
        #endif
    }

    #if canImport(libepos2)
    private func printReceiptSync(_ receipt: Receipt, target: String) throws {
        guard let printer = Epos2Printer(printerSeries: EPOS2_TM_M30III.rawValue, lang: EPOS2_MODEL_ANK.rawValue) else {
            throw PrinterError.initFailed(-1)
        }

        defer {
            printer.disconnect()
            printer.clearCommandBuffer()
            printer.setReceiveEventDelegate(nil)
        }

        try ReceiptBuilder.build(receipt: receipt, into: printer)

        let connectResult = printer.connect(target, timeout: Int(EPOS2_PARAM_DEFAULT))
        guard connectResult == EPOS2_SUCCESS.rawValue else {
            throw PrinterError.connectFailed(connectResult)
        }

        let beginResult = printer.beginTransaction()
        if beginResult != EPOS2_SUCCESS.rawValue {
            throw PrinterError.connectFailed(beginResult)
        }

        let sendResult = printer.sendData(Int(EPOS2_PARAM_DEFAULT))
        if sendResult != EPOS2_SUCCESS.rawValue {
            printer.endTransaction()
            throw PrinterError.sendFailed(sendResult)
        }

        printer.endTransaction()
    }
    #endif
}
