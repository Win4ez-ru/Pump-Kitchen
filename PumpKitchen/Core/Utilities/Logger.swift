import OSLog

enum LoggerProvider {
    static let app = Logger(subsystem: "PumpKitchen", category: "App")
}

