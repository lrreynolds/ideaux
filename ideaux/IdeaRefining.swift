import Foundation

/// A service that can refine idea content locally or via an AI backend.
/// Replace the mock implementation with a Foundation Models–backed implementation later.
public protocol IdeaRefining {
    /// Generate a concise title for the idea.
    func generateTitle(from rawCapture: String) -> String
    /// Generate a short summary explaining why the idea matters / key points.
    func generateSummary(from rawCapture: String) -> String
    /// Generate follow-up questions that move the idea forward.
    func generateQuestions(from rawCapture: String) -> [String]
    /// Generate human-readable connection labels to related ideas (placeholder strings for now).
    func generateConnections(from rawCapture: String) -> [String]
}

/// A deterministic, local mock used for development and previews.
public struct MockIdeaRefiner: IdeaRefining {
    public init() {}

    public func generateTitle(from rawCapture: String) -> String {
        // Use first non-empty line capped to 60 chars
        let firstLine = rawCapture.split(separator: "\n").first.map(String.init) ?? rawCapture
        let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled Idea" : String(trimmed.prefix(60))
    }

    public func generateSummary(from rawCapture: String) -> String {
        let words = rawCapture.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
        let snippet = words.prefix(30).joined(separator: " ")
        if snippet.isEmpty { return "No summary available." }
        return "Summary: \(snippet)\(words.count > 30 ? "…" : "")"
    }

    public func generateQuestions(from rawCapture: String) -> [String] {
        let base: [String] = [
            "What’s the smallest experiment to validate this?",
            "Who benefits the most and why?",
            "What assumptions are we making?",
            "What would make this idea 10x better?"
        ]
        // Add a deterministic extra question based on content length
        let extra = rawCapture.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "What is the core problem this solves in one sentence?"
        return extra != nil ? base + [extra!] : base
    }

    public func generateConnections(from rawCapture: String) -> [String] {
        // Very simple keyword-based mock connections
        let lower = rawCapture.lowercased()
        var related: [String] = []
        if lower.contains("onboarding") { related.append("Related: Onboarding flow improvements") }
        if lower.contains("ai") || lower.contains("assistant") { related.append("Related: AI-assisted drafting") }
        if lower.contains("tag") { related.append("Related: Tagging taxonomy") }
        if related.isEmpty {
            related = ["Related: Similar brainstorming session", "Related: Adjacent feature request"]
        }
        return related
    }
}
