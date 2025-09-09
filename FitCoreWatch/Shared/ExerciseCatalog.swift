import Foundation

struct ExerciseItem: Identifiable, Hashable, Codable {
    let id = UUID()
    let name: String
    let category: String
}

final class ExerciseCatalog: ObservableObject {
    static let shared = ExerciseCatalog()
    @Published private(set) var all: [ExerciseItem] = []
    
    private init() {
        load()
    }
    
    func load() {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "txt", subdirectory: "Shared") ??
                Bundle.main.url(forResource: "exercises", withExtension: "txt") else {
            print("ExerciseCatalog: exercises.txt not found")
            all = []
            return
        }
        do {
            let raw = try String(contentsOf: url, encoding: .utf8)
            var items: [ExerciseItem] = []
            let lines = raw.split(separator: "\n", omittingEmptySubsequences: false).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            var i = 0
            while i < lines.count {
                if lines[i].isEmpty { i += 1; continue }
                let name = lines[i]
                let cat = (i+1) < lines.count ? lines[i+1] : "other"
                items.append(ExerciseItem(name: name, category: cat))
                i += 3 // name, category, blank line
            }
            self.all = items
        } catch {
            print("ExerciseCatalog: load failed - \(error)")
            self.all = []
        }
    }
}
