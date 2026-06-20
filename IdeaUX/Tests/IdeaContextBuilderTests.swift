//
//  IdeaContextBuilderTests.swift
//  IdeaUX
//
//  Created by LouR on 6/18/26.
//

import Foundation
import Testing
@testable import IdeaUX

@Suite("IdeaContextBuilder")
struct IdeaContextBuilderTests {

    @Test("Root node snapshot includes siblings and children")
    func rootNodeSnapshot() {
        let collection = IdeaCollection(name: "ideauX")

        let root = IdeaNode(title: "Voice-First UX")
        root.collectionID = collection.id

        let sibling = IdeaNode(title: "Dynamic Outliner")
        sibling.collectionID = collection.id

        let child = IdeaNode(title: "Speech is primary")
        child.collectionID = collection.id
        child.parentID = root.id

        let snapshot = IdeaContextBuilder.snapshot(
            collection: collection,
            node: root,
            allNodes: [root, sibling, child]
        )

        #expect(snapshot.collectionName == "ideauX")
        #expect(snapshot.currentNodeTitle == "Voice-First UX")
        #expect(snapshot.parentPath.isEmpty)
        #expect(snapshot.siblingTitles == ["Dynamic Outliner"])
        #expect(snapshot.childTitles == ["Speech is primary"])
    }

    @Test("Child node snapshot includes parent path, siblings, and children")
    func childNodeSnapshot() {
        let collection = IdeaCollection(name: "ideauX")

        let root = IdeaNode(title: "Voice-First UX")
        root.collectionID = collection.id

        let child = IdeaNode(title: "Collection Creation")
        child.collectionID = collection.id
        child.parentID = root.id

        let sibling = IdeaNode(title: "Idea Capture")
        sibling.collectionID = collection.id
        sibling.parentID = root.id

        let grandchild = IdeaNode(title: "User dictates title and blurb")
        grandchild.collectionID = collection.id
        grandchild.parentID = child.id

        let snapshot = IdeaContextBuilder.snapshot(
            collection: collection,
            node: child,
            allNodes: [root, child, sibling, grandchild]
        )

        #expect(snapshot.parentPath == ["Voice-First UX"])
        #expect(snapshot.currentNodeTitle == "Collection Creation")
        #expect(snapshot.siblingTitles == ["Idea Capture"])
        #expect(snapshot.childTitles == ["User dictates title and blurb"])
    }

    @Test("Collection-level snapshot has no current node")
    func collectionLevelSnapshot() {
        let collection = IdeaCollection(
            name: "ideauX",
            summary: "Voice-first thinking companion",
            purpose: "Capture and refine ideas."
        )

        let snapshot = IdeaContextBuilder.snapshot(
            collection: collection,
            node: nil,
            allNodes: []
        )

        #expect(snapshot.collectionName == "ideauX")
        #expect(snapshot.collectionSummary == "Voice-first thinking companion")
        #expect(snapshot.purpose == "Capture and refine ideas.")
        #expect(snapshot.currentNodeTitle.isEmpty)
        #expect(snapshot.parentPath.isEmpty)
        #expect(snapshot.siblingTitles.isEmpty)
        #expect(snapshot.childTitles.isEmpty)
    }
    
    @Test("Deep node snapshot includes full parent path")
    func deepNodeSnapshot() {
        let collection = IdeaCollection(name: "ideauX")

        let root = IdeaNode(title: "Product Vision")
        root.collectionID = collection.id

        let child = IdeaNode(title: "Voice-First UX")
        child.collectionID = collection.id
        child.parentID = root.id

        let grandchild = IdeaNode(title: "Collection Creation")
        grandchild.collectionID = collection.id
        grandchild.parentID = child.id

        let sibling = IdeaNode(title: "Idea Capture")
        sibling.collectionID = collection.id
        sibling.parentID = child.id

        let leaf = IdeaNode(title: "User dictates title and short blurb")
        leaf.collectionID = collection.id
        leaf.parentID = grandchild.id

        let snapshot = IdeaContextBuilder.snapshot(
            collection: collection,
            node: leaf,
            allNodes: [root, child, grandchild, sibling, leaf]
        )

        #expect(snapshot.parentPath == [
            "Product Vision",
            "Voice-First UX",
            "Collection Creation"
        ])
        #expect(snapshot.currentNodeTitle == "User dictates title and short blurb")
        #expect(snapshot.siblingTitles.isEmpty)
        #expect(snapshot.childTitles.isEmpty)
    }
    
    @Test("Refinement prompt includes collection context and raw input")
    func refinementPromptIncludesContextAndInput() {
        let snapshot = IdeaContextSnapshot(
            collectionName: "ideauX",
            collectionSummary: "Voice-first thinking companion",
            purpose: "Capture and refine ideas while offline.",
            goals: "Make idea capture fast and contextual.",
            keyConcepts: "Voice capture, idea trees, export, refinement",
            backgroundContext: "The app is being dogfooded while it is built.",
            refinementInstructions: "Keep nodes small and actionable.",
            parentPath: ["Voice-First UX", "Idea Capture"],
            currentNodeTitle: "Capture by dictation",
            currentNodeContent: "Users should speak ideas instead of typing them.",
            siblingTitles: ["Question Answering", "Collection Creation"],
            childTitles: ["Mic button", "Edit after transcription"]
        )

        let prompt = IdeaPromptBuilder.refinementPrompt(
            for: snapshot,
            rawInput: "User should be able to add a quick thought while hiking."
        )

        #expect(prompt.contains("COLLECTION CONTEXT"))
        #expect(prompt.contains("Collection Name:"))
        #expect(prompt.contains("ideauX"))
        #expect(prompt.contains("Collection Purpose:"))
        #expect(prompt.contains("Capture and refine ideas while offline."))
        #expect(prompt.contains("Parent Path:"))
        #expect(prompt.contains("Voice-First UX > Idea Capture"))
        #expect(prompt.contains("CURRENT NODE"))
        #expect(prompt.contains("Current Title:"))
        #expect(prompt.contains("Capture by dictation"))
        #expect(prompt.contains("Current Content:"))
        #expect(prompt.contains("Users should speak ideas instead of typing them."))
        #expect(prompt.contains("SIBLINGS"))
        #expect(prompt.contains("Question Answering"))
        #expect(prompt.contains("Collection Creation"))
        #expect(prompt.contains("CHILDREN"))
        #expect(prompt.contains("Mic button"))
        #expect(prompt.contains("Edit after transcription"))
        #expect(prompt.contains("Raw Input:"))
        #expect(prompt.contains("User should be able to add a quick thought while hiking."))
    }

    @Test("Refinement prompt uses None for empty context lists")
    func refinementPromptUsesNoneForEmptyLists() {
        let snapshot = IdeaContextSnapshot(
            collectionName: "ideauX",
            collectionSummary: "",
            purpose: "",
            goals: "",
            keyConcepts: "",
            backgroundContext: "",
            refinementInstructions: "",
            parentPath: [],
            currentNodeTitle: "",
            currentNodeContent: "",
            siblingTitles: [],
            childTitles: []
        )

        let prompt = IdeaPromptBuilder.refinementPrompt(
            for: snapshot,
            rawInput: "A rough idea."
        )

        #expect(prompt.contains("Collection Purpose:\nNone"))
        #expect(prompt.contains("Parent Path:\nNone"))
        #expect(prompt.contains("SIBLINGS\n\nNone"))
        #expect(prompt.contains("CHILDREN\n\nNone"))
        #expect(prompt.contains("Raw Input:\nA rough idea."))
        #expect(prompt.contains("Help the user think about the CURRENT NODE only."))
        #expect(prompt.contains("A clearer title"))
        #expect(prompt.contains("A short summary"))
        #expect(prompt.contains("Helpful questions"))
        #expect(prompt.contains("Related ideas"))
        #expect(prompt.contains("Possible next steps"))
    }
}
