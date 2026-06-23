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
    @Query(sort: \IdeaCollection.name) private var collections: [IdeaCollection]
    @State private var showingNewCollection = false
    @State private var showingImportTree = false

    var body: some View {
        NavigationStack {
            List {
                Section("Collections") {
                    ForEach(collections) { collection in
                        NavigationLink {
                            IdeaCollectionDetailView(collection: collection)
                        } label: {
                            HStack {
                                Image(systemName: collection.iconName)
                                VStack(alignment: .leading) {
                                    Text(collection.name)
                                        .font(.headline)
                                    let displayHeadline = collection.headline.trimmingCharacters(in: .whitespacesAndNewlines)
                                    let displaySummary = collection.summary.trimmingCharacters(in: .whitespacesAndNewlines)

                                    if !displayHeadline.isEmpty {
                                        Text(displayHeadline)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    } else if !displaySummary.isEmpty {
                                        Text(displaySummary)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                    .onDelete(perform: deleteCollections)
                }
            }
            .navigationTitle("IdeaUX")
            .toolbar {
                Menu {
                    Button {
                        showingNewCollection = true
                    } label: {
                        Label("New Collection", systemImage: "plus")
                    }
                    Button {
                        showingImportTree = true
                    } label: {
                        Label("Import Tree", systemImage: "tray.and.arrow.down")
                    }
                } label: {
                    Label("Actions", systemImage: "ellipsis.circle")
                }
            }
            .onAppear {
                seedCollectionsIfNeeded()
            }
            .sheet(isPresented: $showingImportTree) {
                ImportTreeSheet()
            }
            .sheet(isPresented: $showingNewCollection) {
                CollectionCreationSheet(
                    onCancel: {
                        showingNewCollection = false
                    },
                    onCreate: { name, headline, summary, purpose in
                        createCollection(
                            name: name,
                            headline: headline,
                            summary: summary,
                            purpose: purpose
                        )
                        showingNewCollection = false
                    }
                )
            }
        }
    }
    
    private func deleteCollections(at offsets: IndexSet) {
        for index in offsets {
            let collection = collections[index]
            modelContext.delete(collection)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete collection: \(error)")
        }
    }

    private func createCollection(
        name: String,
        headline: String,
        summary: String,
        purpose: String
    ) {
        let collection = IdeaCollection(
            name: name,
            headline: headline,
            summary: summary,
            iconName: "folder",
            colorName: "blue"
        )

        modelContext.insert(collection)

        do {
            try modelContext.save()
        } catch {
            print("Failed to save collection: \(error)")
        }
    }

    private func seedCollectionsIfNeeded() {
        guard collections.isEmpty else { return }

        let samples = [
            ("Commonshub", "Creator-owned communities", "Creator-owned communities on the open social web.", "folder", "indigo"),
            ("ideauX", "Offline idea trees", "Offline-first idea capture and idea trees.", "leaf", "green"),
            ("AI", "Local model thinking", "Local models, refinement, and structured thinking.", "sparkles", "purple"),
            ("Discovery", "Find useful signals", "Finding and connecting useful signals.", "magnifyingglass", "orange"),
            ("Universities", "Institutional networks", "Institutional communities, mentorship, and alumni networks.", "graduationcap", "teal")
        ]

        for sample in samples {
            let collection = IdeaCollection(
                name: sample.0,
                headline: sample.1,
                summary: sample.2,
                iconName: sample.3,
                colorName: sample.4
            )
            modelContext.insert(collection)
        }
    }
}
