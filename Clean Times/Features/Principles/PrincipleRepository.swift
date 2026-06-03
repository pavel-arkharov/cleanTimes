import Foundation

struct PrincipleRepository {
    private let entries: [PrincipleEntry]
    private let entriesByID: [String: PrincipleEntry]

    init(
        bundle: Bundle = .main,
        resourceName: String = "principles",
        resourceExtension: String = "json"
    ) {
        self.init(entries: Self.loadEntries(
            bundle: bundle,
            resourceName: resourceName,
            resourceExtension: resourceExtension
        ))
    }

    init(entries: [PrincipleEntry]) {
        let sortedEntries = entries.sorted {
            ($0.month, $0.day) < ($1.month, $1.day)
        }
        self.entries = sortedEntries.isEmpty ? [.sample] : sortedEntries

        var indexedEntries: [String: PrincipleEntry] = [:]
        for entry in self.entries {
            indexedEntries[entry.id] = entry
        }
        self.entriesByID = indexedEntries
    }

    func allEntries() -> [PrincipleEntry] {
        entries
    }

    func entry(month: Int, day: Int) -> PrincipleEntry? {
        entriesByID[String(format: "%02d-%02d", month, day)]
    }

    func entry(for date: Date, calendar: Calendar) -> PrincipleEntry {
        let components = calendar.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else {
            return .sample
        }
        return entry(month: month, day: day) ?? .sample
    }

    func next(after entry: PrincipleEntry) -> PrincipleEntry {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else {
            return entries.first ?? .sample
        }
        return entries[(index + 1) % entries.count]
    }

    func previous(before entry: PrincipleEntry) -> PrincipleEntry {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else {
            return entries.first ?? .sample
        }
        return entries[(index - 1 + entries.count) % entries.count]
    }

    private static func loadEntries(
        bundle: Bundle,
        resourceName: String,
        resourceExtension: String
    ) -> [PrincipleEntry] {
        guard let url = resourceURL(
            bundle: bundle,
            resourceName: resourceName,
            resourceExtension: resourceExtension
        ) else {
            return [.sample]
        }

        do {
            let data = try Data(contentsOf: url)
            let decodedEntries = try JSONDecoder().decode([PrincipleEntry].self, from: data)
            return decodedEntries.isEmpty ? [.sample] : decodedEntries
        } catch {
            return [.sample]
        }
    }

    private static func resourceURL(
        bundle: Bundle,
        resourceName: String,
        resourceExtension: String
    ) -> URL? {
        let subdirectories: [String?] = [
            "Principles",
            "Resources/Principles",
            nil
        ]

        for subdirectory in subdirectories {
            if let url = bundle.url(
                forResource: resourceName,
                withExtension: resourceExtension,
                subdirectory: subdirectory
            ) {
                return url
            }
        }

        return nil
    }
}
