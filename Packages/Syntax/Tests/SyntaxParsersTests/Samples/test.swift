import Foundation

// MARK: - Protocols

protocol Identifiable {
    associatedtype ID: Hashable
    var id: ID { get }
}

protocol Displayable {
    func display() -> String
}

extension Displayable {
    func summary() -> String {
        "[\(Self.self): \(display())]"
    }
}

// MARK: - Enums

enum Status: String, CaseIterable, Sendable {
    case active, inactive, pending

    var label: String {
        rawValue.capitalized
    }
}

enum AppError: Error, LocalizedError {
    case notFound(id: Int)
    case validation(field: String, message: String)
    case network(underlying: any Error)

    var errorDescription: String? {
        switch self {
            case .notFound(let id):
                "Item \(id) not found"
            case .validation(let field, let message):
                "\(field): \(message)"
            case .network(let underlying):
                "Network error: \(underlying.localizedDescription)"
        }
    }
}

// MARK: - Data Types

struct User: Identifiable, Displayable, Sendable {
    let id: Int
    var name: String
    var email: String
    var status: Status

    func display() -> String {
        "\(name) <\(email)> [\(status.label)]"
    }

    func validate() throws {
        guard name.count >= 2 else {
            throw AppError.validation(field: "name", message: "too short")
        }
        guard email.contains("@") else {
            throw AppError.validation(field: "email", message: "invalid format")
        }
    }
}

struct Pair<A, B> {
    var first: A
    var second: B

    func map<C>(_ transform: (B) -> C) -> Pair<A, C> {
        Pair<A, C>(first: first, second: transform(second))
    }
}

// MARK: - Actor

actor UserStore {
    private var users: [Int: User] = [:]

    var count: Int { users.count }

    func insert(_ user: User) {
        users[user.id] = user
    }

    func find(by id: Int) throws -> User {
        guard let user = users[id] else {
            throw AppError.notFound(id: id)
        }
        return user
    }

    func all() -> [User] {
        users.values.sorted { $0.id < $1.id }
    }
}

// MARK: - Class

class Logger: @unchecked Sendable {
    static let shared = Logger()

    private let queue = DispatchQueue(label: "logger")
    private var entries: [String] = []

    private init() {}

    func log(_ message: String, level: String = "INFO") {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let entry = "[\(timestamp)] [\(level)] \(message)"
        queue.sync {
            entries.append(entry)
            print(entry)
        }
    }
}

// MARK: - Property Wrappers & Result Builders

@propertyWrapper
struct Clamped<Value: Comparable> {
    private var value: Value
    let range: ClosedRange<Value>

    var wrappedValue: Value {
        get { value }
        set { value = min(max(newValue, range.lowerBound), range.upperBound) }
    }

    init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.range = range
        self.value = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }
}

@resultBuilder
struct ArrayBuilder<Element> {
    static func buildBlock(_ components: Element...) -> [Element] {
        components
    }

    static func buildOptional(_ component: [Element]?) -> [Element] {
        component ?? []
    }

    static func buildEither(first component: [Element]) -> [Element] {
        component
    }

    static func buildEither(second component: [Element]) -> [Element] {
        component
    }
}

// MARK: - Extensions & Generics

extension Sequence where Element: Displayable {
    func descriptions() -> [String] {
        map { $0.display() }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

func fetch<T: Decodable & Sendable>(
    _ type: T.Type,
    from url: URL
) async throws -> T {
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let http = response as? HTTPURLResponse,
          (200..<300).contains(http.statusCode)
    else {
        throw AppError.network(underlying: URLError(.badServerResponse))
    }

    return try JSONDecoder().decode(type, from: data)
}

// MARK: - Pattern Matching

func classify(_ value: some Any) -> String {
    switch value {
        case let n as Int where n > 0:
            "positive(\(n))"
        case let n as Int:
            "non-positive(\(n))"
        case let s as String where s.isEmpty:
            "empty string"
        case let s as String:
            "string(\(s))"
        case let u as User:
            "user(\(u.name))"
        default:
            "unknown"
    }
}

// MARK: - String Literals

let multiline = """
    SELECT u.id, u.name
    FROM users AS u
    WHERE u.status = 'active'
    ORDER BY u.created_at DESC
    """

let regex = #/^(?<name>[A-Z][a-z]+)\s+(?<age>\d{1,3})$/#

// MARK: - Main

@main
struct App {
    static func main() async {
        let store = UserStore()
        let logger = Logger.shared

        let users = [
            User(id: 1, name: "Alice", email: "alice@example.com", status: .active),
            User(id: 2, name: "Bob", email: "bob@example.com", status: .inactive),
            User(id: 3, name: "Charlie", email: "charlie@example.com", status: .pending),
        ]

        for user in users {
            do {
                try user.validate()
                await store.insert(user)
                logger.log("Registered: \(user.display())")
            } catch {
                logger.log("Validation failed: \(error)", level: "WARN")
            }
        }

        let active = await store.all().filter { $0.status == .active }
        logger.log("Active users: \(active.descriptions().joined(separator: ", "))")

        if let input = "Alice 30".wholeMatch(of: regex) {
            logger.log("Parsed: name=\(input.name), age=\(input.age)")
        }

        let pair = Pair(first: 1, second: "hello")
        let mapped = pair.map { $0.uppercased() }
        logger.log("Pair: \(mapped.first) -> \(mapped.second)")

        logger.log("Total: \(await store.count)")
        logger.log(classify(42))
        logger.log(classify(""))
        logger.log(classify(users[0]))
    }
}
