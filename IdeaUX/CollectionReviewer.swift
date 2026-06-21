
import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

#if canImport(FoundationModels)
struct CollectionReviewer {
    func review(snapshot: CollectionReviewSnapshot) async throws -> CollectionReviewSuggestion {
        let prompt = collectionReviewPrompt(for: snapshot)

        let session = LanguageModelSession(instructions: """
        You review an evolving personal idea tree.

        The tree is the source of truth.
        Your job is not to rewrite the tree.
        Your job is to identify nodes that appear to need user attention.

        Review the full node data, not just titles.
        Use summaries, interpretations, questions, related ideas, next steps, status, path, and children.

        Recommend status changes only when useful.

        Use recommendedStatus = question only when the node itself is primarily an unanswered question or unresolved point of clarification.

        Use recommendedStatus = actionable only when the node describes something the user could reasonably do next.

        Use recommendedStatus = none when no user attention state is needed.

        Never recommend implemented or done. Completion is a user decision.
        Do not mark a parent as question only because a child is a question.
        Do not mark a parent as actionable only because a child is actionable.
        Prefer fewer, higher-confidence recommendations.
        """)

        let response = try await session.respond(
            to: prompt,
            generating: CollectionReviewSuggestion.self
        )

        return response.content
    }

    private func collectionReviewPrompt(for snapshot: CollectionReviewSnapshot) -> String {
        """
        Review this ideauX collection tree and recommend node attention statuses.

        COLLECTION

        Name:
        \(snapshot.collectionName)

        Summary:
        \(emptyFallback(snapshot.collectionSummary))

        Purpose:
        \(emptyFallback(snapshot.purpose))

        Goals:
        \(emptyFallback(snapshot.goals))

        Key Concepts:
        \(emptyFallback(snapshot.keyConcepts))

        Background Context:
        \(emptyFallback(snapshot.backgroundContext))

        Refinement Instructions:
        \(emptyFallback(snapshot.refinementInstructions))

        NODE DATA
        
        \(nodeDataText(for: reviewCandidates(from: snapshot.nodes)))

        TASK

        Return nodeUpdates for nodes whose attention status should change.

        For each update:
        - nodeID must exactly match one node id from NODE DATA.
        - recommendedStatus must be question, actionable, or none.
        - reason should briefly explain why.

        STATUS RULES

        question:
        Use when the node itself is an unresolved question, uncertainty, or clarification point.

        actionable:
        Use when the node describes a concrete next action, implementation task, decision, or follow-up the user could do.

        none:
        Use when the node is an idea, concept, observation, branch heading, summary, or already sufficiently classified.

        IMPORTANT

        Do not recommend implemented or done.
        Do not classify branch headings as question/actionable merely because descendants contain questions or todos.
        Do not recommend changes for every node.
        Prefer a short, high-signal list.
        """
    }

    private func reviewCandidates(from nodes: [CollectionReviewNodeSnapshot]) -> [CollectionReviewNodeSnapshot] {
        let scored = nodes.map { node in
            (node: node, score: reviewPriorityScore(for: node))
        }

        return scored
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.node.depth > rhs.node.depth
            }
            .prefix(24)
            .map(\.node)
    }

    private func reviewPriorityScore(for node: CollectionReviewNodeSnapshot) -> Int {
        var score = 0

        let status = node.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let type = node.nodeType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let title = node.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let summary = node.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let refined = node.refinedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let interpretation = node.modelInterpretation.trimmingCharacters(in: .whitespacesAndNewlines)
        let questions = node.modelQuestionsText.trimmingCharacters(in: .whitespacesAndNewlines)
        let nextSteps = node.modelNextStepsText.trimmingCharacters(in: .whitespacesAndNewlines)

        if status == "implemented" || status == "done" { score -= 100 }
        if status == "question" || type == "question" { score += 40 }
        if status == "actionable" { score += 35 }
        if status == "seed" || status == "refining" { score += 20 }
        if !questions.isEmpty { score += 20 }
        if !nextSteps.isEmpty { score += 15 }
        if !summary.isEmpty && summary != title { score += 12 }
        if !refined.isEmpty && refined != title { score += 10 }
        if !interpretation.isEmpty { score += 8 }
        if node.childIDs.isEmpty { score += 6 }
        if node.depth > 0 { score += min(node.depth, 4) }

        return score
    }

    private func nodeDataText(for nodes: [CollectionReviewNodeSnapshot]) -> String {
        nodes.map { node in
            let indent = String(repeating: "  ", count: node.depth)
            return """
            \(indent)- Node ID: \(node.id.uuidString)
            \(indent)  Path: \(shorten(node.path.joined(separator: " > "), limit: 220))
            \(indent)  Status: \(emptyFallback(node.status))
            \(indent)  Type: \(emptyFallback(node.nodeType))
            \(indent)  Title: \(shorten(node.title, limit: 120))
            \(indent)  Summary: \(shorten(primaryContent(for: node), limit: 260))
            \(indent)  Questions: \(shorten(node.modelQuestionsText, limit: 220))
            \(indent)  Next Steps: \(shorten(node.modelNextStepsText, limit: 220))
            \(indent)  Child Count: \(node.childIDs.count)
            """
        }
        .joined(separator: "\n\n")
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
