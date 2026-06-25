//
//  IdeaOutlineView.swift
//  IdeaUX
//
//  Created by LouR on 6/20/26.
//

import SwiftUI
import SwiftData

struct IdeaOutlineView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    let collection: IdeaCollection
    let ideas: [IdeaNode]
    let onNodeApproved: (() -> Void)?

    @State private var expanded: Set<UUID> = []
    @State private var focusedNodeID: UUID?
    @State private var copiedBranchRootID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                let focusedNode = focusedNodeID.flatMap { id in
                    ideas.first { $0.id == id }
                }
                
                if let focusedNode {
                    IdeaHierarchyPathView(items: focusPathItems(for: focusedNode)) { item in
                        if let node = item.node {
                            focusedNodeID = node.id
                        } else {
                            focusedNodeID = nil
                        }
                    }
                    .padding(.bottom, 6)
                }

                let roots = focusedNode.map { [$0] } ?? ideas
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
                .contextMenu {
                    Button {
                        focusedNodeID = node.id
                        expanded.insert(node.id)
                    } label: {
                        Label("Focus Branch", systemImage: "scope")
                    }

                    Button {
                        copyBranch(node)
                    } label: {
                        Label("Copy Branch", systemImage: "doc.on.doc")
                    }

                    if copiedBranchRootID != nil {
                        Button {
                            pasteCopiedBranch(under: node)
                        } label: {
                            Label("Paste Branch Here", systemImage: "doc.on.clipboard")
                        }
                        Button {
                                pasteCopiedBranch(under: node, deleteOriginal: true)
                            } label: {
                                Label("Move Branch Here", systemImage: "arrow.turn.down.right")
                            }
                    }
                }

                if hasChildren && expanded.contains(node.id) {
                    ForEach(kids, id: \.persistentModelID) { child in
                        outlineNode(child, all: all, depth: depth + 1)
                    }
                }
            }
        )
    }

    
    private func focusPathItems(for node: IdeaNode) -> [IdeaHierarchyPathItem] {
        var items = [
            IdeaHierarchyPathItem(
                id: collection.id.uuidString,
                title: collection.name,
                node: nil
            )
        ]

        var parents: [IdeaNode] = []
        var currentParentID = node.parentID

        while let parentID = currentParentID,
              let parent = ideas.first(where: { $0.id == parentID }) {
            parents.insert(parent, at: 0)
            currentParentID = parent.parentID
        }

        items.append(contentsOf: parents.map {
            IdeaHierarchyPathItem(
                id: $0.id.uuidString,
                title: titleForPath($0),
                node: $0
            )
        })

        items.append(
            IdeaHierarchyPathItem(
                id: node.id.uuidString,
                title: titleForPath(node),
                node: node
            )
        )

        return items
    }

    private func titleForPath(_ node: IdeaNode) -> String {
        let title = node.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty { return title }

        let raw = node.rawCapture.trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty { return String(raw.prefix(48)) }

        return "Untitled"
    }
    
    private func copyBranch(_ node: IdeaNode) {
        copiedBranchRootID = node.id
    }

    private func pasteCopiedBranch(under parent: IdeaNode) {
        guard let sourceRootID = copiedBranchRootID,
              let sourceRoot = ideas.first(where: { $0.id == sourceRootID }) else {
            return
        }
            guard sourceRoot.id != parent.id else { return }
            guard !descendants(of: sourceRoot, in: ideas).contains(where: { $0.id == parent.id }) else {
                return
        }

        let pastedRoot = cloneSubtree(
            from: sourceRoot,
            under: parent,
            all: ideas
        )

        expanded.insert(parent.id)
        expanded.insert(pastedRoot.id)
        focusedNodeID = pastedRoot.id

        try? modelContext.save()
    }
    
    private func pasteCopiedBranch(under parent: IdeaNode, deleteOriginal: Bool = false) {
        guard let sourceRootID = copiedBranchRootID,
              let sourceRoot = ideas.first(where: { $0.id == sourceRootID }) else {
            return
        }

        guard sourceRoot.id != parent.id else { return }
        guard !descendants(of: sourceRoot, in: ideas).contains(where: { $0.id == parent.id }) else {
            return
        }

        let pastedRoot = cloneSubtree(
            from: sourceRoot,
            under: parent,
            all: ideas
        )

        if deleteOriginal {
            deleteSubtree(sourceRoot, all: ideas)
            copiedBranchRootID = nil
        }

        expanded.insert(parent.id)
        expanded.insert(pastedRoot.id)
        focusedNodeID = pastedRoot.id

        try? modelContext.save()
    }
    
    private func deleteSubtree(_ node: IdeaNode, all: [IdeaNode]) {
        let kids = children(of: node, in: all)
        for child in kids {
            deleteSubtree(child, all: all)
        }
        modelContext.delete(node)
    }

    @discardableResult
    private func cloneSubtree(
        from source: IdeaNode,
        under parent: IdeaNode?,
        all: [IdeaNode]
    ) -> IdeaNode {
        let clone = IdeaNode(rawCapture: source.rawCapture)

        clone.title = source.title
        clone.refinedText = source.refinedText
        clone.summary = source.summary
        clone.status = source.status
        clone.nodeType = source.nodeType
        clone.nextQuestionsText = source.nextQuestionsText
        clone.modelInterpretation = source.modelInterpretation
        clone.modelQuestionsText = source.modelQuestionsText
        clone.modelRelatedIdeasText = source.modelRelatedIdeasText
        clone.modelNextStepsText = source.modelNextStepsText
        clone.lastAnalyzedAt = source.lastAnalyzedAt
        clone.implementedAt = source.implementedAt
        clone.collectionID = collection.id
        clone.collection = collection
        clone.parentID = parent?.id
        clone.parent = parent
        clone.sortOrder = nextSortOrder(under: parent, in: all)
        clone.updatedAt = Date()

        modelContext.insert(clone)

        let sourceChildren = children(of: source, in: all)
        for child in sourceChildren {
            cloneSubtree(from: child, under: clone, all: all)
        }

        return clone
    }

    private func nextSortOrder(under parent: IdeaNode?, in all: [IdeaNode]) -> Int {
        let siblings = all.filter { node in
            node.collectionID == collection.id && node.parentID == parent?.id
        }

        return (siblings.map { $0.sortOrder }.max() ?? 0) + 1
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
        IdeaNodeDisplayStatus.statusKey(for: node)
    }

    private func descendants(of node: IdeaNode, in all: [IdeaNode]) -> [IdeaNode] {
        let directChildren = children(of: node, in: all)
        return directChildren + directChildren.flatMap { descendants(of: $0, in: all) }
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
