//
//  BibleBook.swift
//  biblia-matos-soares
//
//  Created by Victor Luís Gama de Assis on 12/06/25.
//

import Foundation
import SwiftData

@Model
class BibleBook {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var order: Int
    var chapters: [BibleChapter] = []

    init(name: String, order: Int) {
        self.name = name
        self.order = order
    }
}

