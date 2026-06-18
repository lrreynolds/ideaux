import SwiftUI
import SwiftData

struct IdeaNodeOutlineRow: View {
    let node: IdeaNode
    let depth: Int
    let hasChildren: Bool
    @Binding var isExpanded: Bool

    var statusSymbol: String {
        let s = node.status.lowercased()
        switch s {
        case "seed": return "🌱"
        case "exploring", "refining", "growing": return "🌿"
        case "actionable": return "●"
        case "implemented": return "✓"
        case "validated": return "★"
        case "rejected": return "✕"
        case "archived": return "📦"
        default: return "•"
        }
    }

    var titleText: String {
        let title = node.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty { return title }
        let raw = node.rawCapture.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? "Untitled" : String(raw.prefix(60))
    }

    var body: some View {
        HStack(spacing: 8) {
            // Indentation
            Color.clear.frame(width: CGFloat(depth) * 14)

            // Disclosure
            if hasChildren {
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            } else {
                // keep alignment
                Color.clear.frame(width: 20, height: 20)
            }

            // Status symbol
            Text(statusSymbol)

            VStack(alignment: .leading, spacing: 2) {
                NavigationLink(value: node) {
                    Text(titleText)
                        .font(.body)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                }
                HStack(spacing: 8) {
                    Group{
                        Text(node.nodeType.capitalized)
                        Text("•")
                        Text(node.status.capitalized)
                    }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if node.priority.lowercased() == "high" {
                        Text("High")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }
}

