import Foundation
import SwiftData

@Model
final class IdeaLink {
    var id: UUID
    var createdAt: Date
    // linkType as String: related, parent, child, supports, expands, contradicts
    var linkType: String
    var confidence: Double
    // createdBy as String: user, model
    var createdBy: String

    // Relationships
    var source: IdeaNode?
    var target: IdeaNode?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        linkType: String = "related",
        confidence: Double = 0.5,
        createdBy: String = "user",
        source: IdeaNode? = nil,
        target: IdeaNode? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.linkType = linkType
        self.confidence = confidence
        self.createdBy = createdBy
        self.source = source
        self.target = target
    }
}
