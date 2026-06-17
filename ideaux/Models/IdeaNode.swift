import Foundation
import SwiftData

@Model
final class IdeaNode {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var rawCapture: String
    var title: String
    var refinedText: String
    var summary: String
    var tagsText: String
    // status as String: seed, growing, archived
    var status: String

    // Future AI-generated fields
    var nextQuestionsText: String
    var exportPromptText: String

    // Relationships
    var collection: IdeaCollection?
    var project: IdeaProject?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        rawCapture: String = "",
        title: String = "",
        refinedText: String = "",
        summary: String = "",
        tagsText: String = "",
        status: String = "seed",
        nextQuestionsText: String = "",
        exportPromptText: String = "",
        collection: IdeaCollection? = nil,
        project: IdeaProject? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.rawCapture = rawCapture
        self.title = title
        self.refinedText = refinedText
        self.summary = summary
        self.tagsText = tagsText
        self.status = status
        self.nextQuestionsText = nextQuestionsText
        self.exportPromptText = exportPromptText
        self.collection = collection
        self.project = project
    }
}
