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
                    IdeaNodeDetailView(node: node, collection: collection)
                } label: {
                    IdeaNodeOutlineRow(
                        node: node,
                        depth: depth,
                        hasChildren: hasChildren,
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
        IdeaOutlineView(collection: collection, ideas: [])
            .padding()
    }
}
