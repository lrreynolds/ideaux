//
//  IdeaRefinementSuggestion.swift
//  IdeaUX
//
//  Created by LouR on 6/18/26.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

#if canImport(FoundationModels)
@Generable
struct IdeaRefinementSuggestion {

    @Guide(description: "A clearer version of the original node title. Do not abstract or generalize. Maximum 48 characters.")
    let title: String

    @Guide(description: "One sentence explaining what this node appears to mean in the larger context. Maximum 160 characters.")
    let interpretation: String

    @Guide(description: "A plain-language summary of this specific node. Maximum 160 characters.")
    let summary: String

    @Guide(description: "Exactly three helpful questions the user might consider. Each item maximum 80 characters.")
    let questions: [String]

    @Guide(description: "Exactly three related ideas that naturally connect to this node. Each item maximum 48 characters.")
    let relatedIdeas: [String]

    @Guide(description: "Exactly three lightweight possible next steps. Each item maximum 80 characters.")
    let possibleNextSteps: [String]

}
#endif
