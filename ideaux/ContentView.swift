//
//  ContentView.swift
//  ideaux
//
//  Created by LouR on 6/16/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \IdeaNode.createdAt, order: .reverse) private var allNodes: [IdeaNode]
    @State private var newIdeaText: String = ""
    @State private var selectedNode: IdeaNode?
    
    var inbox: [IdeaNode] { allNodes.filter { $0.status == "inbox" } }
    var refined: [IdeaNode] { allNodes.filter { $0.status == "refined" } }
    var archived: [IdeaNode] { allNodes.filter { $0.status == "archived" } }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("ideauX").font(.largeTitle).bold()
                Text("Capture ideas. Grow idea trees.").font(.subheadline).foregroundStyle(.secondary)
                TextEditor(text: $newIdeaText).frame(minHeight: 80).overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray.opacity(0.2)))
                Button("Save Idea") {
                    let now = Date()
                    let node = IdeaNode(createdAt: now, updatedAt: now, rawCapture: newIdeaText)
                    node.status = "inbox"
                    modelContext.insert(node)
                    newIdeaText = ""
                }
                .disabled(newIdeaText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Divider()
                SectionList(title: "Inbox", nodes: inbox, onSelect: { selectedNode = $0 }, onRefine: refine, onArchive: archive)
                SectionList(title: "Refined", nodes: refined, onSelect: { selectedNode = $0 }, onArchive: archive)
                SectionList(title: "Archived", nodes: archived, onSelect: { selectedNode = $0 })
            }
            .padding()
            .sheet(item: $selectedNode) { node in
                IdeaNodeDetailView(node: node)
            }
        }
    }
    // Action for refining an idea
    func refine(_ node: IdeaNode) {
        node.status = "refined"
        node.updatedAt = Date()
        // Generate placeholder title and summary
        let firstLine = node.rawCapture.split(separator: "\n").first.map(String.init) ?? node.rawCapture
        node.title = String(firstLine.prefix(40))
        node.refinedText = node.rawCapture
        node.summary = "This is a summary."
    }
    // Action for archiving an idea
    func archive(_ node: IdeaNode) {
        node.status = "archived"
        node.updatedAt = Date()
    }
}

struct SectionList: View {
    let title: String
    let nodes: [IdeaNode]
    var onSelect: (IdeaNode) -> Void = { _ in }
    var onRefine: ((IdeaNode) -> Void)? = nil
    var onArchive: ((IdeaNode) -> Void)? = nil
    var body: some View {
        if !nodes.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                ForEach(nodes, id: \.persistentModelID) { node in
                    HStack {
                        Button(action: { onSelect(node) }) {
                            Text(node.title.isEmpty ? String(node.rawCapture.prefix(40)) : String(node.title.prefix(40)))
                                .lineLimit(1)
                        }
                        Spacer()
                        if let onRefine, node.status == "inbox" {
                            Button("Refine") { onRefine(node) }.buttonStyle(.borderless)
                        }
                        if let onArchive, node.status != "archived" {
                            Button("Archive") { onArchive(node) }.buttonStyle(.borderless)
                        }
                    }
                    .contentShape(Rectangle())
                }
            }
        }
    }
}

struct IdeaNodeDetailView: View, Identifiable {
    let node: IdeaNode
    var id: ObjectIdentifier { ObjectIdentifier(node) }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(node.title.isEmpty ? "(No Title)" : node.title).font(.title2)
            Text("Status: \(node.status)").font(.subheadline)
            Divider()
            Text("Raw Capture").font(.headline)
            Text(node.rawCapture)
            if !node.refinedText.isEmpty {
                Text("Refined").font(.headline)
                Text(node.refinedText)
            }
            if !node.summary.isEmpty {
                Text("Summary").font(.headline)
                Text(node.summary)
            }
            if !node.tagsText.isEmpty {
                Text("Tags").font(.headline)
                Text(node.tagsText)
            }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

