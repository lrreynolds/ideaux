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

    @Bindable var collection: IdeaCollection

    @Query(sort: \IdeaNode.createdAt, order: .reverse) private var allIdeas: [IdeaNode]

    @State private var showingCapture = false
    @State private var expanded: Set<UUID> = []
    @State private var showingContext = false
    @State private var selectedRootNode: IdeaNode?

    var body: some View {
        let collectionIdeas = allIdeas.filter { $0.collectionID == collection.id }

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .firstTextBaseline) {

                    Text(collection.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    Button {
                        showingContext = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }

                if !collection.summary.isEmpty {
                    Text(collection.summary)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                

                VStack(alignment: .leading, spacing: 10) {
                 

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
        .navigationDestination(item: $selectedRootNode) { node in
            IdeaNodeDetailView(node: node, collection: collection)
        }
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
            IdeaCaptureSheet(
                title: "Capture Idea",
                sectionTitle: "Idea",
                onCancel: {
                    showingCapture = false
                },
                onSave: { text in
                    createRootIdea(from: text)
                }
            )
        }
        .sheet(isPresented: $showingContext) {
            NavigationStack {
                Form {
                    Section("Collection") {
                        TextField("Name", text: $collection.name)
                        TextField("Summary", text: $collection.summary, axis: .vertical)
                            .lineLimit(2...4)
                    }

                    Section("Context") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Purpose")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $collection.purpose)
                                .frame(minHeight: 80)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Goals")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $collection.goalsText)
                                .frame(minHeight: 100)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Key Concepts")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $collection.keyConceptsText)
                                .frame(minHeight: 100)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Background Context")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $collection.backgroundContext)
                                .frame(minHeight: 120)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Refinement Instructions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $collection.refinementInstructions)
                                .frame(minHeight: 120)
                        }
                    }
                    Section("Export") {
                        ShareLink(item: IdeaTreeExporter.exportMarkdown(for: collection, ideas: collectionIdeas)) {
                            Label("Export Collection as Markdown", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                .navigationTitle("Collection Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            try? modelContext.save()
                            showingContext = false
                        }
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

    private func createRootIdea(from text: String) {
        let node = IdeaNode(rawCapture: text)
        node.title = String(text.prefix(60))
        node.refinedText = text
        node.collectionID = collection.id
        node.collection = collection
        node.parentID = nil
        node.parent = nil
        node.status = "refining"
        node.nodeType = "idea"

        modelContext.insert(node)
        try? modelContext.save()

        showingCapture = false
        selectedRootNode = node
        
        Task {
            await analyzeRootIdea(node)
        }
    }
    
    private func analyzeRootIdea(_ node: IdeaNode) async {
        do {
            let collectionIdeas = allIdeas.filter { $0.collectionID == collection.id }

            let snapshot = IdeaContextBuilder.snapshot(
                collection: collection,
                node: node,
                allNodes: collectionIdeas
            )

            let prompt = IdeaPromptBuilder.refinementPrompt(
                for: snapshot,
                rawInput: node.rawCapture
            )

            let suggestion = try await FoundationModelIdeaRefiner()
                .refineSuggestion(prompt: prompt)

            await MainActor.run {
                node.title = suggestion.title
                node.refinedText = suggestion.summary
                node.modelInterpretation = suggestion.interpretation
                node.modelQuestionsText = suggestion.questions.joined(separator: "\n")
                node.modelRelatedIdeasText = suggestion.relatedIdeas.joined(separator: "\n")
                node.modelNextStepsText = suggestion.possibleNextSteps.joined(separator: "\n")
                node.status = "seed"
                node.lastAnalyzedAt = Date()
                node.updatedAt = Date()

                try? modelContext.save()
            }
        } catch {
#if DEBUG
            print("Root idea analysis failed: \(error.localizedDescription)")
#endif
        }
    }


}

private struct ContextSection: View {
    let title: String
    let text: String

    var body: some View {
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline)
                Text(text).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
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
