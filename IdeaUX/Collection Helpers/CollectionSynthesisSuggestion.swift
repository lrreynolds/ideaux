
//
//  CollectionSynthesisSuggestion.swift
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
struct CollectionSynthesisSuggestion {

    @Guide(description: "An evolving description of what this collection is becoming based on approved idea branches. Maximum 500 characters.")
    let description: String

    @Guide(description: "Important themes or concepts emerging across approved branches. Use plain text, one concept per line. Maximum 8 lines.")
    let keyConceptsText: String

    @Guide(description: "Useful background context the app should remember when refining future ideas in this collection. Maximum 500 characters.")
    let backgroundContext: String
}
#endif
