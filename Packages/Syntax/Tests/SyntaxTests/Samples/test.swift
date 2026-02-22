import Foundation

enum LogLevel: String {
    case debug, info, warning, error
}

struct User {
    let id: Int
    let name: String

    func label(prefix: String = "user") -> String {
        "\(prefix):\(id):\(name)"
    }
}

func fetchUsers() async throws -> [User] {
    [User(id: 1, name: "Alice"), User(id: 2, name: "Bob")]
}

@main
struct App {
    static func main() async {
        do {
            let users = try await fetchUsers()
            print(users.first?.label() ?? "empty")
        } catch {
            print("error: \(error)")
        }
    }
}
