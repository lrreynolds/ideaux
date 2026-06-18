//
//  IdeaCollectionDetailView.swift
//  ideaux
//
//  Created by LouR on 6/16/26.
//

import SwiftUI
import SwiftData

struct IdeaCollectionDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let collection: IdeaCollection

    @Query(sort: \IdeaNode.createdAt, order: .reverse) private var allIdeas: [IdeaNode]

    @State private var showingCapture = false
    @State private var captureText = ""
    @State private var expanded: Set<UUID> = []
    @State private var showContext: Bool = false

    var body: some View {
        let collectionIdeas = allIdeas.filter { $0.collectionID == collection.id }

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: collection.iconName)
                    Text(collection.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                if !collection.summary.isEmpty {
                    Text(collection.summary)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                DisclosureGroup(isExpanded: $showContext) {
                    GroupBox("Purpose") {
                        Text(collection.purpose.isEmpty ? "No purpose yet." : collection.purpose)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    GroupBox("Goals") {
                        Text(collection.goalsText.isEmpty ? "No goals yet." : collection.goalsText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    GroupBox("Key Concepts") {
                        Text(collection.keyConceptsText.isEmpty ? "No key concepts yet." : collection.keyConceptsText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    GroupBox("Background Context") {
                        Text(collection.backgroundContext.isEmpty ? "No background context yet." : collection.backgroundContext)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    GroupBox("Refinement Instructions") {
                        Text(collection.refinementInstructions.isEmpty ? "No refinement instructions yet." : collection.refinementInstructions)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } label: {
                    Text("Collection Context")
                        .font(.headline)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Ideas")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 2) {
                        let roots = collectionIdeas
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
                                outlineNode(root, all: collectionIdeas, depth: 0)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

            }
            .padding()
        }
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCapture = true
                    } label: {
                        Label("Capture Idea", systemImage: "plus")
                    }
                }
        }
        .sheet(isPresented: $showingCapture) {
            NavigationStack {
                Form {
                    Section("Idea") {
                        TextEditor(text: $captureText)
                            .frame(minHeight: 160)
                    }
                }
                .navigationTitle("Capture Idea")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingCapture = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let text = captureText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !text.isEmpty else { return }

                            let node = IdeaNode(rawCapture: text)
                            node.collectionID = collection.id
                            node.collection = collection
                            node.parentID = nil
                            node.parent = nil
                            node.status = "seed"

                            modelContext.insert(node)
                            try? modelContext.save()

                            captureText = ""
                            showingCapture = false
                        }
                        .disabled(captureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
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

#Preview("Idea Collection Detail") {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: IdeaCollection.self, IdeaProject.self, IdeaNode.self,
        configurations: configuration
    )

    let sample = IdeaCollection(
        name: "My Project",
        summary: "A quick summary of the collection.",
        iconName: "lightbulb",
        purpose: "Explore and refine ideas for the next release.",
        goalsText: "- Ship MVP\n- Get feedback",
        keyConceptsText: "SwiftUI, SwiftData, Architecture",
        backgroundContext: "Notes and prior art live here.",
        refinementInstructions: "Tighten scope and clarify user value."
    )

    container.mainContext.insert(sample)

    return NavigationStack {
        IdeaCollectionDetailView(collection: sample)
    }
    .modelContainer(container)
}
