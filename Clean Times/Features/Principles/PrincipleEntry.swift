import Foundation

struct PrincipleEntry: Codable, Identifiable, Equatable {
    let id: String
    let month: Int
    let day: Int
    let displayDate: String
    let keyword: String
    let title: String
    let body: String
    let page: Int?
}

extension PrincipleEntry {
    static let sample = PrincipleEntry(
        id: "05-09",
        month: 5,
        day: 9,
        displayDate: "May 9",
        keyword: "Love",
        title: "Love",
        body: "A local daily reading will appear here once the bundled principle data is added.",
        page: nil
    )
}
