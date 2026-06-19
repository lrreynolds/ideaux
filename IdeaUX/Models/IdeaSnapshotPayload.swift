//
//  IdeaSnapshotPayload.swift
//  IdeaUX
//
//  Created by LouR on 6/19/26.
//

import Foundation

struct IdeaCollectionSnapshotPayload: Codable {
    var collection: CollectionSnapshotData
    var nodes: [NodeSnapshotData]
}

struct CollectionSnapshotData: Codable {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date

    var name: String
    var summary: String

    var iconName: String
    var colorName: String

    var purpose: String
    var goalsText: String
    var keyConceptsText: String
    var backgroundContext: String
    var refinementInstructions: String
}

struct NodeSnapshotData: Codable {
    var id: UUID

    var collectionID: UUID
    var parentID: UUID?

    var createdAt: Date
    var updatedAt: Date
    var implementedAt: Date?
    var lastAnalyzedAt: Date?

    var title: String
    var rawCapture: String
    var refinedText: String
    var summary: String

    var status: String
    var nodeType: String

    var nextQuestionsText: String

    var modelInterpretation: String
    var modelQuestionsText: String
    var modelRelatedIdeasText: String
    var modelNextStepsText: String
}
