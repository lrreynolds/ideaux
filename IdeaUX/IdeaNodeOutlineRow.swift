import SwiftUI
import SwiftData

struct IdeaNodeOutlineRow: View {
    let node: IdeaNode
    let depth: Int
    let hasChildren: Bool
    @Binding var isExpanded: Bool

    var statusSymbol: String {
        switch node.status.lowercased() {
        case "seed": return "🌱"
        case "active": return "🔨"
        case "done", "implemented": return "✓"
        case "archived": return "📦"
        default: return "🌱"
        }
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
                .frame(width: 22, alignment: .center)

            Text(titleText)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }
}
