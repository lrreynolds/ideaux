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
    // Outliner fields
    var nodeType: String // convention: idea, question, task, decision, implementation, evidence, project, observation
    var priority: String // convention: low, normal, high
    // status as String (by convention): seed, exploring, refining, actionable, implemented, validated, rejected, archived
    var status: String

    // Future AI-generated fields
    var nextQuestionsText: String
    var exportPromptText: String

    // Lifecycle / implementation
    var implementedAt: Date?

    // Simple parent support (no inverse children array for now)
    // parentID is used for reliable outline rendering/import.
    // The SwiftData parent relationship can remain as a convenience reference.
    var parentID: UUID?
    var parent: IdeaNode?

    // Relationships
    var collectionID: UUID?
    var collection: IdeaCollection?
    var project: IdeaProject?

    var tagsText: String
    var sortOrder: Int
    
    var modelInterpretation: String = ""
    var modelQuestionsText: String = ""
    var modelRelatedIdeasText: String = ""
    var modelNextStepsText: String = ""
    var lastAnalyzedAt: Date?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        rawCapture: String = "",
        title: String = "",
        refinedText: String = "",
        summary: String = "",
        nodeType: String = "idea",
        priority: String = "normal",
        status: String = "seed",
        nextQuestionsText: String = "",
        exportPromptText: String = "",
        implementedAt: Date? = nil,
        parentID: UUID? = nil,
        parent: IdeaNode? = nil,
        collectionID: UUID? = nil,
        collection: IdeaCollection? = nil,
        project: IdeaProject? = nil,
        tagsText: String = "",
        sortOrder: Int = 0,
        modelInterpretation: String = "",
        modelQuestionsText: String = "",
        modelRelatedIdeasText: String = "",
        modelNextStepsText: String = "",
        lastAnalyzedAt: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.rawCapture = rawCapture
        self.title = title
        self.refinedText = refinedText
        self.summary = summary
        self.nodeType = nodeType
        self.priority = priority
        self.status = status
        self.nextQuestionsText = nextQuestionsText
        self.exportPromptText = exportPromptText
        self.implementedAt = implementedAt
        self.parentID = parentID
        self.parent = parent
        self.collectionID = collectionID
        self.collection = collection
        self.project = project
        self.tagsText = tagsText
        self.sortOrder = sortOrder
        self.modelInterpretation = modelInterpretation
        self.modelQuestionsText = modelQuestionsText
        self.modelRelatedIdeasText = modelRelatedIdeasText
        self.modelNextStepsText = modelNextStepsText
        self.lastAnalyzedAt = lastAnalyzedAt
    }
}
