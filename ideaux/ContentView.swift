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
                                    if !collection.summary.isEmpty {
                                        Text(collection.summary)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                    .onDelete(perform: deleteCollections)
                }
            }
            .navigationTitle("ideauX")
            .toolbar {
                Button {
                    addSampleCollection()
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
            .onAppear {
                seedCollectionsIfNeeded()
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

    private func addSampleCollection() {
        let collection = IdeaCollection(
            name: "New Collection \(collections.count + 1)",
            summary: "A new idea context.",
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
            ("Commonshub", "Creator-owned communities on the open social web.", "folder", "indigo"),
            ("ideauX", "Offline-first idea capture and idea trees.", "leaf", "green"),
            ("AI", "Local models, refinement, and structured thinking.", "sparkles", "purple"),
            ("Discovery", "Finding and connecting useful signals.", "magnifyingglass", "orange"),
            ("Universities", "Institutional communities, mentorship, and alumni networks.", "graduationcap", "teal")
        ]

        for sample in samples {
            let collection = IdeaCollection(
                name: sample.0,
                summary: sample.1,
                iconName: sample.2,
                colorName: sample.3
            )
            modelContext.insert(collection)
        }
    }
}




