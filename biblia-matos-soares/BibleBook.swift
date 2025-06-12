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
    var chapters: [BibleChapter] = []

    init(name: String) {
        self.name = name
    }
}

