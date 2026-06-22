//
//  CollectionCreationSheet.swift
//  IdeaUX
//
//  Created by LouR on 6/22/26.
//

import SwiftUI

struct CollectionCreationSheet: View {
    let onCancel: () -> Void
    let onCreate: (_ name: String, _ headline: String, _ summary: String, _ purpose: String) -> Void

    @State private var captureText = ""
    @State private var name = ""
    @State private var headline = ""
    @State private var summary = ""
    @State private var inputMode: CollectionCreationInputMode = .text

    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !captureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Start with a thought") {
                    Picker("Input", selection: $inputMode) {
                        Text("Text").tag(CollectionCreationInputMode.text)
                        Text("Voice").tag(CollectionCreationInputMode.voice)
                    }
                    .pickerStyle(.segmented)

                    if inputMode == .text {
                        TextEditor(text: $captureText)
                            .frame(minHeight: 120)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            TextEditor(text: $captureText)
                                .frame(minHeight: 120)

                            Text("Voice capture will use the same recorder flow as idea capture once wired in.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Collection") {
                    TextField("Name", text: $name)
                    TextField("Headline", text: $headline, axis: .vertical)
                        .lineLimit(1...2)
                    TextField("Short Summary", text: $summary, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createCollection()
                    }
                    .disabled(!canCreate)
                }
            }
            .onChange(of: captureText) { _, newValue in
                fillDraftFieldsIfNeeded(from: newValue)
            }
        }
    }

    private func createCollection() {
        let cleanedCapture = captureText.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedHeadline = headline.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)

        let finalName = cleanedName.isEmpty ? fallbackName(from: cleanedCapture) : cleanedName
        let finalHeadline = cleanedHeadline.isEmpty ? fallbackHeadline(from: cleanedCapture, name: finalName) : cleanedHeadline
        let finalSummary = cleanedSummary.isEmpty ? cleanedCapture : cleanedSummary
        let purpose = cleanedCapture.isEmpty ? finalSummary : cleanedCapture

        onCreate(finalName, finalHeadline, finalSummary, purpose)
    }

    private func fillDraftFieldsIfNeeded(from text: String) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            name = fallbackName(from: cleaned)
        }

        if headline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            headline = fallbackHeadline(from: cleaned, name: name)
        }

        if summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            summary = cleaned
        }
    }

    private func fallbackName(from text: String) -> String {
        let firstLine = text
            .split(separator: "\n", omittingEmptySubsequences: true)
            .first
            .map(String.init) ?? "New Collection"

        return String(firstLine.prefix(48))
    }

    private func fallbackHeadline(from text: String, name: String) -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty { return name }
        return String(cleaned.prefix(90))
    }
}

private enum CollectionCreationInputMode: String, CaseIterable, Identifiable {
    case text
    case voice

    var id: String { rawValue }
}

#Preview {
    CollectionCreationSheet(
        onCancel: {},
        onCreate: { _, _, _, _ in }
    )
}
