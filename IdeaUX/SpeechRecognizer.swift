//
//  SpeechRecognizer.swift
//  IdeaUX
//
//  Created by LouR on 6/19/26.
//


import Foundation
import Speech
import AVFoundation
import Observation

@Observable
@MainActor
final class SpeechRecognizer {

    var transcript: String = ""
    var isRecording: Bool = false

    private let recognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func requestPermissions() async -> Bool {
        let speechAuthorized = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        let micAuthorized = await AVAudioApplication.requestRecordPermission()

        return speechAuthorized && micAuthorized
    }

    func startRecording() async throws {
        stopRecording()

        transcript = ""

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true

        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
            [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = recognizer?.recognitionTask(with: request) {
            [weak self] result, error in

            guard let self else { return }

            if let result {
                Task { @MainActor in
                    self.transcript = result.bestTranscription.formattedString
                }
            }

            if error != nil {
                Task { @MainActor in
                    self.stopRecording()
                }
            }
        }

        isRecording = true
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil

        isRecording = false
    }
}
