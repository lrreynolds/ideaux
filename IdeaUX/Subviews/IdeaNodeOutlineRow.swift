import SwiftUI
import SwiftData

struct IdeaNodeOutlineRow: View {
    let node: IdeaNode
    let depth: Int
    let hasChildren: Bool
    @Binding var isExpanded: Bool

    var statusSymbol: String {
        if node.status.lowercased() == "question" || node.nodeType.lowercased() == "question" {
            return "?"
        }

        switch node.status.lowercased() {
        case "done", "implemented":
            return "✓"
        case "actionable":
            return "⚡"
        case "refined":
            return hasChildren ? "🌳" : "🌿"
        case "refining":
            return "…"
        default:
            if hasChildren && hasMeaningfulRefinement { return "🌳" }
            return hasMeaningfulRefinement ? "🌿" : "🌱"
        }
    }

    var statusColor: Color {
        if node.status.lowercased() == "question" || node.nodeType.lowercased() == "question" {
            return .red
        }

        switch node.status.lowercased() {
        case "done", "implemented":
            return .secondary
        case "actionable":
            return .orange
        case "refining":
            return .secondary
        default:
            return .primary
        }
    }

    var hasMeaningfulRefinement: Bool {
        let title = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        let raw = node.rawCapture.trimmingCharacters(in: .whitespacesAndNewlines)
        let refined = node.refinedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let summary = node.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let interpretation = node.modelInterpretation.trimmingCharacters(in: .whitespacesAndNewlines)

        if !interpretation.isEmpty { return true }
        if !summary.isEmpty && summary != title && summary != raw { return true }
        if !refined.isEmpty && refined != title && refined != raw { return true }

        return false
    }

    var subtitleText: String? {
        let candidates = [
            node.summary,
            node.refinedText,
            node.modelInterpretation
        ]

        for candidate in candidates {
            let text = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            guard text != titleText else { continue }
            guard text != node.rawCapture.trimmingCharacters(in: .whitespacesAndNewlines) else { continue }
            return text
        }

        return nil
    }

    var titleStyle: Font.Weight {
        hasMeaningfulRefinement ? .medium : .regular
    }

    var titleColor: Color {
        hasMeaningfulRefinement ? .primary : .secondary
    }

    var titleText: String {
        let title = node.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty { return title }

        let raw = node.rawCapture.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? "Untitled" : raw
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Color.clear.frame(width: CGFloat(depth) * 18)

            if hasChildren {
                Button {
                    isExpanded.toggle()
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 24)
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 20, height: 24)
            }

            Text(statusSymbol)
                .foregroundStyle(statusColor)
                .fontWeight((node.status.lowercased() == "question" || node.nodeType.lowercased() == "question") ? .bold : .regular)
                .frame(width: 22, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(titleText)
                    .font(.body)
                    .fontWeight(titleStyle)
                    .foregroundStyle(titleColor)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitleText {
                    Text(subtitleText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }
}
