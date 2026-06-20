//
//  IdeaCaptureSheet.swift
//  IdeaUX
//
//  Created by LouR on 6/19/26.
//

import SwiftUI

enum IdeaCaptureMode: String, CaseIterable, Identifiable {
    case voice
    case text
    var id: String { rawValue }
}

struct IdeaCaptureSheet: View {
    
    @AppStorage("ideaCaptureMode") private var captureModeRaw = IdeaCaptureMode.voice.rawValue

    private var captureMode: IdeaCaptureMode {
        get { IdeaCaptureMode(rawValue: captureModeRaw) ?? .voice }
        set { captureModeRaw = newValue.rawValue }
    }
    
    let title: String
    let sectionTitle: String
    let onCancel: () -> Void
    let onSave: (String) -> Void

    @State private var captureText = ""
    @FocusState private var editorFocused: Bool
    
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var speechErrorMessage: String?
    @State private var lastSpeechTranscript = ""
    

    var body: some View {
        NavigationStack {
            Form {
                Picker("Capture Mode", selection: $captureModeRaw) {
                    Text("Voice").tag(IdeaCaptureMode.voice.rawValue)
                    Text("Text").tag(IdeaCaptureMode.text.rawValue)
                }
                .pickerStyle(.segmented)
                Section(sectionTitle) {
                    VStack(alignment: .leading, spacing: 12) {
                        if captureMode == .voice {
                            
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
                                Label("Clear and Re-record", systemImage: "arrow.counterclockwise")
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
                            .frame(minHeight: 160)
                            .focused($editorFocused)
                    }
                }
            }
            .navigationTitle(title)
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        resetCapture()
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let text = captureText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                        resetCapture()
                        onSave(text)
                    }
                    .disabled(captureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    private func resetCapture() {
        speechRecognizer.stopRecording()
        speechRecognizer.transcript = ""
        lastSpeechTranscript = ""
        editorFocused = false
        captureText = ""
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
}
