//
//  IdeaContextSnapshot.swift
//  IdeaUX
//
//  Created by LouR on 6/18/26.
//

import Foundation

struct IdeaContextSnapshot {
    let collectionName: String
    let collectionSummary: String

    let purpose: String
    let goals: String
    let keyConcepts: String
    let backgroundContext: String
    let refinementInstructions: String

    let parentPath: [String]
    let currentNodeTitle: String
    let currentNodeContent: String

    let siblingTitles: [String]
    let childTitles: [String]
}
