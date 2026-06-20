import Foundation

struct IdeaTreeExporter {
    static func exportMarkdown(for collection: IdeaCollection, ideas: [IdeaNode]) -> String {
        var lines: [String] = []

        lines.append("# \(collection.name)")
        lines.append("")

        let summary = collection.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !summary.isEmpty {
            lines.append(summary)
            lines.append("")
        }

        appendContextSection(title: "Purpose", text: collection.purpose, to: &lines)
        appendContextSection(title: "Goals", text: collection.goalsText, to: &lines)
        appendContextSection(title: "Key Concepts", text: collection.keyConceptsText, to: &lines)
        appendContextSection(title: "Background Context", text: collection.backgroundContext, to: &lines)
        appendContextSection(title: "Refinement Instructions", text: collection.refinementInstructions, to: &lines)

        let roots = ideas
            .filter { $0.parentID == nil }
            .sorted { lhs, rhs in
                if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                return lhs.createdAt < rhs.createdAt
            }

        if !roots.isEmpty {
            lines.append("## Idea Tree")
            lines.append("")

            for root in roots {
                appendMarkdownNode(root, all: ideas, depth: 0, to: &lines)
            }
        }

        return lines.joined(separator: "\n")
    }

    private static func appendContextSection(title: String, text: String, to lines: inout [String]) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        lines.append("## \(title)")
        lines.append("")
        lines.append(trimmed)
        lines.append("")
    }

    private static func appendMarkdownNode(_ node: IdeaNode, all: [IdeaNode], depth: Int, to lines: inout [String]) {
        let indent = String(repeating: "  ", count: depth)
        let title = markdownTitle(for: node)
        let metadata = exportMetadata(for: node)

        if metadata.isEmpty {
            lines.append("\(indent)- \(title)")
        } else {
            lines.append("\(indent)- \(title) _(\(metadata.joined(separator: " • ")))_")
        }

        let raw = node.rawCapture.trimmingCharacters(in: .whitespacesAndNewlines)
        let refined = node.refinedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let summary = node.summary.trimmingCharacters(in: .whitespacesAndNewlines)

        let meaningfulSummary =
            !refined.isEmpty &&
            refined != title &&
            refined != raw

        if meaningfulSummary {
            lines.append("\(indent)  - Summary: \(refined)")
        } else if !summary.isEmpty && summary != title && summary != raw {
            lines.append("\(indent)  - Summary: \(summary)")
        }

        let kids = children(of: node, in: all)
        for child in kids {
            appendMarkdownNode(child, all: all, depth: depth + 1, to: &lines)
        }
    }

    private static func children(of node: IdeaNode, in all: [IdeaNode]) -> [IdeaNode] {
        all.filter { $0.parentID == node.id }
            .sorted { lhs, rhs in
                if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                return lhs.createdAt < rhs.createdAt
            }
    }

    private static func exportMetadata(for node: IdeaNode) -> [String] {
        var metadata: [String] = []

        let type = node.nodeType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let status = node.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if type == "question" {
            metadata.append("Question")
        }

        switch status {
        case "done", "implemented":
            metadata.append("Done")
        case "active", "actionable", "refining", "exploring", "growing":
            metadata.append("Active")
        case "archived", "rejected":
            metadata.append("Archived")
        default:
            break
        }

        return metadata
    }

    private static func markdownTitle(for node: IdeaNode) -> String {
        let title = node.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty { return title }

        let raw = node.rawCapture.trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty { return raw }

        return "Untitled"
    }
}
