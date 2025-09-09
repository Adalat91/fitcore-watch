import SwiftUI

struct ExercisesView: View {
    @ObservedObject private var catalog = ExerciseCatalog.shared
    @State private var query: String = ""
    @State private var favoritesOnly: Bool = false
    @State private var selectedTag: String? = nil // e.g., "Chest", "Arms", "Olympic"
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    // Search (compact)
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.caption2)
                        TextField("Search", text: $query)
                            .textFieldStyle(.plain)
                            .font(.caption2)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .frame(height: 26)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(6)

                    // Horizontal scrollable filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            // Starred
                            Button { toggleStarred() } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: favoritesOnly ? "star.fill" : "star")
                                    Text("Starred")
                                }
                                .font(.caption2)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(chipBg(active: favoritesOnly))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)

                            // Dynamic tags from categories in file (e.g., Core, Arms, Olympic ...)
                            ForEach(categoryTags, id: \.self) { tag in
                                Button {
                                    select(tag: tag)
                                } label: {
                                    Text(tag)
                                        .font(.caption2)
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(chipBg(active: selectedTag == tag))
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                ForEach(filtered) { item in
                    HStack(spacing: 6) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.name)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text(item.displayBodyPart)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer(minLength: 8)
                        Button(action: { catalog.toggleFavorite(name: item.name) }) {
                            Image(systemName: catalog.favorites.contains(item.name) ? "star.fill" : "star")
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                    .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                }
            }
            .listStyle(.plain)
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var filtered: [ExerciseItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return catalog.all.filter { item in
            // search
            if !q.isEmpty && !(item.name.localizedCaseInsensitiveContains(q) || item.category.localizedCaseInsensitiveContains(q)) { return false }
            // tag filter (by body part like Chest, Arms, Core, Olympic, etc.)
            if let tag = selectedTag {
                if item.displayBodyPart != tag { return false }
            }
            // favorites
            if favoritesOnly && !catalog.favorites.contains(item.name) { return false }
            return true
        }
    }

    // MARK: - Tags
    private var categoryTags: [String] {
        // Disambiguate against Codable init(from:) by specifying the generic type
        let set: Swift.Set<String> = Swift.Set(catalog.all.map { $0.displayBodyPart })
        return Array(set).sorted()
    }
    private func select(tag: String) {
        selectedTag = tag
        query = ""
    }
    private func toggleStarred() {
        favoritesOnly.toggle()
    }
    private func chipBg(active: Bool) -> Color { active ? Color.accentColor.opacity(0.25) : Color.gray.opacity(0.2) }
}

#Preview {
    ExercisesView()
}
