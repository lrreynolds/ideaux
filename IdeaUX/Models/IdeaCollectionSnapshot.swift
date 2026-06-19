//
//  IdeaCollectionSnapshot.swift
//  IdeaUX
//
//  Created by LouR on 6/19/26.
//

import Foundation
import SwiftData

@Model
final class IdeaCollectionSnapshot {
    var id: UUID
    var collectionID: UUID
    var collectionName: String
    var createdAt: Date
    var reason: String
    var payloadJSON: String

    init(
        id: UUID = UUID(),
        collectionID: UUID,
        collectionName: String,
        createdAt: Date = Date(),
        reason: String,
        payloadJSON: String
    ) {
        self.id = id
        self.collectionID = collectionID
        self.collectionName = collectionName
        self.createdAt = createdAt
        self.reason = reason
        self.payloadJSON = payloadJSON
    }
}
