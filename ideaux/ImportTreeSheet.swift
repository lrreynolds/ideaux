import SwiftUI
import SwiftData

struct ImportTreeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \IdeaCollection.name) private var allCollections: [IdeaCollection]

    @State private var markdown: String = ""
    @State private var pendingMarkdown: String = ""
    @State private var showingImportConflict = false

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
                        // TODO: fileImporter integration
                    } label: {
                        Label("Import File", systemImage: "doc.badge.plus")
                    }
                    .disabled(true)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        let trimmed = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }

                        let title = collectionTitle(from: trimmed)
                        let existingCollection = allCollections.first { $0.name == title }

                        if existingCollection != nil {
                            pendingMarkdown = trimmed
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
        }
    }

    private func collectionTitle(from markdown: String) -> String {
        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.hasPrefix("# ") {
                return String(line.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return "Imported Outline"
    }
}

#Preview {
    ImportTreeSheet()
}
