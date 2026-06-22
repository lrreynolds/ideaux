//
//  IdeaNodeDisplayStatus.swift
//  IdeaUX
//
//  Created by LouR on 6/22/26.
//

import Foundation
import SwiftUI

struct IdeaNodeDisplayStatus {
    let symbol: String
    let color: Color
    let isReviewed: Bool
    let titleWeight: Font.Weight
    let titleColor: Color

    static func statusKey(for node: IdeaNode) -> String {
        let status = node.status
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch status {
        case "implemented", "done":
            return "implemented"
        case "actionable":
            return "actionable"
        case "question":
            return "question"
        case "refined":
            return "refined"
        case "refining":
            return "refining"
        default:
            return "seed"
        }
    }

    static func displayStatus(for statusKey: String) -> IdeaNodeDisplayStatus {
        switch statusKey {
        case "question":
            return IdeaNodeDisplayStatus(
                symbol: "?",
                color: .red,
                isReviewed: true,
                titleWeight: .medium,
                titleColor: .primary
            )
        case "implemented":
            return IdeaNodeDisplayStatus(
                symbol: "✓",
                color: .secondary,
                isReviewed: true,
                titleWeight: .medium,
                titleColor: .primary
            )
        case "actionable":
            return IdeaNodeDisplayStatus(
                symbol: "⚡",
                color: .orange,
                isReviewed: true,
                titleWeight: .medium,
                titleColor: .primary
            )
        case "refined":
            return IdeaNodeDisplayStatus(
                symbol: "🌿",
                color: .primary,
                isReviewed: true,
                titleWeight: .medium,
                titleColor: .primary
            )
        case "refining":
            return IdeaNodeDisplayStatus(
                symbol: "…",
                color: .secondary,
                isReviewed: false,
                titleWeight: .regular,
                titleColor: .secondary
            )
        default:
            return IdeaNodeDisplayStatus(
                symbol: "🌱",
                color: .primary,
                isReviewed: false,
                titleWeight: .regular,
                titleColor: .secondary
            )
        }
    }
}
