
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
        Review these ideauX nodes. Return only high-confidence status changes.

        Collection: \(snapshot.collectionName)
        
        \(nodeDataText(for: reviewCandidates(from: snapshot.nodes)))

             Rules:
             - nodeID must exactly match a listed id.
             - recommendedStatus: question, actionable, or none.
             - question = node itself is unresolved.
             - actionable = the node already describes a specific concrete action the user can do.
             - Do not invent actions from a broad idea.
             - Do not classify generated next steps as the node status.
             - none = clear stale question/actionable.
             - never recommend done/implemented.
             - do not classify parents only because children need attention.
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
            .prefix(8)
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
        if !nextSteps.isEmpty { score += 2 }
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
                       \(indent)- id: \(node.id.uuidString)
                       \(indent)  path: \(shorten(node.path.joined(separator: " > "), limit: 80))
                       \(indent)  status: \(emptyFallback(node.status)); type: \(emptyFallback(node.nodeType)); children: \(node.childIDs.count)
                       \(indent)  title: \(shorten(node.title, limit: 60))
                       \(indent)  content: \(shorten(primaryContent(for: node), limit: 90))
                       \(indent)  q: \(shorten(node.modelQuestionsText, limit: 60))
                       \(indent)  next: \(shorten(node.modelNextStepsText, limit: 60))
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
