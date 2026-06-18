//
//  IdeaContextBuilder.swift
//  IdeaUX
//
//  Created by LouR on 6/18/26.
//

import Foundation

struct IdeaContextBuilder {

    static func snapshot(
        collection: IdeaCollection,
        node: IdeaNode?,
        allNodes: [IdeaNode]
    ) -> IdeaContextSnapshot {

        return IdeaContextSnapshot(
            collectionName: collection.name,
            collectionSummary: collection.summary,
            purpose: collection.purpose,
            goals: collection.goalsText,
            keyConcepts: collection.keyConceptsText,
            backgroundContext: collection.backgroundContext,
            refinementInstructions: collection.refinementInstructions,
            parentPath: [],
            currentNodeTitle: "",
            currentNodeContent: "",
            siblingTitles: [],
            childTitles: []
        )
    }
}
