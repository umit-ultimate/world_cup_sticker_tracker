import Foundation

struct Country: Codable, Identifiable, Hashable {
    let id: String
    let code: String
    let name: String
    let page: Int
    let group: String
    let stickerCount: Int
}
