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
 
   
    
    @State private var debugDocument: DebugDocument?

    var body: some View {
        ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(node.title.isEmpty ? String(node.rawCapture.prefix(80)) : node.title)
                        .font(.headline)
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
                }

                    IdeaDetailSection(title: "Original") {
                    Text(node.rawCapture)
                }

            IdeaDetailSection(title: "Interpretation") {
                Text(node.modelInterpretation.isEmpty ? "Not analyzed yet." : node.modelInterpretation)
                }

            IdeaDetailSection(title: "Summary") {
                Text(node.refinedText.isEmpty ? "No summary yet." : node.refinedText)
                }

            IdeaDetailSection(title: "Questions") {
                IdeaTextList(text: node.modelQuestionsText, emptyText: "No questions yet.")
                }

            IdeaDetailSection(title: "Related Ideas") {
                IdeaTextList(text: node.modelRelatedIdeasText, emptyText: "No related ideas yet.")
                }
               

            IdeaDetailSection(title: "Possible Next Steps") {
                IdeaTextList(text: node.modelNextStepsText, emptyText: "No next steps yet.")
                }
                

            VStack(spacing: 12) {
                Button {
                    Task {
                        await testFoundationModel()
                    }
                } label: {
                    Label("Analyze Idea", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                    }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    showingAddChild = true
                } label: {
                    Label("Add Child Idea", systemImage: "plus.rectangle.on.folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    showContextDebug()
                } label: {
                    Label("Prompt Debug", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

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
     
        .sheet(isPresented: $showingAddChild) {
            NavigationStack {
                Form {
                    Section("Child Node") {
                        TextEditor(text: $childCaptureText)
                            .frame(minHeight: 160)
                    }
                }
                .navigationTitle("Add Child Node")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            childCaptureText = ""
                            showingAddChild = false
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let text = childCaptureText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !text.isEmpty else { return }

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

                            childCaptureText = ""
                            showingAddChild = false
                        }
                        .disabled(childCaptureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
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

    private func setStatus(_ status: String) {
        node.status = status
        node.updatedAt = Date()
        if status == "implemented" {
            node.implementedAt = Date()
        }
        try? modelContext.save()
    }

    private func makeCurrentSnapshot() -> IdeaContextSnapshot {
        let collectionIdeas = allIdeas.filter { $0.collectionID == collection.id }

        return IdeaContextBuilder.snapshot(
            collection: collection,
            node: node,
            allNodes: collectionIdeas
        )
    }

 

    private func testFoundationModel() async {
        debugDocument = DebugDocument(
            title: "Analyzing Idea",
            text: "Running typed Foundation Model analysis…"
        )

        do {
            let snapshot = makeCurrentSnapshot()

            let prompt = IdeaPromptBuilder.refinementPrompt(
                for: snapshot,
                rawInput: node.rawCapture
            )

            let suggestion = try await FoundationModelIdeaRefiner()
                .refineSuggestion(prompt: prompt)

            let output = """
            Original:
            \(node.rawCapture)

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
                node.title = suggestion.title
                node.modelInterpretation = suggestion.interpretation
                node.refinedText = suggestion.summary
                node.modelQuestionsText = suggestion.questions.joined(separator: "\n")
                node.modelRelatedIdeasText = suggestion.relatedIdeas.joined(separator: "\n")
                node.modelNextStepsText = suggestion.possibleNextSteps.joined(separator: "\n")
                node.lastAnalyzedAt = Date()
                node.updatedAt = Date()

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

