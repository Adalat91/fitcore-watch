import SwiftUI

struct ExercisesView: View {
    @ObservedObject private var catalog = ExerciseCatalog.shared
    @State private var query: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                // Search
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search", text: $query)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                
                List(filtered) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(item.category.capitalized)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .listStyle(.plain)
            }
            .padding(.horizontal, 8)
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var filtered: [ExerciseItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return catalog.all }
        return catalog.all.filter { $0.name.localizedCaseInsensitiveContains(q) || $0.category.localizedCaseInsensitiveContains(q) }
    }
}

#Preview {
    ExercisesView()
}
