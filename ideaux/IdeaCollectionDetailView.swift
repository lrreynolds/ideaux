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

    var body: some View {
        
        let collectionIdeas = allIdeas.filter { $0.collection?.id == collection.id }
        
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
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ideas")
                        .font(.headline)

                    if collectionIdeas.isEmpty {
                        Text("No ideas captured yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(collectionIdeas, id: \.persistentModelID) { idea in
                            NavigationLink {
                                IdeaNodeDetailView(node: idea, collection: collection)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(idea.title.isEmpty ? String(idea.rawCapture.prefix(60)) : idea.title)
                                        .font(.headline)

                                    Text(idea.rawCapture)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(3)

                                    Text(idea.status.capitalized)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color(.secondarySystemBackground))
                                )
                            }
                         
                        }
                    }
                }
                Button {
                    showingCapture = true
                } label: {
                    Label("Capture Idea", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.inline)
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
                            node.collection = collection
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
}

#Preview("Idea Collection Detail") {
    // Provide a sample IdeaCollection for preview
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
    NavigationStack {
            IdeaCollectionDetailView(collection: sample)
        }

}
