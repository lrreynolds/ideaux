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
    @State private var userEditedName = false
    @State private var userEditedHeadline = false
    @State private var userEditedSummary = false
    @State private var inputMode: CollectionCreationInputMode = .text
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var speechErrorMessage: String?
    @State private var lastSpeechTranscript = ""
    @FocusState private var editorFocused: Bool

    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !captureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Describe the collection") {
                    Picker("Input", selection: $inputMode) {
                        Text("Text").tag(CollectionCreationInputMode.text)
                        Text("Voice").tag(CollectionCreationInputMode.voice)
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 12) {
                        if inputMode == .voice {
                            Button {
                                Task {
                                    await toggleRecording()
                                }
                            } label: {
                                Label(
                                    speechRecognizer.isRecording ? "Stop Recording" : "Start Recording",
                                    systemImage: speechRecognizer.isRecording ? "stop.circle.fill" : "mic.circle.fill"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }

                        if !captureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Button(role: .destructive) {
                                resetCapture()
                            } label: {
                                Label(inputMode == .voice ? "Clear and Re-record" : "Clear", systemImage: "arrow.counterclockwise")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }

                        if speechRecognizer.isRecording {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Listening…")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        TextEditor(text: $captureText)
                            .frame(minHeight: 120)
                            .focused($editorFocused)
                    }
                }

                Section("Collection") {
                    TextField("Name", text: Binding(
                        get: { name },
                        set: { newValue in
                            userEditedName = true
                            name = newValue
                        }
                    ))

                    TextField("Headline", text: Binding(
                        get: { headline },
                        set: { newValue in
                            userEditedHeadline = true
                            headline = newValue
                        }
                    ), axis: .vertical)
                    .lineLimit(1...2)

                    TextField("Short Summary", text: Binding(
                        get: { summary },
                        set: { newValue in
                            userEditedSummary = true
                            summary = newValue
                        }
                    ), axis: .vertical)
                    .lineLimit(2...4)
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        resetCapture()
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
                updateDraftFields(from: newValue)
            }
            .onChange(of: speechRecognizer.transcript) { _, newValue in
                mergeSpeechTranscript(newValue)
            }
            .alert("Speech Capture Error", isPresented: Binding(
                get: { speechErrorMessage != nil },
                set: { newValue in
                    if !newValue { speechErrorMessage = nil }
                }
            )) {
                Button("OK", role: .cancel) {
                    speechErrorMessage = nil
                }
            } message: {
                Text(speechErrorMessage ?? "Unknown speech capture error.")
            }
        }
    }

    private func resetCapture() {
        speechRecognizer.stopRecording()
        speechRecognizer.transcript = ""
        lastSpeechTranscript = ""
        editorFocused = false
        captureText = ""
        name = ""
        headline = ""
        summary = ""
        userEditedName = false
        userEditedHeadline = false
        userEditedSummary = false
    }

    private func toggleRecording() async {
        if speechRecognizer.isRecording {
            speechRecognizer.stopRecording()
            return
        }

        let hasPermission = await speechRecognizer.requestPermissions()
        guard hasPermission else {
            speechErrorMessage = "Speech recognition or microphone permission was not granted."
            return
        }

        editorFocused = false
        lastSpeechTranscript = ""

        do {
            try await speechRecognizer.startRecording()
        } catch {
            speechErrorMessage = error.localizedDescription
        }
    }

    private func mergeSpeechTranscript(_ newTranscript: String) {
        let newSegment = newTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newSegment.isEmpty else { return }

        let previousSegment = lastSpeechTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        defer { lastSpeechTranscript = newSegment }

        if captureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            captureText = newSegment
            return
        }

        if !previousSegment.isEmpty,
           newSegment.hasPrefix(previousSegment) {
            let suffix = String(newSegment.dropFirst(previousSegment.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            appendSpeechSegment(suffix)
            return
        }

        appendSpeechSegment(newSegment)
    }

    private func appendSpeechSegment(_ segment: String) {
        let segment = segment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !segment.isEmpty else { return }

        let existing = captureText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !existing.isEmpty else {
            captureText = segment
            return
        }

        let existingWords = existing.split(separator: " ").map(String.init)
        let segmentWords = segment.split(separator: " ").map(String.init)

        let maxOverlap = min(existingWords.count, segmentWords.count)
        var overlap = 0

        if maxOverlap > 0 {
            for count in stride(from: maxOverlap, through: 1, by: -1) {
                let existingSuffix = existingWords.suffix(count).map { $0.lowercased() }
                let segmentPrefix = segmentWords.prefix(count).map { $0.lowercased() }

                if Array(existingSuffix) == Array(segmentPrefix) {
                    overlap = count
                    break
                }
            }
        }

        let wordsToAppend = segmentWords.dropFirst(overlap)
        guard !wordsToAppend.isEmpty else { return }

        captureText = existing + " " + wordsToAppend.joined(separator: " ")
    }

    private func createCollection() {
        let cleanedCapture = captureText.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedHeadline = headline.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)

        let sourceSummary = cleanedSummary.isEmpty ? cleanedCapture : cleanedSummary
        let finalName = cleanedName.isEmpty ? fallbackName(from: sourceSummary) : cleanedName
        let finalHeadline = cleanedHeadline.isEmpty ? fallbackHeadline(from: sourceSummary, name: finalName) : cleanedHeadline
        let finalSummary = sourceSummary
        let purpose = cleanedCapture.isEmpty ? finalSummary : cleanedCapture

        resetCapture()
        onCreate(finalName, finalHeadline, finalSummary, purpose)
    }

    private func updateDraftFields(from text: String) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        if !userEditedSummary {
            summary = cleaned
        }

        let draftSummary = userEditedSummary ? summary : cleaned

        if !userEditedName {
            name = fallbackName(from: draftSummary)
        }

        if !userEditedHeadline {
            headline = fallbackHeadline(from: draftSummary, name: name)
        }
    }

    private func fallbackName(from text: String) -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return "New Collection" }

        let words = cleaned
            .split(separator: " ")
            .prefix(5)
            .joined(separator: " ")

        return String(words.prefix(48))
    }

    private func fallbackHeadline(from text: String, name: String) -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return name }

        let firstSentence = cleaned
            .split(whereSeparator: { ".!?".contains($0) })
            .first
            .map(String.init) ?? cleaned

        return String(firstSentence.trimmingCharacters(in: .whitespacesAndNewlines).prefix(90))
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
