//
//  LinkItem.swift
//  islandmemo
//
//  Created by Claude on 12/01/25.
//

import Foundation
import SwiftData

@Model
final class LinkItem {
    var url: String = ""
    var title: String?
    var category: String = ""
    var createdAt: Date = Date()

    init(url: String, title: String? = nil, category: String) {
        self.url = url
        self.title = title
        self.category = category
        self.createdAt = Date()
    }
}
