import SwiftUI
import SwiftData

struct IdeaNodeOutlineRow: View {
    let node: IdeaNode
    let depth: Int
    let hasChildren: Bool
    let displayStatus: String?
    @Binding var isExpanded: Bool

    private var effectiveStatus: String {
        let explicitStatus = displayStatus?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if let explicitStatus, !explicitStatus.isEmpty {
            return explicitStatus
        }

        return IdeaNodeDisplayStatus.statusKey(for: node)
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
        IdeaNodeDisplayStatus.displayStatus(for: effectiveStatus).titleWeight
    }

    var titleColor: Color {
        IdeaNodeDisplayStatus.displayStatus(for: effectiveStatus).titleColor
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

            Text(IdeaNodeDisplayStatus.displayStatus(for: effectiveStatus).symbol)
                .foregroundStyle(IdeaNodeDisplayStatus.displayStatus(for: effectiveStatus).color)
                .fontWeight(effectiveStatus == "question" ? .bold : .regular)
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
