
//
//  CollectionCreationRefiner.swift
//  IdeaUX
//
//  Created by LouR on 6/22/26.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct CollectionCreationRefiner {

    func refine(from rawText: String) async throws -> CollectionCreationSuggestion {
#if canImport(FoundationModels)

        let model = SystemLanguageModel.default

        guard case .available = model.availability else {
            throw IdeaFoundationModelError.modelUnavailable(
                String(describing: model.availability)
            )
        }

        let session = LanguageModelSession(instructions: """
        Help create a new collection from a user's dictated description.

        Clean up transcription errors.

        Convert casual speech into clear written language.

        Stay faithful to the user's intent.

        Do not invent goals or strategy.

        Produce:

        - A short collection name
        - A one-line headline
        - A short summary

        Prefer clarity over creativity.
        """)

        let response = try await session.respond(
            to: """
            Create a collection from this description:

            \(rawText)
            """,
            generating: CollectionCreationSuggestion.self,
            options: GenerationOptions(sampling: .greedy)
        )

        return response.content

#else

        return CollectionCreationSuggestion(
            name: rawText,
            headline: rawText,
            summary: rawText
        )

#endif
    }
}
