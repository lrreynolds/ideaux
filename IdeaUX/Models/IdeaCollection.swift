import Foundation
import SwiftData

@Model
final class IdeaCollection {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var name: String
    var headline: String = ""
    var summary: String
    var iconName: String
    var colorName: String


    // Model-synthesized collection context from approved idea branches
    var synthesizedDescription: String = ""
    var synthesizedKeyConceptsText: String = ""
    var synthesizedBackgroundContext: String  = ""
    var synthesizedAt: Date?

    // Legacy / advanced context fields retained for now
    var goalsText: String
    var keyConceptsText: String
    var backgroundContext: String
    var refinementInstructions: String

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        name: String,
        headline: String = "",
        summary: String = "",
        iconName: String = "folder",
        colorName: String = "blue",
        synthesizedDescription: String = "",
        synthesizedKeyConceptsText: String = "",
        synthesizedBackgroundContext: String = "",
        synthesizedAt: Date? = nil,
        goalsText: String = "",
        keyConceptsText: String = "",
        backgroundContext: String = "",
        refinementInstructions: String = ""
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.name = name
        self.headline = headline
        self.summary = summary
        self.iconName = iconName
        self.colorName = colorName
        self.synthesizedDescription = synthesizedDescription
        self.synthesizedKeyConceptsText = synthesizedKeyConceptsText
        self.synthesizedBackgroundContext = synthesizedBackgroundContext
        self.synthesizedAt = synthesizedAt
        self.goalsText = goalsText
        self.keyConceptsText = keyConceptsText
        self.backgroundContext = backgroundContext
        self.refinementInstructions = refinementInstructions
    }
}
