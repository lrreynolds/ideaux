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
    @State private var showingContext = false
    @State private var selectedRootNode: IdeaNode?
    @State private var isReviewingCollection = false
    @State private var isSynthesizingCollection = false

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

                let displayHeadline = collection.headline.trimmingCharacters(in: .whitespacesAndNewlines)
                let displaySummary = collection.summary.trimmingCharacters(in: .whitespacesAndNewlines)

                if !displayHeadline.isEmpty {
                    Text(displayHeadline)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else if !displaySummary.isEmpty {
                    Text(displaySummary)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                IdeaOutlineView(
                    collection: collection,
                    ideas: collectionIdeas,
                    onNodeApproved: {
                        Task {
                            await synthesizeCollection()
                        }
                    }
                )

            }
            .padding()
        }
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedRootNode) { node in
            IdeaNodeDetailView(node: node, collection: collection)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    Task {
                        await reviewCollection()
                    }
                } label: {
                    if isReviewingCollection {
                        ProgressView()
                    } else {
                        Image(systemName: "sparkles")
                    }
                }
                .disabled(isReviewingCollection)

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
                        TextField("Headline", text: $collection.headline, axis: .vertical)
                            .lineLimit(1...2)
                        TextField("Short Summary", text: $collection.summary, axis: .vertical)
                            .lineLimit(2...4)
                    }

                    Section("Context") {
                        Button {
                            Task {
                                await synthesizeCollection()
                            }
                        } label: {
                            if isSynthesizingCollection {
                                Label("Updating Collection Context…", systemImage: "sparkles")
                            } else {
                                Label("Update Collection Context", systemImage: "sparkles")
                            }
                        }
                        .disabled(isSynthesizingCollection)

                        Button(role: .destructive) {
                            resetNodesToSeed()
                        } label: {
                            Label("Reset Node Review Statuses", systemImage: "arrow.counterclockwise")
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Purpose")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $collection.purpose)
                                .frame(minHeight: 80)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Evolving Description")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $collection.synthesizedDescription)
                                .frame(minHeight: 120)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Emerging Key Concepts")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $collection.synthesizedKeyConceptsText)
                                .frame(minHeight: 120)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Synthesized Background Context")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $collection.synthesizedBackgroundContext)
                                .frame(minHeight: 140)
                        }

                        if let synthesizedAt = collection.synthesizedAt {
                            Text("Last updated \(synthesizedAt, style: .relative) ago")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
                applyRecommendedStatus(from: suggestion, to: node)
                node.refinedText = suggestion.summary
                node.modelInterpretation = suggestion.interpretation
                node.modelQuestionsText = suggestion.questions.joined(separator: "\n")
                node.modelRelatedIdeasText = suggestion.relatedIdeas.joined(separator: "\n")
                node.modelNextStepsText = suggestion.possibleNextSteps.joined(separator: "\n")
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

    private func synthesizeCollection() async {
        guard !isSynthesizingCollection else { return }

        await MainActor.run {
            isSynthesizingCollection = true
        }

        defer {
            Task { @MainActor in
                isSynthesizingCollection = false
            }
        }

        do {
            let collectionIdeas = allIdeas.filter { $0.collectionID == collection.id }
            let snapshot = CollectionReviewSnapshotBuilder.snapshot(
                collection: collection,
                allNodes: collectionIdeas
            )

            let suggestion = try await CollectionSynthesizer().synthesize(snapshot: snapshot)

            await MainActor.run {
                collection.synthesizedDescription = suggestion.description
                collection.synthesizedKeyConceptsText = suggestion.keyConceptsText
                collection.synthesizedBackgroundContext = suggestion.backgroundContext
                collection.synthesizedAt = Date()
                collection.updatedAt = Date()
                try? modelContext.save()
            }
        } catch {
#if DEBUG
            print("Collection synthesis failed: \(error)")
#endif
        }
    }

    private func resetNodesToSeed() {
        let collectionIdeas = allIdeas.filter { $0.collectionID == collection.id }

        for node in collectionIdeas {
            let status = node.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard status != "implemented" && status != "done" else { continue }

            node.status = "seed"
            node.nodeType = "idea"
            node.updatedAt = Date()
        }

        try? modelContext.save()
    }

    private func reviewCollection() async {
        guard !isReviewingCollection else { return }

        await MainActor.run {
            isReviewingCollection = true
        }

        defer {
            Task { @MainActor in
                isReviewingCollection = false
            }
        }

        do {
            let collectionIdeas = allIdeas.filter { $0.collectionID == collection.id }

            let snapshot = CollectionReviewSnapshotBuilder.snapshot(
                collection: collection,
                allNodes: collectionIdeas
            )

            let result = try await CollectionReviewer().review(
                snapshot: snapshot
            )

#if DEBUG
            print("\n====================")
            print("COLLECTION REVIEW")
            print("====================")
            print("Updates Returned: \(result.nodeUpdates.count)")

            for update in result.nodeUpdates {
                print("Node: \(update.nodeID)")
                print("Status: \(update.recommendedStatus)")
                print("Reason: \(update.reason)")
                print("---")
            }

            print("====================\n")
#endif

            await MainActor.run {
                for update in result.nodeUpdates {
                    guard let nodeID = UUID(uuidString: update.nodeID) else {
                        continue
                    }

                    guard let node = collectionIdeas.first(where: { $0.id == nodeID }) else {
                        continue
                    }

                    guard node.status.lowercased() != "implemented" else {
                        continue
                    }

                    switch update.recommendedStatus.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
                    case "question":
                        node.status = "question"
                    case "actionable":
                        node.status = "actionable"
                    case "none":
                        node.status = "refined"
                    default:
                        break
                    }

                    node.updatedAt = Date()
                }

                try? modelContext.save()
            }
        } catch {
#if DEBUG
            print("Collection review failed: \(error)")
#endif
        }
    }

    private func applyRecommendedStatus(from suggestion: IdeaRefinementSuggestion, to node: IdeaNode) {
        guard node.status != "implemented" else { return }

        switch suggestion.recommendedStatus.lowercased() {
        case "question":
            node.status = "question"
        case "actionable":
            node.status = "actionable"
        default:
            if node.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "refining" {
                node.status = "seed"
            }
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
        headline: "A quick summary of the collection.",
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
