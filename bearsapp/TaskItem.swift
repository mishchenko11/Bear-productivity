//
//  TaskItem.swift
//  bearsapp
//
//  Created by Irina on 19.09.26.
//

import Foundation
import SwiftData

@Model
final class TaskItem {
    var title: String
    var date: Date
    var time: Date?
    var isCompleted: Bool
 
    init(title: String,
         date: Date,
         time: Date? = nil,
         isCompleted: Bool = false
    ) {
        self.title = title
        self.date = date
        self.time = time
        self.isCompleted = isCompleted
    }
}
