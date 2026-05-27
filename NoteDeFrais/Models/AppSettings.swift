import Foundation
import Combine

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var restaurantName: String {
        didSet { defaults.set(restaurantName, forKey: Keys.restaurantName) }
    }
    @Published var restaurantAddress: String {
        didSet { defaults.set(restaurantAddress, forKey: Keys.restaurantAddress) }
    }
    @Published var restaurantPhone: String {
        didSet { defaults.set(restaurantPhone, forKey: Keys.restaurantPhone) }
    }
    @Published var siret: String {
        didSet { defaults.set(siret, forKey: Keys.siret) }
    }
    @Published var tvaNumber: String {
        didSet { defaults.set(tvaNumber, forKey: Keys.tvaNumber) }
    }
    @Published var printerTarget: String {
        didSet { defaults.set(printerTarget, forKey: Keys.printerTarget) }
    }
    @Published var printerName: String {
        didSet { defaults.set(printerName, forKey: Keys.printerName) }
    }

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let restaurantName = "restaurantName"
        static let restaurantAddress = "restaurantAddress"
        static let restaurantPhone = "restaurantPhone"
        static let siret = "siret"
        static let tvaNumber = "tvaNumber"
        static let printerTarget = "printerTarget"
        static let printerName = "printerName"
    }

    private init() {
        self.restaurantName = defaults.string(forKey: Keys.restaurantName) ?? ""
        self.restaurantAddress = defaults.string(forKey: Keys.restaurantAddress) ?? ""
        self.restaurantPhone = defaults.string(forKey: Keys.restaurantPhone) ?? ""
        self.siret = defaults.string(forKey: Keys.siret) ?? ""
        self.tvaNumber = defaults.string(forKey: Keys.tvaNumber) ?? ""
        self.printerTarget = defaults.string(forKey: Keys.printerTarget) ?? ""
        self.printerName = defaults.string(forKey: Keys.printerName) ?? ""
    }

    var isPrinterConfigured: Bool {
        !printerTarget.isEmpty
    }

    var isRestaurantConfigured: Bool {
        !restaurantName.isEmpty
    }
}
