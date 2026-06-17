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

    let node: IdeaNode
    let collection: IdeaCollection

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(node.title.isEmpty ? String(node.rawCapture.prefix(80)) : node.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                HStack {
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

                GroupBox("Collection") {
                    Text(collection.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Original Idea") {
                    Text(node.rawCapture)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Refined Idea") {
                    Text(node.refinedText.isEmpty ? "Not refined yet." : node.refinedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Why It Matters") {
                    Text(node.summary.isEmpty ? "No summary yet." : node.summary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                GroupBox("Next Questions") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(
                            node.nextQuestionsText
                                .split(separator: "\n")
                                .map(String.init),
                            id: \.self
                        ) { question in

                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "questionmark.circle")
                                    .foregroundStyle(.secondary)

                                Text(question)
                            }
                        }
                    }
                }

                Button {
                    refineIdea()
                } label: {
                    Label("Refine Idea", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
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
    }

    private var statusLabel: String {
        switch node.status {
        case "seed": "🌱 Seed"
        case "growing": "🌿 Growing"
        case "archived": "🗄 Archived"
        default: node.status.capitalized
        }
    }

    private func refineIdea() {
        let raw = node.rawCapture.trimmingCharacters(in: .whitespacesAndNewlines)

        node.status = "growing"
        node.updatedAt = Date()
        node.title = String(raw.prefix(60))
        node.refinedText = raw

        let contextParts = [
            collection.purpose,
            collection.goalsText,
            collection.keyConceptsText,
            collection.backgroundContext,
            collection.refinementInstructions
        ].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        if contextParts.isEmpty {
            node.summary = "This idea may be useful within \(collection.name) because it relates to the collection context."
        } else {
            node.summary = "This idea may be useful within \(collection.name) because it connects to: \(contextParts.joined(separator: " "))"
        }

        node.nextQuestionsText = """
        What problem does this solve within \(collection.name)?
        Which existing idea or project does this connect to?
        What is the smallest next experiment?
        What would make this idea 10x better?
        """

        try? modelContext.save()
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

