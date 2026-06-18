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
}
