import Foundation

#if canImport(libepos2)
import libepos2
#endif

struct DiscoveredPrinter: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let target: String
    let ipAddress: String
    let macAddress: String
}

@MainActor
final class PrinterDiscovery: NSObject, ObservableObject {
    @Published var devices: [DiscoveredPrinter] = []
    @Published var isSearching = false
    @Published var lastError: String?

    private var isRunning = false

    func start() {
        #if canImport(libepos2)
        guard !isRunning else { return }
        devices.removeAll()
        lastError = nil
        isSearching = true

        let filter = Epos2FilterOption()
        filter.deviceType = EPOS2_TYPE_PRINTER.rawValue
        filter.portType = EPOS2_PORTTYPE_TCP.rawValue

        let result = Epos2Discovery.start(filter, delegate: self)
        if result != EPOS2_SUCCESS.rawValue {
            isSearching = false
            lastError = "Démarrage de la découverte impossible (code \(result))."
            return
        }
        isRunning = true
        #else
        lastError = "SDK Epson non installé."
        #endif
    }

    func stop() {
        #if canImport(libepos2)
        guard isRunning else { return }
        var result = EPOS2_SUCCESS.rawValue
        repeat {
            result = Epos2Discovery.stop()
        } while result == EPOS2_ERR_PROCESSING.rawValue
        isRunning = false
        isSearching = false
        #endif
    }

    deinit {
        #if canImport(libepos2)
        if isRunning {
            _ = Epos2Discovery.stop()
        }
        #endif
    }
}

#if canImport(libepos2)
extension PrinterDiscovery: Epos2DiscoveryDelegate {
    nonisolated func onDiscovery(_ deviceInfo: Epos2DeviceInfo!) {
        guard let info = deviceInfo else { return }
        let device = DiscoveredPrinter(
            name: info.deviceName ?? "Imprimante",
            target: info.target ?? "",
            ipAddress: info.ipAddress ?? "",
            macAddress: info.macAddress ?? ""
        )
        Task { @MainActor in
            if !self.devices.contains(where: { $0.target == device.target }) {
                self.devices.append(device)
            }
        }
    }
}
#endif
