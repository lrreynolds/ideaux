//
//  CollectionReviewSnapshot.swift
//  IdeaUX
//
//  Created by LouR on 6/21/26.
//

import Foundation


struct CollectionReviewSnapshot {
    let collectionID: UUID
    let collectionName: String
    let collectionSummary: String
    let purpose: String
    let goals: String
    let keyConcepts: String
    let backgroundContext: String
    let refinementInstructions: String
    let nodes: [CollectionReviewNodeSnapshot]
}

struct CollectionReviewNodeSnapshot {
    let id: UUID
    let parentID: UUID?
    let title: String
    let rawCapture: String
    let refinedText: String
    let summary: String
    let modelInterpretation: String
    let modelQuestionsText: String
    let modelRelatedIdeasText: String
    let modelNextStepsText: String
    let status: String
    let nodeType: String
    let childIDs: [UUID]
    let depth: Int
    let path: [String]
}

struct CollectionReviewSnapshotBuilder {
    static func snapshot(
        collection: IdeaCollection,
        allNodes: [IdeaNode]
    ) -> CollectionReviewSnapshot {
        let collectionNodes = allNodes
            .filter { $0.collectionID == collection.id }
            .sorted { lhs, rhs in
                if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                return lhs.createdAt < rhs.createdAt
            }

        let nodeSnapshots = collectionNodes.map { node in
            CollectionReviewNodeSnapshot(
                id: node.id,
                parentID: node.parentID,
                title: displayTitle(for: node),
                rawCapture: node.rawCapture,
                refinedText: node.refinedText,
                summary: node.summary,
                modelInterpretation: node.modelInterpretation,
                modelQuestionsText: node.modelQuestionsText,
                modelRelatedIdeasText: node.modelRelatedIdeasText,
                modelNextStepsText: node.modelNextStepsText,
                status: node.status,
                nodeType: node.nodeType,
                childIDs: children(of: node, in: collectionNodes).map(\.id),
                depth: depth(of: node, in: collectionNodes),
                path: path(to: node, in: collectionNodes)
            )
        }

        return CollectionReviewSnapshot(
            collectionID: collection.id,
            collectionName: collection.name,
            collectionSummary: collection.summary,
            purpose: collection.purpose,
            goals: collection.goalsText,
            keyConcepts: collection.keyConceptsText,
            backgroundContext: collection.backgroundContext,
            refinementInstructions: collection.refinementInstructions,
            nodes: nodeSnapshots
        )
    }

    private static func displayTitle(for node: IdeaNode) -> String {
        let title = node.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty { return title }

        let raw = node.rawCapture.trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty { return String(raw.prefix(80)) }

        return "Untitled"
    }

    private static func children(of node: IdeaNode, in allNodes: [IdeaNode]) -> [IdeaNode] {
        allNodes
            .filter { $0.parentID == node.id }
            .sorted { lhs, rhs in
                if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                return lhs.createdAt < rhs.createdAt
            }
    }

    private static func depth(of node: IdeaNode, in allNodes: [IdeaNode]) -> Int {
        var depth = 0
        var currentParentID = node.parentID

        while let parentID = currentParentID,
              let parent = allNodes.first(where: { $0.id == parentID }) {
            depth += 1
            currentParentID = parent.parentID
        }

        return depth
    }

    private static func path(to node: IdeaNode, in allNodes: [IdeaNode]) -> [String] {
        var path = [displayTitle(for: node)]
        var currentParentID = node.parentID

        while let parentID = currentParentID,
              let parent = allNodes.first(where: { $0.id == parentID }) {
            path.insert(displayTitle(for: parent), at: 0)
            currentParentID = parent.parentID
        }

        return path
    }
}
