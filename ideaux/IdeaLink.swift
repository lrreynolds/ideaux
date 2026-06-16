import Foundation
import SwiftData

@Model
final class IdeaLink {
    var id: UUID
    var createdAt: Date
    @Relationship var source: IdeaNode?
    @Relationship var target: IdeaNode?
    var linkType: String // related, parent, child, supports, expands, contradicts
    var confidence: Double
    var createdBy: String // user or model

    init(id: UUID = UUID(), createdAt: Date = Date(), source: IdeaNode? = nil, target: IdeaNode? = nil, linkType: String, confidence: Double = 0.5, createdBy: String = "user") {
        self.id = id
        self.createdAt = createdAt
        self.source = source
        self.target = target
        self.linkType = linkType
        self.confidence = confidence
        self.createdBy = createdBy
    }
}
