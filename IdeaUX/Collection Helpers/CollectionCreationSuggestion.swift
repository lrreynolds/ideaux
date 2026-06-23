//
//  CollectionCreationSuggestion.swift
//  IdeaUX
//
//  Created by LouR on 6/22/26.
//

import Foundation

//
//  CollectionCreationSuggestion.swift
//  IdeaUX
//
//  Created by LouR on 6/22/26.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

#if canImport(FoundationModels)
@Generable
struct CollectionCreationSuggestion {

    @Guide(description: "A short, clear collection name. Clean up transcription errors and slang. Maximum 40 characters.")
    let name: String

    @Guide(description: "A one-line headline that explains what this collection is for. Clean up dictated wording. Maximum 90 characters.")
    let headline: String

    @Guide(description: "A polished short summary of the collection purpose. Stay close to the user's intent. Maximum 220 characters.")
    let summary: String
}
#endif
