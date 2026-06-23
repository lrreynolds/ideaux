//
//  IdeaContextBuilder.swift
//  IdeaUX
//
//  Created by LouR on 6/18/26.
//

import Foundation

struct IdeaContextBuilder {

    static func snapshot(
        collection: IdeaCollection,
        node: IdeaNode?,
        allNodes: [IdeaNode]
    ) -> IdeaContextSnapshot {

        // Helpers
        func displayTitle(for n: IdeaNode) -> String {
            let t = n.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { return t }
            let raw = n.rawCapture.trimmingCharacters(in: .whitespacesAndNewlines)
            return raw.isEmpty ? "Untitled" : String(raw.prefix(80))
        }
        func displayContent(for n: IdeaNode) -> String {
            let refined = n.refinedText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !refined.isEmpty { return refined }
            return n.rawCapture
        }

        // Build parent path from root -> parent of current node
        var parentTitles: [String] = []
        if let current = node {
            var cursor: IdeaNode? = current
            // climb to root, collecting parents (exclude current)
            while let parentID = cursor?.parentID {
                if let parentNode = allNodes.first(where: { $0.id == parentID }) {
                    parentTitles.append(displayTitle(for: parentNode))
                    cursor = parentNode
                } else {
                    break
                }
            }
            parentTitles.reverse() // root -> ... -> direct parent
        }

        // Current node fields
        let currentTitle: String = {
            guard let n = node else { return "" }
            return displayTitle(for: n)
        }()
        let currentContent: String = {
            guard let n = node else { return "" }
            return displayContent(for: n)
        }()

        // Siblings: same parentID, excluding current node
        let siblingTitles: [String] = {
            guard let n = node else { return [] }
            let siblings = allNodes
                .filter { $0.collectionID == collection.id && $0.parentID == n.parentID && $0.id != n.id }
                .sorted { lhs, rhs in
                    if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                    return lhs.createdAt < rhs.createdAt
                }
            return siblings.map { displayTitle(for: $0) }
        }()

        // Children: nodes with parentID == current node id
        let childTitles: [String] = {
            guard let n = node else { return [] }
            let kids = allNodes
                .filter { $0.collectionID == collection.id && $0.parentID == n.id }
                .sorted { lhs, rhs in
                    if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                    return lhs.createdAt < rhs.createdAt
                }
            return kids.map { displayTitle(for: $0) }
        }()

        return IdeaContextSnapshot(
            collectionName: collection.name,
            collectionHeadline: collection.headline,
            collectionSummary: collection.summary,
            synthesizedDescription: collection.synthesizedDescription,
            synthesizedKeyConceptsText: collection.synthesizedKeyConceptsText,
            synthesizedBackgroundContext: collection.synthesizedBackgroundContext,
            parentPath: parentTitles,
            currentNodeTitle: currentTitle,
            currentNodeContent: currentContent,
            siblingTitles: siblingTitles,
            childTitles: childTitles
        )
    }
}
