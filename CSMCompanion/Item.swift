//
//  Item.swift
//  CSMCompanion
//
//  Created by Stuart Minchington on 9/9/26.
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
