import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

// MARK: - DeviceInfo

internal class DeviceInfo {
    /// Hardware model identifier, e.g. "iPhone15,2", "MacBookPro18,3", "AppleTV14,1".
    static var hardwareModel: String {
        // Simulators report the simulator's own hardware; the simulated device is in the environment.
        if let simulatorModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulatorModel
        }
        #if os(macOS)
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        guard size > 0 else { return "Mac" }
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &buffer, &size, nil, 0)
        return String(cString: buffer)
        #else
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafeBytes(of: &systemInfo.machine) { buffer -> String in
            guard let base = buffer.baseAddress else { return "" }
            return String(cString: base.assumingMemoryBound(to: CChar.self))
        }
        return machine.isEmpty ? "Apple" : machine
        #endif
    }

    static func getUserAgent() -> String {
        // The Model=/Manufacturer= form is recognized by the OpenPanel backend as
        // app traffic, so it is not classified as a server/bot request.
        return "OpenPanel/\(OpenPanel.sdkVersion) (Model=\(hardwareModel); Manufacturer=Apple)"
    }

    static var osName: String {
        // Names must match ua-parser-js v2 vocabulary so app traffic shares
        // dashboard buckets with web traffic ("macOS", not "Mac OS").
        #if os(iOS)
        return "iOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(watchOS)
        return "watchOS"
        #elseif os(macOS)
        return "macOS"
        #else
        return "Unknown"
        #endif
    }

    static var osVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    static var deviceType: String {
        // Must match ua-parser-js v2 device types.
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? "tablet" : "mobile"
        #elseif os(tvOS)
        return "smarttv"
        #elseif os(watchOS)
        return "wearable"
        #else
        return "desktop"
        #endif
    }

    /// Property overrides the backend prefers over user-agent parsing.
    static func deviceProperties() -> [String: Any] {
        return [
            "__os": osName,
            "__osVersion": osVersion,
            "__device": deviceType,
            "__brand": "Apple",
            "__model": hardwareModel,
        ]
    }
}

// MARK: - Payload Types

public enum TrackHandlerPayload: Codable {
    case track(TrackPayload)
    case increment(IncrementPayload)
    case decrement(DecrementPayload)
    case alias(AliasPayload)
    case identify(IdentifyPayload)
    
    private enum CodingKeys: String, CodingKey {
        case type, payload
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .track(let payload):
            try container.encode("track", forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .increment(let payload):
            try container.encode("increment", forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .decrement(let payload):
            try container.encode("decrement", forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .alias(let payload):
            try container.encode("alias", forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .identify(let payload):
            try container.encode("identify", forKey: .type)
            try container.encode(payload, forKey: .payload)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "track":
            self = .track(try container.decode(TrackPayload.self, forKey: .payload))
        case "increment":
            self = .increment(try container.decode(IncrementPayload.self, forKey: .payload))
        case "decrement":
            self = .decrement(try container.decode(DecrementPayload.self, forKey: .payload))
        case "alias":
            self = .alias(try container.decode(AliasPayload.self, forKey: .payload))
        case "identify":
            self = .identify(try container.decode(IdentifyPayload.self, forKey: .payload))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type")
        }
    }
}

public struct TrackPayload: Codable {
    public let name: String
    public var properties: [String: AnyCodable]?
    public var profileId: String?
    
    public init(name: String, properties: [String: AnyCodable]? = nil, profileId: String? = nil) {
        self.name = name
        self.properties = properties
        self.profileId = profileId
    }
}

public typealias TrackProperties = [String: Any]

extension AnyCodable:
    ExpressibleByStringLiteral,
    ExpressibleByBooleanLiteral,
    ExpressibleByIntegerLiteral,
    ExpressibleByFloatLiteral,
    ExpressibleByArrayLiteral,
    ExpressibleByDictionaryLiteral
{
    public init(stringLiteral value: String) {
        self = AnyCodable(value)
    }

    public init(booleanLiteral value: Bool) {
        self = AnyCodable(value)
    }

    public init(integerLiteral value: Int) {
        self = AnyCodable(value)
    }

    public init(floatLiteral value: Double) {
        self = AnyCodable(value)
    }

    public init(arrayLiteral elements: AnyCodable...) {
        self = AnyCodable(elements)
    }

    public init(dictionaryLiteral elements: (String, AnyCodable)...) {
        let dict = Dictionary(elements, uniquingKeysWith: { first, _ in first })
        self = AnyCodable(dict)
    }
}

public struct IdentifyPayload: Codable {
    public let profileId: String
    public var firstName: String?
    public var lastName: String?
    public var email: String?
    public var avatar: String?
    public var properties: [String: AnyCodable]?
    
    public init(profileId: String, firstName: String? = nil, lastName: String? = nil, email: String? = nil, avatar: String? = nil, properties: [String: AnyCodable]? = nil) {
        self.profileId = profileId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.avatar = avatar
        self.properties = properties
    }
}

public struct AliasPayload: Codable {
    public let profileId: String
    public let alias: String
    
    public init(profileId: String, alias: String) {
        self.profileId = profileId
        self.alias = alias
    }
}

public struct IncrementPayload: Codable {
    public let profileId: String
    public let property: String
    public var value: Int?
    
    public init(profileId: String, property: String, value: Int? = nil) {
        self.profileId = profileId
        self.property = property
        self.value = value
    }
}

public struct DecrementPayload: Codable {
    public let profileId: String
    public let property: String
    public var value: Int?
    
    public init(profileId: String, property: String, value: Int? = nil) {
        self.profileId = profileId
        self.property = property
        self.value = value
    }
}

// MARK: - AnyCodable

public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self.value = value
        } else if let value = try? container.decode(Int.self) {
            self.value = value
        } else if let value = try? container.decode(Double.self) {
            self.value = value
        } else if let value = try? container.decode(Bool.self) {
            self.value = value
        } else if let value = try? container.decode([AnyCodable].self) {
            self.value = value.map { $0.value }
        } else if let value = try? container.decode([String: AnyCodable].self) {
            self.value = value.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let value as String:
            try container.encode(value)
        case let value as Int:
            try container.encode(value)
        case let value as Double:
            try container.encode(value)
        case let value as Bool:
            try container.encode(value)
        case let value as [AnyCodable]:
            try container.encode(value)
        case let value as [String: AnyCodable]:
            try container.encode(value)
        case let value as [Any]:
            try container.encode(value.map { AnyCodable($0) })
        case let value as [String: Any]:
            try container.encode(value.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
}

// MARK: - OpenPanel Class

public class OpenPanel {
    public static let shared = OpenPanel()
    
    private let api: Api
    private var profileId: String?
    private let globalQueue = DispatchQueue(label: "com.openpanel.globalQueue", attributes: .concurrent)
    private var _global: [String: Any]?
    private var global: [String: Any]? {
        get { globalQueue.sync { _global } }
        set { globalQueue.async(flags: .barrier) { self._global = newValue } }
    }
    private var queue: [TrackHandlerPayload] = []
    // Tail of the in-flight send chain; each new send awaits the previous one
    // so events reach the server in the order they were tracked.
    private var sendTask: Task<Void, Never>?
    
    public struct Options {
        public let clientId: String
        public var clientSecret: String?
        public var apiUrl: String?
        public var waitForProfile: Bool?
        public var filter: ((TrackHandlerPayload) -> Bool)?
        public var disabled: Bool?
        public var automaticTracking: Bool?
        
        public init(clientId: String, clientSecret: String? = nil, apiUrl: String? = nil, waitForProfile: Bool? = nil, filter: ((TrackHandlerPayload) -> Bool)? = nil, disabled: Bool? = nil, automaticTracking: Bool? = nil) {
            self.clientId = clientId
            self.clientSecret = clientSecret
            self.apiUrl = apiUrl
            self.waitForProfile = waitForProfile
            self.filter = filter
            self.disabled = disabled
            self.automaticTracking = automaticTracking
        }
    }
    
    private var options: Options?
    
    public static var sdkVersion: String {
        return "1.0.1"
    }
    
    private init() {
        self.api = Api(config: Api.Config(baseUrl: "https://api.openpanel.dev"))
    }
    
    public static func initialize(options: Options) {
        shared.options = options

        let deviceDefaults = DeviceInfo.deviceProperties()
        shared.globalQueue.async(flags: .barrier) {
            // Device defaults sit under any user-set globals so explicit
            // setGlobalProperties values always win.
            var merged = deviceDefaults
            if let existing = shared._global {
                merged.merge(existing) { _, user in user }
            }
            shared._global = merged
        }

        var defaultHeaders: [String: String] = [
            "openpanel-client-id": options.clientId,
            "openpanel-sdk-name": "swift",
            "openpanel-sdk-version": OpenPanel.sdkVersion,
            "user-agent": DeviceInfo.getUserAgent(),
        ]
        
        if let clientSecret = options.clientSecret {
            defaultHeaders["openpanel-client-secret"] = clientSecret
        }
        
        shared.api.updateConfig(Api.Config(
            baseUrl: options.apiUrl ?? "https://api.openpanel.dev",
            defaultHeaders: defaultHeaders
        ))

        if options.automaticTracking == true {
            shared.setupAutomaticTracking()
        }
    }
    
    public static func ready() {
        shared.options?.waitForProfile = false
        shared.flush()
    }
    
    private func send(_ payload: TrackHandlerPayload) {
        guard let options = self.options else {
            logError("OpenPanel not initialized. Call OpenPanel.initialize() first.")
            return
        }
        
        if options.disabled == true {
            return
        }
        
        if let filter = options.filter, !filter(payload) {
            return
        }
        
        if options.waitForProfile == true, profileId == nil {
            globalQueue.async(flags: .barrier) {
                self.queue.append(payload)
            }
            return
        }
        
        let updatedPayload = ensureProfileId(payload)
        globalQueue.async(flags: .barrier) {
            let previous = self.sendTask
            self.sendTask = Task {
                await previous?.value
                let result = await self.api.fetch(path: "/track", data: updatedPayload)
                switch result {
                case .success:
                    break
                case .failure(let error):
                    self.logError("Error sending payload: \(error)")
                }
            }
        }
    }
    
    private func ensureProfileId(_ payload: TrackHandlerPayload) -> TrackHandlerPayload {
        switch payload {
        case .track(var trackPayload):
            if trackPayload.profileId == nil {
                trackPayload.profileId = self.profileId
            }
            return .track(trackPayload)
        default:
            return payload
        }
    }
    
    public static func setGlobalProperties(_ properties: [String: Any]) {
        shared.globalQueue.async(flags: .barrier) {
            if var global = shared._global {
                for (key, value) in properties {
                    global[key] = value
                }
                shared._global = global
            } else {
                shared._global = properties
            }
        }
    }
    
    public static func track(name: String, properties: TrackProperties? = nil) {
        let mergedProperties = shared.globalQueue.sync {
            var merged = shared._global ?? [:]
            if let properties = properties {
                merged.merge(properties) { (_, new) in new }
            }
            return merged
        }
        let payload = TrackPayload(
            name: name,
            properties: mergedProperties.mapValues { AnyCodable($0) },
            profileId: properties?["profileId"] as? String ?? shared.profileId
        )
        shared.send(.track(payload))
    }
    
    public static func identify(payload: IdentifyPayload) {
        shared.profileId = payload.profileId
        shared.flush()
        
        if payload.firstName != nil || payload.lastName != nil || payload.email != nil || payload.avatar != nil || !(payload.properties?.isEmpty ?? true) {
            var updatedPayload = payload
            shared.globalQueue.sync {
                if let global = shared._global {
                    var mergedProperties = global
                    if let payloadProperties = payload.properties {
                        mergedProperties.merge(payloadProperties) { (_, new) in (new as? AnyCodable)?.value ?? new }
                    }
                    updatedPayload.properties = mergedProperties.mapValues { AnyCodable($0) }
                }
            }
            shared.send(.identify(updatedPayload))
        }
    }
    
    public static func alias(payload: AliasPayload) {
        shared.send(.alias(payload))
    }
    
    public static func increment(payload: IncrementPayload) {
        shared.send(.increment(payload))
    }
    
    public static func decrement(payload: DecrementPayload) {
        shared.send(.decrement(payload))
    }
    
    public static func clear() {
        shared.profileId = nil
        // Wipe user-set globals but keep the device defaults seeded at initialize.
        let deviceDefaults = shared.options != nil ? DeviceInfo.deviceProperties() : nil
        shared.globalQueue.async(flags: .barrier) {
            shared._global = deviceDefaults
        }
    }
    
    public func flush() {
        let currentQueue = globalQueue.sync(flags: .barrier) { () -> [TrackHandlerPayload] in
            let items = queue
            queue.removeAll()
            return items
        }
        for item in currentQueue {
            send(item)
        }
    }
    
    public static func flush() {
        shared.flush()
    }

    
    private func setupAutomaticTracking() {
        #if os(iOS) || os(tvOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sceneDidActivate),
            name: UIScene.didActivateNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sceneDidEnterBackground),
            name: UIScene.didEnterBackgroundNotification,
            object: nil
        )
        #elseif os(macOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
        #elseif os(watchOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: WKExtension.applicationDidBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: WKExtension.applicationDidEnterBackgroundNotification,
            object: nil
        )
        #endif
    }

    #if os(iOS) || os(tvOS)
    @objc private func sceneDidActivate(_ notification: Notification) {
        guard let scene = notification.object as? UIScene,
            scene.activationState == .foregroundActive,
            UIApplication.shared.connectedScenes.filter({ $0.activationState == .foregroundActive }).count == 1 else {
            return
        }
        OpenPanel.track(name: "app_opened")
    }

    @objc private func sceneDidEnterBackground(_ notification: Notification) {
        guard UIApplication.shared.connectedScenes.filter({ $0.activationState != .background }).isEmpty else {
            return
        }
        OpenPanel.track(name: "app_closed")
    }
    #elseif os(macOS)
    @objc private func appDidBecomeActive() {
        OpenPanel.track(name: "app_opened")
    }

    @objc private func appWillTerminate() {
        OpenPanel.track(name: "app_closed")
    }
    #elseif os(watchOS)
    @objc private func appDidBecomeActive() {
        OpenPanel.track(name: "app_opened")
    }

    @objc private func appDidEnterBackground() {
        OpenPanel.track(name: "app_closed")
    }
    #endif

    private func logError(_ message: String) {
        print("OpenPanel Error: \(message)")
    }
}

// MARK: - Api Class

internal class Api {
    private var baseUrl: String
    private var headers: [String: String]
    private var maxRetries: Int
    private var initialRetryDelay: TimeInterval
    
    struct Config {
        let baseUrl: String
        var defaultHeaders: [String: String]?
        var maxRetries: Int?
        var initialRetryDelay: TimeInterval?
    }
    
    init(config: Config) {
        self.baseUrl = config.baseUrl
        self.headers = config.defaultHeaders ?? [:]
        self.headers["Content-Type"] = "application/json"
        self.maxRetries = config.maxRetries ?? 3
        self.initialRetryDelay = config.initialRetryDelay ?? 0.5
    }
    
    func updateConfig(_ config: Config) {
        self.baseUrl = config.baseUrl
        self.headers = config.defaultHeaders ?? [:]
        self.headers["Content-Type"] = "application/json"
        self.maxRetries = config.maxRetries ?? 3
        self.initialRetryDelay = config.initialRetryDelay ?? 0.5
    }
    
    func addHeader(key: String, value: String) {
        headers[key] = value
    }
    
    private func post<T: Codable>(url: URL, data: T, options: [String: Any] = [:], attempt: Int = 0) async -> Result<Data, Error> {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        
        do {
            request.httpBody = try JSONEncoder().encode(data)
        } catch {
            return .failure(error)
        }
        
        for (key, value) in options {
            if let stringValue = value as? String {
                request.setValue(stringValue, forHTTPHeaderField: key)
            }
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(NSError(domain: "HTTPError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                return .failure(NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"]))
            }
            
            return .success(data)
        } catch {
            if attempt < maxRetries {
                let delay = initialRetryDelay * pow(2.0, Double(attempt))
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return await post(url: url, data: data, options: options, attempt: attempt + 1)
            }
            return .failure(error)
        }
    }
    
    func fetch<T: Codable>(path: String, data: T, options: [String: Any] = [:]) async -> Result<Data, Error> {
        guard let url = URL(string: baseUrl + path) else {
            return .failure(NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
        }
        return await post(url: url, data: data, options: options)
    }
}
