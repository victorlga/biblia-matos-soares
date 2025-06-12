//
//  ReadingProgress.swift
//  biblia-matos-soares
//
//  Created by Victor Luís Gama de Assis on 12/06/25.
//

import Foundation
import SwiftData

@Model
class ReadingProgress {
    @Relationship var lastBook: BibleBook?
    @Relationship var lastChapter: BibleChapter?

    init(lastBook: BibleBook? = nil, lastChapter: BibleChapter? = nil) {
        self.lastBook = lastBook
        self.lastChapter = lastChapter
    }
}
