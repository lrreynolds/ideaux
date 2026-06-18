//
//  IdeaPromptBuilder.swift
//  IdeaUX
//
//  Created by LouR on 6/18/26.
//

import Foundation

struct IdeaPromptBuilder {

    static func refinementPrompt(for snapshot: IdeaContextSnapshot, rawInput: String) -> String {
        """
        You are helping refine an idea inside an evolving idea tree.

        Collection:
        \(snapshot.collectionName)

        Summary:
        \(snapshot.collectionSummary)

        Purpose:
        \(snapshot.purpose)

        Goals:
        \(snapshot.goals)

        Key Concepts:
        \(snapshot.keyConcepts)

        Background:
        \(snapshot.backgroundContext)

        Refinement Instructions:
        \(snapshot.refinementInstructions)

        Parent Path:
        \(snapshot.parentPath.isEmpty ? "None" : snapshot.parentPath.joined(separator: " > "))

        Current Node:
        \(snapshot.currentNodeTitle)

        Current Content:
        \(snapshot.currentNodeContent)

        Siblings:
        \(snapshot.siblingTitles.isEmpty ? "None" : snapshot.siblingTitles.map { "- \($0)" }.joined(separator: "\n"))

        Children:
        \(snapshot.childTitles.isEmpty ? "None" : snapshot.childTitles.map { "- \($0)" }.joined(separator: "\n"))

        New Input:
        \(rawInput)

        Task:
        Refine the new input into a clear idea node.

        Return:
        Title:
        Summary:
        Suggested Questions:
        Suggested Child Ideas:
        """
    }
}
