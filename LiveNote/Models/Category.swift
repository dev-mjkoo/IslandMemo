
import Foundation
import SwiftData

@Model
final class Category {
    var name: String = ""
    var createdAt: Date = Date()
    var isLocked: Bool = false

    init(name: String, isLocked: Bool = false) {
        self.name = name
        self.createdAt = Date()
        self.isLocked = isLocked
    }
}
