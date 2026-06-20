//
//  IdeaNodeDetailView.swift
//  ideaux
//
//  Created by LouR on 6/16/26.
//

import SwiftUI
import SwiftData

struct IdeaNodeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \IdeaNode.createdAt, order: .reverse) private var allIdeas: [IdeaNode]

    let node: IdeaNode
    let collection: IdeaCollection

    @State private var showingAddChild = false
    @State private var childCaptureText = ""
    @State private var selectedChildNode: IdeaNode?
    @State private var showingEditCore = false
    @State private var editTitleText = ""
    @State private var editSummaryText = ""
    @State private var showingRelatedDetails = false
    @State private var isAnalyzing = false
    @FocusState private var childEditorFocused: Bool
 
   
    
    @State private var debugDocument: DebugDocument?
    
#if DEBUG
private let showDebugControls = true
#else
private let showDebugControls = false
#endif

    var body: some View {
        ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(node.title.isEmpty ? String(node.rawCapture.prefix(80)) : node.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding()

                    HStack(spacing: 10) {
                        Text(statusLabel)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.green.opacity(0.15))
                            .clipShape(Capsule())

                        Text(node.createdAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                }

                    if let lastAnalyzedAt = node.lastAnalyzedAt {
                        Text("Analyzed \(lastAnalyzedAt, style: .relative) ago")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if isAnalyzing {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Analyzing updated idea…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }


            IdeaDetailSection(title: "Summary") {
                Text(node.refinedText.isEmpty ? "No summary yet." : node.refinedText)
            }

            HStack(spacing: 16) {
                if node.status != "refined" {
                    Button {
                        acceptCoreIdea()
                        showingRelatedDetails = true
                    } label: {
                        Label("Looks Good", systemImage: "hand.thumbsup")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(node.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || node.refinedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Button {
                    editTitleText = node.title
                    editSummaryText = node.refinedText
                    showingEditCore = true
                } label: {
                    Label("Edit", systemImage: "hand.thumbsdown")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            if showingRelatedDetails || node.status == "refined" {
                IdeaDetailSection(title: "Questions") {
                    IdeaTextList(text: node.modelQuestionsText, emptyText: "No questions yet.")
                }

                IdeaDetailSection(title: "Related Ideas") {
                    IdeaTextList(text: node.modelRelatedIdeasText, emptyText: "No related ideas yet.")
                }

                IdeaDetailSection(title: "Possible Next Steps") {
                    IdeaTextList(text: node.modelNextStepsText, emptyText: "No next steps yet.")
                }
            }
                

            VStack(spacing: 12) {

                if showDebugControls {
                    Button {
                        showContextDebug()
                    } label: {
                        Label("Prompt Debug", systemImage: "doc.text")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Button(role: .destructive) {
                    modelContext.delete(node)
                    try? modelContext.save()
                    dismiss()
                } label: {
                    Label("Delete Idea", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                }
            
            
            .padding()
        }
        .navigationTitle("Idea")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedChildNode) { child in
            IdeaNodeDetailView(node: child, collection: collection)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddChild = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Child Idea")
            }
        }
        .sheet(item: $debugDocument) { doc in
            NavigationStack {
                ScrollView {
                    Text(doc.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .navigationTitle(doc.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                           debugDocument = nil
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditCore) {
            NavigationStack {
                Form {
                    Section("Title") {
                        TextField("Title", text: $editTitleText)
                    }

                    Section("Summary") {
                        TextEditor(text: $editSummaryText)
                            .frame(minHeight: 140)
                    }
                }
                .navigationTitle("Edit Idea")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingEditCore = false
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveCoreEdits()
                            showingEditCore = false

                            Task {
                                isAnalyzing = true
                                await analyze(node, updateCoreFields: false)
                                await MainActor.run {
                                    isAnalyzing = false
                                    showingRelatedDetails = true
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddChild) {
            IdeaCaptureSheet(
                title: "Add Child Idea",
                sectionTitle: "Idea",
                onCancel: {
                    showingAddChild = false
                },
                onSave: { text in
                    createChildIdea(from: text)
                }
            )
        }
    }

    private var statusLabel: String {
        switch node.status.lowercased() {
        case "seed": "🌱 Seed"
        case "exploring": "🔎 Exploring"
        case "refining", "growing": "🌿 Refining"
        case "actionable": "● Actionable"
        case "implemented": "✓ Implemented"
        case "validated": "★ Validated"
        case "rejected": "✕ Rejected"
        case "archived": "📦 Archived"
        default: node.status.capitalized
        }
    }
    
    private func showContextDebug() {
        let snapshot = makeCurrentSnapshot()

        let prompt = IdeaPromptBuilder.refinementPrompt(
            for: snapshot,
            rawInput: node.rawCapture
        )

       debugDocument = DebugDocument(
            title: "Prompt Debug",
            text: prompt
       )
    }
    
    private func createChildIdea(from text: String) {
        let child = IdeaNode(rawCapture: text)
        child.title = String(text.prefix(60))
        child.refinedText = text
        child.status = "seed"
        child.nodeType = "idea"
        child.collectionID = collection.id
        child.collection = collection
        child.parentID = node.id
        child.parent = node

        modelContext.insert(child)
        try? modelContext.save()

        showingAddChild = false

        Task {
            await analyze(child)

            await MainActor.run {
                selectedChildNode = child
            }
        }
    }

    private func setStatus(_ status: String) {
        node.status = status
        node.updatedAt = Date()
        if status == "implemented" {
            node.implementedAt = Date()
        }
        try? modelContext.save()
    }

    private func acceptCoreIdea() {
        node.status = "refined"
        node.updatedAt = Date()
        showingRelatedDetails = true
        try? modelContext.save()
    }

    private func saveCoreEdits() {
        let title = editTitleText.trimmingCharacters(in: .whitespacesAndNewlines)
        let summary = editSummaryText.trimmingCharacters(in: .whitespacesAndNewlines)

        node.title = title.isEmpty ? String(node.rawCapture.prefix(80)) : title
        node.refinedText = summary
        node.status = "refined"
        node.updatedAt = Date()
        showingRelatedDetails = true
        try? modelContext.save()
    }

    private func saveCoreEditsAndReanalyze() async {
        let title = editTitleText.trimmingCharacters(in: .whitespacesAndNewlines)
        let summary = editSummaryText.trimmingCharacters(in: .whitespacesAndNewlines)

        await MainActor.run {
            node.title = title.isEmpty ? String(node.rawCapture.prefix(80)) : title
            node.refinedText = summary
            node.status = "refined"
            node.updatedAt = Date()
            showingRelatedDetails = true
            try? modelContext.save()
        }

        await analyze(node, updateCoreFields: false)
    }

    private func makeCurrentSnapshot() -> IdeaContextSnapshot {
        let collectionIdeas = allIdeas.filter { $0.collectionID == collection.id }

        return IdeaContextBuilder.snapshot(
            collection: collection,
            node: node,
            allNodes: collectionIdeas
        )
    }

 


    private func analyze(_ targetNode: IdeaNode, updateCoreFields: Bool = true) async {
        await MainActor.run {
            debugDocument = DebugDocument(
                title: "Analyzing Idea",
                text: "Running typed Foundation Model analysis…"
            )
        }

        do {
            let collectionIdeas = allIdeas.filter { $0.collectionID == collection.id }

            let snapshot = IdeaContextBuilder.snapshot(
                collection: collection,
                node: targetNode,
                allNodes: collectionIdeas
            )

            let prompt = IdeaPromptBuilder.refinementPrompt(
                for: snapshot,
                rawInput: targetNode.rawCapture
            )

            let suggestion = try await FoundationModelIdeaRefiner()
                .refineSuggestion(prompt: prompt)

            let output = """
            Original:
            \(targetNode.rawCapture)

            Title:
            \(suggestion.title)

            Interpretation:
            \(suggestion.interpretation)

            Summary:
            \(suggestion.summary)

            Questions:
            \(suggestion.questions.map { "- \($0)" }.joined(separator: "\n"))

            Related Ideas:
            \(suggestion.relatedIdeas.map { "- \($0)" }.joined(separator: "\n"))

            Possible Next Steps:
            \(suggestion.possibleNextSteps.map { "- \($0)" }.joined(separator: "\n"))
            """

            await MainActor.run {
                if updateCoreFields {
                    targetNode.title = suggestion.title
                    targetNode.refinedText = suggestion.summary
                }

                targetNode.modelInterpretation = suggestion.interpretation
                targetNode.modelQuestionsText = suggestion.questions.joined(separator: "\n")
                targetNode.modelRelatedIdeasText = suggestion.relatedIdeas.joined(separator: "\n")
                targetNode.modelNextStepsText = suggestion.possibleNextSteps.joined(separator: "\n")
                targetNode.lastAnalyzedAt = Date()
                targetNode.updatedAt = Date()

                try? modelContext.save()

                debugDocument = DebugDocument(
                    title: "Typed Model Output",
                    text: output
                )
            }
        } catch {
            await MainActor.run {
                debugDocument = DebugDocument(
                    title: "Model Error",
                    text: error.localizedDescription
                )
            }
        }
    }

    private func testFoundationModel() async {
        await analyze(node)
    }

   
  
}

#Preview("Idea Detail") {
    PreviewIdeaNodeDetail()
}

struct PreviewIdeaNodeDetail: View {
    let container: ModelContainer
    let mockCollection: IdeaCollection
    let mockNode: IdeaNode

    init() {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: IdeaCollection.self, IdeaProject.self, IdeaNode.self,
            configurations: configuration
        )

        mockCollection = IdeaCollection(
            name: "Demo Collection",
            summary: "Explore and refine product ideas",
            iconName: "folder",
            colorName: "blue",
            purpose: "Explore and refine product ideas",
            goalsText: "Ship MVP, validate with users",
            keyConceptsText: "Focus, scope, feedback",
            backgroundContext: "We’re exploring opportunities in productivity tools.",
            refinementInstructions: "Clarify user value; propose small next steps"
        )

        mockNode = IdeaNode(
            rawCapture: "A lightweight note-taking app that automatically organizes ideas by topics using on-device intelligence.",
            title: "",
            refinedText: "",
            summary: "",
            status: "seed",
            nextQuestionsText: ""
        )

        mockNode.collectionID = mockCollection.id
        mockNode.collection = mockCollection
        container.mainContext.insert(mockCollection)
        container.mainContext.insert(mockNode)
    }

    var body: some View {
        NavigationStack {
            IdeaNodeDetailView(node: mockNode, collection: mockCollection)
        }
        .modelContainer(container)
    }
}

struct DebugDocument: Identifiable {
    let id = UUID()
    let title: String
    let text: String
}

struct IdeaDetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            content
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct IdeaTextList: View {
    let text: String
    let emptyText: String

    var items: [String] {
        text
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        if items.isEmpty {
            Text(emptyText)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(item)
                    }
                }
            }
        }
    }
}
