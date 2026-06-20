//
//  IdeaCaptureSheet.swift
//  IdeaUX
//
//  Created by LouR on 6/19/26.
//

import SwiftUI

struct IdeaCaptureSheet: View {
    let title: String
    let sectionTitle: String
    let onCancel: () -> Void
    let onSave: (String) -> Void

    @State private var captureText = ""
    @FocusState private var editorFocused: Bool
    
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var speechErrorMessage: String?
    

    var body: some View {
        NavigationStack {
            Form {
                Section(sectionTitle) {
                    VStack(alignment: .leading, spacing: 12) {
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
                captureText = newValue
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
                        speechRecognizer.stopRecording()
                        editorFocused = false
                        captureText = ""
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let text = captureText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                        speechRecognizer.stopRecording()
                        editorFocused = false
                        captureText = ""
                        onSave(text)
                    }
                    .disabled(captureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
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

        do {
            try await speechRecognizer.startRecording()
        } catch {
            speechErrorMessage = error.localizedDescription
        }
    }
}
