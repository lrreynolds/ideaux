//
//  IdeaTreeImporterTests.swift
//  IdeaUXTests
//
//  Created by LouR on 6/20/26.
//

import Foundation
import SwiftData
import Testing
@testable import IdeaUX

@Suite("IdeaTreeExporterImporter")
struct IdeaTreeExporterImporterTests {

    @Test("Importer restores summary metadata")
    @MainActor
    func importerRestoresSummaryMetadata() throws {

        let markdown = """
        # Test Collection

        ## Idea Tree

        - Parent Idea
          - Summary: This is the refined summary.
          - Child Idea
        """

        let container = try ModelContainer(
            for: IdeaCollection.self,
                IdeaProject.self,
                IdeaNode.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        let context = container.mainContext

        let collection = IdeaTreeImporter.importMarkdownAsCollection(
            markdown,
            context: context
        )

        #expect(collection != nil)

        let nodes = try context.fetch(FetchDescriptor<IdeaNode>())

        let parent = nodes.first { $0.title == "Parent Idea" }

        #expect(parent != nil)
        #expect(parent?.summary == "This is the refined summary.")
        #expect(parent?.refinedText == "This is the refined summary.")

        let bogusSummaryNode = nodes.first {
            $0.title.contains("Summary:")
        }

        #expect(bogusSummaryNode == nil)
    }
    
    @Test("Importer preserves child hierarchy when summaries are present")
    @MainActor
    func importerPreservesChildHierarchyWhenSummariesArePresent() throws {

        let markdown = """
        # Test Collection

        ## Idea Tree

        - Parent Idea
          - Summary: This is the refined summary.
          - Child Idea
        """

        let container = try ModelContainer(
            for: IdeaCollection.self,
                IdeaProject.self,
                IdeaNode.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        let context = container.mainContext

        let collection = IdeaTreeImporter.importMarkdownAsCollection(
            markdown,
            context: context
        )

        #expect(collection != nil)

        let nodes = try context.fetch(FetchDescriptor<IdeaNode>())

        let parent = nodes.first { $0.title == "Parent Idea" }
        let child = nodes.first { $0.title == "Child Idea" }

        #expect(parent != nil)
        #expect(child != nil)
        #expect(child?.parentID == parent?.id)
        #expect(child?.collectionID == collection?.id)
    }
    
    @Test("Exporter importer round trips summaries")
    @MainActor
    func exporterImporterRoundTripsSummaries() throws {

        let container = try ModelContainer(
            for: IdeaCollection.self,
                IdeaProject.self,
                IdeaNode.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        let context = container.mainContext

        let collection = IdeaCollection(
            name: "Test Collection"
        )

        context.insert(collection)

        let node = IdeaNode(rawCapture: "Original thought")
        node.title = "Important Idea"
        node.refinedText = "This is the important summary."
        node.summary = "This is the important summary."
        node.collection = collection
        node.collectionID = collection.id

        context.insert(node)

        try context.save()

        let markdown = IdeaTreeExporter.exportMarkdown(
            for: collection,
            ideas: [node]
        )

        let importedCollection =
            IdeaTreeImporter.importMarkdownAsCollection(
                markdown,
                context: context,
                mode: .createNewCopy
            )

        #expect(importedCollection != nil)

        let nodes = try context.fetch(FetchDescriptor<IdeaNode>())

        let importedNode = nodes.first {
            $0.collectionID == importedCollection?.id &&
            $0.title == "Important Idea"
        }

        #expect(importedNode != nil)
        #expect(importedNode?.summary == "This is the important summary.")
        #expect(importedNode?.refinedText == "This is the important summary.")
    }
}
