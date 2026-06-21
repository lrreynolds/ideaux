//
//  CollectionReviewSuggestion.swift
//  IdeaUX
//
//  Created by LouR on 6/21/26.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

#if canImport(FoundationModels)
@Generable
struct NodeReviewUpdate {

    @Guide(description: "The UUID string of the node being evaluated.")
    let nodeID: String

    @Guide(description: """
    Recommended status.

    Use:
    - question
    - actionable
    - none

    Return only one value.
    """)
    let recommendedStatus: String

    @Guide(description: """
    Brief explanation of why this status was chosen.
    Maximum 120 characters.
    """)
    let reason: String
}

@Generable
struct CollectionReviewSuggestion {

    @Guide(description: """
    List of node status recommendations for the collection.
    Only include nodes whose status should change.
    """)
    let nodeUpdates: [NodeReviewUpdate]
}
#endif
