import Foundation

struct ExerciseItem: Identifiable, Hashable, Codable {
    let id = UUID()
    let name: String
    let category: String // body part from file, e.g., core, arms
    
    var displayBodyPart: String { category.capitalized }
    
    // Heuristic equipment type for "Any Cat" filter
    var equipment: String {
        let n = name.lowercased()
        if n.contains("barbell") { return "Barbell" }
        if n.contains("dumbbell") { return "Dumbbell" }
        if n.contains("kettlebell") { return "Kettlebell" }
        if n.contains("cable") { return "Cable" }
        if n.contains("machine") { return "Machine" }
        if n.contains("smith") { return "Smith Machine" }
        if n.contains("band") { return "Band" }
        if n.contains("bodyweight") || n.contains("push up") || n.contains("pull up") { return "Bodyweight" }
        if n.contains("row") || n.contains("running") || n.contains("cycling") || n.contains("elliptical") || n.contains("ski") || n.contains("skate") || n.contains("swim") || n.contains("walk") { return "Cardio" }
        return "Other"
    }
}

final class ExerciseCatalog: ObservableObject {
    static let shared = ExerciseCatalog()
    @Published private(set) var all: [ExerciseItem] = []
    
    // Favorites persisted by name
    private let favKey = "favorite_exercises"
    // Use Swift.Set to avoid name clash with app's Workout Set model
    @Published var favorites: Swift.Set<String> = []
    
    // Filter options shown in pickers
    static let bodyParts: [String] = [
        "Any Body", "Core", "Arms", "Back", "Chest", "Legs", "Shoulders"
    ]
    static let equipmentCats: [String] = [
        "Any Cat", "Barbell", "Dumbbell", "Machine", "Cable", "Bodyweight", "Cardio", "Band", "Kettlebell", "Smith Machine", "Other"
    ]
    
    private init() {
        load()
        loadFavorites()
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
                let cat = (i+1) < lines.count ? lines[i+1].lowercased() : "other"
                items.append(ExerciseItem(name: name, category: cat))
                i += 3 // name, category, blank line
            }
            self.all = items
        } catch {
            print("ExerciseCatalog: load failed - \(error)")
            self.all = []
        }
    }
    
    func toggleFavorite(name: String) {
        if favorites.contains(name) {
            favorites.remove(name)
        } else {
            favorites.insert(name)
        }
        UserDefaults.standard.set(Array(favorites), forKey: favKey)
    }
    
    private func loadFavorites() {
        if let arr = UserDefaults.standard.array(forKey: favKey) as? [String] {
            favorites = Swift.Set(arr)
        }
    }
}
