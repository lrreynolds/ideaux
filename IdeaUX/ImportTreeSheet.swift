import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportTreeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \IdeaCollection.name) private var allCollections: [IdeaCollection]
    @Query(sort: \IdeaNode.createdAt, order: .forward) private var allNodes: [IdeaNode]

    @State private var markdown: String = ""
    @State private var pendingMarkdown: String = ""
    @State private var showingImportConflict = false
    @State private var showingFileImporter = false
    @State private var importErrorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Markdown Outline") {
                    TextEditor(text: $markdown)
                        .frame(minHeight: 240)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .navigationTitle("Import Tree")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .status) {
                    Button {
                        showingFileImporter = true
                    } label: {
                        Label("Import File", systemImage: "doc.badge.plus")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        let trimmed = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }

                        let title = collectionTitle(from: trimmed)
                        let existingCollection = matchingExistingCollection(for: title)

                        if let existingCollection {
                            pendingMarkdown = markdownReplacingCollectionTitle(trimmed, with: existingCollection.name)
                            showingImportConflict = true
                        } else {
                            _ = IdeaTreeImporter.importMarkdownAsCollection(trimmed, context: modelContext, mode: .createNewCopy)
                            dismiss()
                        }
                    }
                    .disabled(markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .confirmationDialog(
                "A collection with this name already exists.",
                isPresented: $showingImportConflict,
                titleVisibility: .visible
            ) {
                Button("Create New Copy") {
                    _ = IdeaTreeImporter.importMarkdownAsCollection(pendingMarkdown, context: modelContext, mode: .createNewCopy)
                    pendingMarkdown = ""
                    dismiss()
                }

                Button("Replace Existing", role: .destructive) {
                    let title = collectionTitle(from: pendingMarkdown)

                    if let existingCollection = matchingExistingCollection(for: title) {
                        do {
                            _ = try IdeaSnapshotManager.createSnapshot(
                                for: existingCollection,
                                allNodes: allNodes,
                                reason: "Before import replace",
                                context: modelContext
                            )
                        } catch {
                            importErrorMessage = "Could not create restore point before replacing: \(error.localizedDescription)"
                            return
                        }
                    }

                    _ = IdeaTreeImporter.importMarkdownAsCollection(pendingMarkdown, context: modelContext, mode: .replaceExisting)
                    pendingMarkdown = ""
                    dismiss()
                }

                Button("Cancel", role: .cancel) {
                    pendingMarkdown = ""
                }
            } message: {
                Text("Choose whether to keep the existing collection and import a copy, or replace the existing collection tree.")
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: allowedImportTypes,
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert("Import File Error", isPresented: Binding(
                get: { importErrorMessage != nil },
                set: { newValue in
                    if !newValue { importErrorMessage = nil }
                }
            )) {
                Button("OK", role: .cancel) {
                    importErrorMessage = nil
                }
            } message: {
                Text(importErrorMessage ?? "Unknown import error.")
            }
        }
    }

    private var allowedImportTypes: [UTType] {
        var types: [UTType] = [.plainText]

        if let markdownType = UTType(filenameExtension: "md") {
            types.append(markdownType)
        }

        if let markdownTextType = UTType(filenameExtension: "markdown") {
            types.append(markdownTextType)
        }

        return types
    }

    private func collectionTitle(from markdown: String) -> String {
        let normalizedMarkdown = IdeaMarkdownNormalizer.normalize(markdown)

        for rawLine in normalizedMarkdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.hasPrefix("# ") {
                return String(line.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if !line.isEmpty && !line.lowercased().hasPrefix("purpose:") {
                return line
            }
        }

        return "Imported Outline"
    }

    private func matchingExistingCollection(for importedTitle: String) -> IdeaCollection? {
        let importedKey = normalizedTitleKey(importedTitle)

        if let exact = allCollections.first(where: { normalizedTitleKey($0.name) == importedKey }) {
            return exact
        }

        return allCollections.first { collection in
            let existingKey = normalizedTitleKey(collection.name)
            return importedKey.contains(existingKey) || existingKey.contains(importedKey)
        }
    }

    private func normalizedTitleKey(_ title: String) -> String {
        title
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }

    private func markdownReplacingCollectionTitle(_ markdown: String, with title: String) -> String {
        var lines = markdown.components(separatedBy: .newlines)

        for index in lines.indices {
            let trimmedLine = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedLine.hasPrefix("# ") {
                lines[index] = "# \(title)"
                return lines.joined(separator: "\n")
            }

            if !trimmedLine.isEmpty && !trimmedLine.lowercased().hasPrefix("purpose:") {
                lines[index] = "# \(title)"
                return lines.joined(separator: "\n")
            }
        }

        return "# \(title)\n\n\(markdown)"
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }

            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let importedMarkdown = try String(contentsOf: url, encoding: .utf8)
            markdown = importedMarkdown
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ImportTreeSheet()
}
