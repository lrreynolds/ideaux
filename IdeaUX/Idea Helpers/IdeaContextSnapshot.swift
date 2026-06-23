//
//  IdeaContextSnapshot.swift
//  IdeaUX
//
//  Created by LouR on 6/18/26.
//

import Foundation

struct IdeaContextSnapshot {
    let collectionName: String
    let collectionHeadline: String
    let collectionSummary: String


    let synthesizedDescription: String
    let synthesizedKeyConceptsText: String
    let synthesizedBackgroundContext: String

    let parentPath: [String]
    let currentNodeTitle: String
    let currentNodeContent: String

    let siblingTitles: [String]
    let childTitles: [String]
}
