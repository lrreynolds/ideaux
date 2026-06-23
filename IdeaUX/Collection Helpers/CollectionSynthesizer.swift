
//
//  CollectionSynthesizer.swift
//  IdeaUX
//
//  Created by LouR on 6/21/26.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

#if canImport(FoundationModels)
struct CollectionSynthesizer {
    func synthesize(snapshot: CollectionReviewSnapshot) async throws -> CollectionSynthesisSuggestion {
        let prompt = synthesisPrompt(for: snapshot)

        let session = LanguageModelSession(instructions: """
        You synthesize an evolving personal idea tree.

        The tree is the source of truth.
        Use only reviewed/approved nodes as reliable evidence.
        Ignore raw, seed, or currently refining nodes unless needed for broad orientation.

        Your job is not to create tasks.
        Your job is to summarize what the collection is becoming based on approved branches.

        Keep the synthesis concise, practical, and close to the user's own language.
        Do not over-generalize.
        """)

        let response = try await session.respond(
            to: prompt,
            generating: CollectionSynthesisSuggestion.self
        )

        return response.content
    }

    private func synthesisPrompt(for snapshot: CollectionReviewSnapshot) -> String {
        let approvedNodes = reviewedNodes(from: snapshot.nodes)

        return """
        Synthesize this ideauX collection from reviewed idea branches.

        REVIEWED NODE EVIDENCE

        \(nodeEvidenceText(for: approvedNodes))

        USER-PROVIDED COLLECTION CONTEXT

        Collection Name:
        \(snapshot.collectionName)

        Collection Headline:
        \(emptyFallback(snapshot.collectionHeadline))

        User Short Summary:
        \(emptyFallback(snapshot.collectionSummary))

        EXISTING SYNTHESIZED CONTEXT

        Current Evolving Description:
        \(emptyFallback(snapshot.synthesizedDescription))

        Current Key Concepts:
        \(emptyFallback(snapshot.synthesizedKeyConceptsText))

        Current Background Context:
        \(emptyFallback(snapshot.synthesizedBackgroundContext))

        TASK

        Produce:
        1. An evolving collection description based on what has been learned from reviewed nodes.
        2. Key concepts emerging across reviewed branches.
        3. Background context that would help future idea refinement.

        IMPORTANT

        The user-provided headline and summary are orientation only.
        Do not simply restate the user summary.
        Use reviewed node evidence as the main source.
        Improve the existing synthesized context rather than starting over.
        Prefer synthesis over repetition.
        Do not invent unrelated product strategy.
        Do not create todos.
        Do not mention that some nodes were omitted.
        """
    }

    private func reviewedNodes(from nodes: [CollectionReviewNodeSnapshot]) -> [CollectionReviewNodeSnapshot] {
        nodes
            .filter { node in
                let status = node.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                return status == "refined" || status == "question" || status == "actionable" || status == "implemented" || status == "done"
            }
            .sorted { lhs, rhs in
                if lhs.depth != rhs.depth { return lhs.depth < rhs.depth }
                return lhs.title < rhs.title
            }
            .prefix(16)
            .map { $0 }
    }

    private func nodeEvidenceText(for nodes: [CollectionReviewNodeSnapshot]) -> String {
        guard !nodes.isEmpty else {
            return "None"
        }

        return nodes.map { node in
            let indent = String(repeating: "  ", count: min(node.depth, 4))
            return """
            \(indent)- Path: \(shorten(node.path.joined(separator: " > "), limit: 160))
            \(indent)  Status: \(emptyFallback(node.status))
            \(indent)  Title: \(shorten(node.title, limit: 90))
            \(indent)  Content: \(shorten(primaryContent(for: node), limit: 220))
            """
        }
        .joined(separator: "\n")
    }

    private func primaryContent(for node: CollectionReviewNodeSnapshot) -> String {
        let summary = node.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !summary.isEmpty { return summary }

        let refined = node.refinedText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !refined.isEmpty { return refined }

        let interpretation = node.modelInterpretation.trimmingCharacters(in: .whitespacesAndNewlines)
        if !interpretation.isEmpty { return interpretation }

        return node.rawCapture
    }

    private func shorten(_ text: String, limit: Int) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "None" }
        guard trimmed.count > limit else { return trimmed }
        return String(trimmed.prefix(limit)) + "…"
    }

    private func emptyFallback(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "None" : trimmed
    }
}
#endif
