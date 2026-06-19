//
//  IdeaSnapshotManager.swift
//  IdeaUX
//
//  Created by LouR on 6/19/26.
//

import Foundation
import SwiftData

struct IdeaSnapshotManager {
    static func createSnapshot(
        for collection: IdeaCollection,
        allNodes: [IdeaNode],
        reason: String,
        context: ModelContext
    ) throws -> IdeaCollectionSnapshot {
        let collectionNodes = allNodes.filter { $0.collectionID == collection.id }

        let payload = IdeaCollectionSnapshotPayload(
            collection: CollectionSnapshotData(
                id: collection.id,
                createdAt: collection.createdAt,
                updatedAt: collection.updatedAt,
                name: collection.name,
                summary: collection.summary,
                iconName: collection.iconName,
                colorName: collection.colorName,
                purpose: collection.purpose,
                goalsText: collection.goalsText,
                keyConceptsText: collection.keyConceptsText,
                backgroundContext: collection.backgroundContext,
                refinementInstructions: collection.refinementInstructions
            ),
            nodes: collectionNodes.map { node in
                NodeSnapshotData(
                    id: node.id,
                    collectionID: collection.id,
                    parentID: node.parentID,
                    createdAt: node.createdAt,
                    updatedAt: node.updatedAt,
                    implementedAt: node.implementedAt,
                    lastAnalyzedAt: node.lastAnalyzedAt,
                    title: node.title,
                    rawCapture: node.rawCapture,
                    refinedText: node.refinedText,
                    summary: node.summary,
                    status: node.status,
                    nodeType: node.nodeType,
                    nextQuestionsText: node.nextQuestionsText,
                    modelInterpretation: node.modelInterpretation,
                    modelQuestionsText: node.modelQuestionsText,
                    modelRelatedIdeasText: node.modelRelatedIdeasText,
                    modelNextStepsText: node.modelNextStepsText
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(payload)
        let payloadJSON = String(decoding: data, as: UTF8.self)

        let snapshot = IdeaCollectionSnapshot(
            collectionID: collection.id,
            collectionName: collection.name,
            reason: reason,
            payloadJSON: payloadJSON
        )

        context.insert(snapshot)
        try context.save()

        return snapshot
    }

    static func restore(
        snapshot: IdeaCollectionSnapshot,
        allCollections: [IdeaCollection],
        allNodes: [IdeaNode],
        context: ModelContext
    ) throws -> IdeaCollection {
        let data = Data(snapshot.payloadJSON.utf8)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let payload = try decoder.decode(IdeaCollectionSnapshotPayload.self, from: data)

        let collection = allCollections.first { $0.id == payload.collection.id } ?? IdeaCollection(
            id: payload.collection.id,
            createdAt: payload.collection.createdAt,
            updatedAt: payload.collection.updatedAt,
            name: payload.collection.name,
            summary: payload.collection.summary,
            iconName: payload.collection.iconName,
            colorName: payload.collection.colorName,
            purpose: payload.collection.purpose,
            goalsText: payload.collection.goalsText,
            keyConceptsText: payload.collection.keyConceptsText,
            backgroundContext: payload.collection.backgroundContext,
            refinementInstructions: payload.collection.refinementInstructions
        )

        if !allCollections.contains(where: { $0.id == collection.id }) {
            context.insert(collection)
        }

        collection.createdAt = payload.collection.createdAt
        collection.updatedAt = payload.collection.updatedAt
        collection.name = payload.collection.name
        collection.summary = payload.collection.summary
        collection.iconName = payload.collection.iconName
        collection.colorName = payload.collection.colorName
        collection.purpose = payload.collection.purpose
        collection.goalsText = payload.collection.goalsText
        collection.keyConceptsText = payload.collection.keyConceptsText
        collection.backgroundContext = payload.collection.backgroundContext
        collection.refinementInstructions = payload.collection.refinementInstructions

        let existingNodes = allNodes.filter { $0.collectionID == collection.id }
        for node in existingNodes {
            context.delete(node)
        }

        var nodeByID: [UUID: IdeaNode] = [:]

        for nodeData in payload.nodes {
            let node = IdeaNode(
                rawCapture: nodeData.rawCapture,
                title: nodeData.title,
                refinedText: nodeData.refinedText,
                summary: nodeData.summary,
                status: nodeData.status,
                nextQuestionsText: nodeData.nextQuestionsText
            )

            node.id = nodeData.id
            node.collectionID = nodeData.collectionID
            node.parentID = nodeData.parentID
            node.createdAt = nodeData.createdAt
            node.updatedAt = nodeData.updatedAt
            node.implementedAt = nodeData.implementedAt
            node.lastAnalyzedAt = nodeData.lastAnalyzedAt
            node.nodeType = nodeData.nodeType
            node.modelInterpretation = nodeData.modelInterpretation
            node.modelQuestionsText = nodeData.modelQuestionsText
            node.modelRelatedIdeasText = nodeData.modelRelatedIdeasText
            node.modelNextStepsText = nodeData.modelNextStepsText
            node.collection = collection

            nodeByID[node.id] = node
            context.insert(node)
        }

        for node in nodeByID.values {
            if let parentID = node.parentID {
                node.parent = nodeByID[parentID]
            }
        }

        try context.save()
        return collection
    }
}
