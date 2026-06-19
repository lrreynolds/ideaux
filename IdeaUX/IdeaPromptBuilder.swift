//
//  IdeaPromptBuilder.swift
//  IdeaUX
//
//  Created by LouR on 6/18/26.
//


import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct IdeaPromptBuilder {

    static func refinementPrompt(
        for snapshot: IdeaContextSnapshot,
        rawInput: String
    ) -> String {
        """
        You are refining a SINGLE idea node inside an idea tree.

        IMPORTANT:
        The CURRENT NODE is the primary subject.
        Collection information exists only to provide context.
        Do not summarize the entire collection.
        Do not create a title for the collection.
        Do not create child ideas for the collection.
        Focus on the current node only.

        COLLECTION CONTEXT

        Collection Name:
        \(snapshot.collectionName)

        Collection Purpose:
        \(snapshot.purpose.isEmpty ? "None" : snapshot.purpose)

        Parent Path:
        \(snapshot.parentPath.isEmpty ? "None" : snapshot.parentPath.joined(separator: " > "))

        CURRENT NODE

        Current Title:
        \(snapshot.currentNodeTitle)

        Current Content:
        \(snapshot.currentNodeContent)

        Raw Input:
        \(rawInput)

        SIBLINGS

        \(snapshot.siblingTitles.isEmpty
            ? "None"
            : snapshot.siblingTitles.joined(separator: "\n"))

        CHILDREN

        \(snapshot.childTitles.isEmpty
            ? "None"
            : snapshot.childTitles.joined(separator: "\n"))

        TASK

        Help the user think about the CURRENT NODE only.

        Produce:

        1. A clearer title for this specific node.
        2. A short summary explaining what this node seems to mean.
        3. Helpful questions the user might consider.
        4. Related ideas that could naturally connect to this node.
        5. Possible next steps, only if they are lightweight and useful.

        Avoid generic product strategy.
        Avoid creating unnecessary work.
        Prefer optional suggestions over assignments.
        Stay close to the user's original wording.
        """
    }
    
    static func debugContext(
        for snapshot: IdeaContextSnapshot,
        rawInput: String
    ) -> String {
        """
        COLLECTION
        Name: \(snapshot.collectionName)

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
        \(snapshot.siblingTitles.isEmpty ? "None" : snapshot.siblingTitles.joined(separator: ", "))

        Children:
        \(snapshot.childTitles.isEmpty ? "None" : snapshot.childTitles.joined(separator: ", "))

        Raw Input:
        \(rawInput)
        """
    }
}

enum IdeaFoundationModelError: LocalizedError {
    case frameworkUnavailable
    case modelUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .frameworkUnavailable:
            return "FoundationModels is not available in this build or SDK."
        case .modelUnavailable(let reason):
            return "The on-device language model is not available: \(reason)"
        }
    }
}

struct FoundationModelIdeaRefiner {
    func refine(prompt: String) async throws -> String {
#if canImport(FoundationModels)
        let model = SystemLanguageModel.default

        guard case .available = model.availability else {
            throw IdeaFoundationModelError.modelUnavailable(String(describing: model.availability))
        }

        let session = LanguageModelSession(instructions: """
        You are helping refine ideas inside a lightweight, offline-first idea tree.
        Be concise, practical, and structure-preserving.
        Do not invent unrelated product requirements.
        Prefer small, actionable idea nodes over long prose.
        """)

        let response = try await session.respond(
            to: prompt,
            options: GenerationOptions(sampling: .greedy)
        )

        return response.content
#else
        throw IdeaFoundationModelError.frameworkUnavailable
#endif
    }
    
    func refineSuggestion(prompt: String) async throws -> IdeaRefinementSuggestion {
#if canImport(FoundationModels)
        let model = SystemLanguageModel.default

        guard case .available = model.availability else {
            throw IdeaFoundationModelError.modelUnavailable(String(describing: model.availability))
        }

        let session = LanguageModelSession(instructions: """
        Your role is to help a human think.

        Do not assume the idea is incomplete.

        A title is a clearer expression of the current idea.

        Do not reinterpret the idea into a different idea.

        Interpretation is different from title.

        The interpretation should explain what you believe
        the node means within the surrounding context.

        The title should stay very close to the original wording.

        Do not create work unless it is genuinely useful.

        Prefer helpful questions over conclusions.

        Prefer possibilities over specific plans.

        Stay close to the original idea.

        When in doubt, preserve the author's intent.
        """)

        let response = try await session.respond(
            to: prompt,
            generating: IdeaRefinementSuggestion.self,
            options: GenerationOptions(sampling: .greedy)
        )

        return response.content
#else
        throw IdeaFoundationModelError.frameworkUnavailable
#endif
    }
    
}
