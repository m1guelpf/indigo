//
//  Item.swift
//  Indigo
//
//  Created by Miguel Piedrafita on 31/01/2024.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
