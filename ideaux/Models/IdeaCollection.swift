import Foundation
import SwiftData

@Model
final class IdeaCollection {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var name: String
    var summary: String
    var iconName: String
    var colorName: String

    // Context fields for Foundation Models
    var purpose: String
    var goalsText: String
    var keyConceptsText: String
    var backgroundContext: String
    var refinementInstructions: String

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        name: String,
        summary: String = "",
        iconName: String = "folder",
        colorName: String = "blue",
        purpose: String = "",
        goalsText: String = "",
        keyConceptsText: String = "",
        backgroundContext: String = "",
        refinementInstructions: String = ""
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.name = name
        self.summary = summary
        self.iconName = iconName
        self.colorName = colorName
        self.purpose = purpose
        self.goalsText = goalsText
        self.keyConceptsText = keyConceptsText
        self.backgroundContext = backgroundContext
        self.refinementInstructions = refinementInstructions
    }
}
