//
//  IdeaOutlineView.swift
//  IdeaUX
//
//  Created by LouR on 6/20/26.
//

import SwiftUI
import SwiftData

struct IdeaOutlineView: View {
    let collection: IdeaCollection
    let ideas: [IdeaNode]
    let onNodeApproved: (() -> Void)?

    @State private var expanded: Set<UUID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                let roots = ideas
                    .filter { $0.parentID == nil }
                    .sorted { lhs, rhs in
                        if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                        return lhs.createdAt < rhs.createdAt
                    }

                if roots.isEmpty {
                    Text("No ideas captured yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(roots, id: \.persistentModelID) { root in
                        outlineNode(root, all: ideas, depth: 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func outlineNode(_ node: IdeaNode, all: [IdeaNode], depth: Int) -> AnyView {
        let kids = children(of: node, in: all)
        let hasChildren = !kids.isEmpty

        return AnyView(
            VStack(alignment: .leading, spacing: 0) {
                NavigationLink {
                    IdeaNodeDetailView(
                        node: node,
                        collection: collection,
                        onApproved: onNodeApproved
                    )
                } label: {
                    IdeaNodeOutlineRow(
                        node: node,
                        depth: depth,
                        hasChildren: hasChildren,
                        displayStatus: effectiveStatus(for: node, in: all),
                        isExpanded: Binding(
                            get: { expanded.contains(node.id) },
                            set: { newValue in
                                if newValue {
                                    expanded.insert(node.id)
                                } else {
                                    expanded.remove(node.id)
                                }
                            }
                        )
                    )
                }
                .buttonStyle(.plain)

                if hasChildren && expanded.contains(node.id) {
                    ForEach(kids, id: \.persistentModelID) { child in
                        outlineNode(child, all: all, depth: depth + 1)
                    }
                }
            }
        )
    }

    private func effectiveStatus(for node: IdeaNode, in all: [IdeaNode]) -> String {
        let ownStatus = normalizedStatus(for: node)

        if expanded.contains(node.id) {
            return ownStatus
        }

        let descendants = descendants(of: node, in: all)
        let descendantStatuses = descendants.map { normalizedStatus(for: $0) }

        if ownStatus == "implemented" { return "implemented" }
        if ownStatus == "actionable" { return "actionable" }
        if ownStatus == "question" { return "question" }

        if descendantStatuses.contains("question") { return "question" }
        if descendantStatuses.contains("actionable") { return "actionable" }
        if !descendants.isEmpty && descendantStatuses.allSatisfy({ $0 == "implemented" }) { return "implemented" }

        return ownStatus
    }

    private func normalizedStatus(for node: IdeaNode) -> String {
        let status = node.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let type = node.nodeType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if status == "implemented" || status == "done" { return "implemented" }
        if status == "actionable" { return "actionable" }
        if status == "question" { return "question" }
        if status == "refined" { return "refined" }
        if hasMeaningfulRefinement(node) { return "refined" }
        return "seed"
    }

    private func descendants(of node: IdeaNode, in all: [IdeaNode]) -> [IdeaNode] {
        let directChildren = children(of: node, in: all)
        return directChildren + directChildren.flatMap { descendants(of: $0, in: all) }
    }

    private func hasMeaningfulRefinement(_ node: IdeaNode) -> Bool {
        let title = node.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let raw = node.rawCapture.trimmingCharacters(in: .whitespacesAndNewlines)
        let refined = node.refinedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let summary = node.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let interpretation = node.modelInterpretation.trimmingCharacters(in: .whitespacesAndNewlines)

        if !interpretation.isEmpty { return true }
        if !summary.isEmpty && summary != title && summary != raw { return true }
        if !refined.isEmpty && refined != title && refined != raw { return true }

        return false
    }

    private func children(of node: IdeaNode, in all: [IdeaNode]) -> [IdeaNode] {
        all.filter { $0.parentID == node.id }
            .sorted { lhs, rhs in
                if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                return lhs.createdAt < rhs.createdAt
            }
    }
}

#Preview("Idea Outline") {
    let collection = IdeaCollection(
        name: "Demo Collection",
        summary: "Demo outline"
    )

    NavigationStack {
        IdeaOutlineView(
            collection: collection,
            ideas: [],
            onNodeApproved: nil
        )
        .padding()
    }
}
