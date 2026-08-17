//
//  QuickCaptureView.swift
//  ADHD LifeOS
//

import PhotosUI
import SwiftUI

struct QuickCaptureView: View {
    @StateObject private var service: CaptureInboxService
    @Environment(\.dismiss) private var dismiss
    let onCreated: () -> Void

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isShowingCamera = false

    @StateObject private var recorder = VoiceCaptureRecorder()
    @State private var recordedAudioURL: URL?

    init(client: CaptureClientAdapting, onCreated: @escaping () -> Void) {
        _service = StateObject(wrappedValue: CaptureInboxService(client: client))
        self.onCreated = onCreated
    }

    private var isPhotoKind: Bool { service.kind == .photo }
    private var isVoiceKind: Bool { service.kind == .voice }
    private var isLinkKind: Bool { service.kind == .link }

    private var isSaveDisabled: Bool {
        guard !service.isSubmittingCapture else { return true }
        if isPhotoKind { return selectedImageData == nil }
        if isVoiceKind { return recordedAudioURL == nil }
        return !service.isContentValid
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if !isVoiceKind {
                        TextField(
                            contentFieldPlaceholder,
                            text: $service.content, axis: .vertical
                        )
                        .keyboardType(isLinkKind ? .URL : .default)
                        .textInputAutocapitalization(isLinkKind ? .never : .sentences)
                        .autocorrectionDisabled(isLinkKind)
                        .accessibilityIdentifier("quickCaptureContentField")
                    }

                    Picker("Kind", selection: $service.kind) {
                        ForEach(CaptureKind.allCases, id: \.self) { kind in
                            Text(kind.rawValue.capitalized).tag(kind)
                        }
                    }
                    .accessibilityIdentifier("quickCaptureKindPicker")
                }

                if isPhotoKind {
                    photoSection
                }

                if isVoiceKind {
                    voiceSection
                }

                if let errorMessage = service.createCaptureErrorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("quickCaptureErrorMessage")
                }
            }
            .navigationTitle("Quick Capture")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await save() {
                                onCreated()
                                dismiss()
                            }
                        }
                    }
                    .disabled(isSaveDisabled)
                    .accessibilityIdentifier("quickCaptureSubmitButton")
                }
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraCapturePicker { data in
                    selectedImageData = PhotoCaptureImageProcessing.downscaledJPEGData(from: data) ?? data
                }
                .ignoresSafeArea()
            }
        }
    }

    private var photoSection: some View {
        Section {
            if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .accessibilityIdentifier("quickCapturePhotoPreview")
            }

            PhotosPicker("Choose Photo", selection: $photoPickerItem, matching: .images)
                .accessibilityIdentifier("quickCapturePhotoPickerButton")
                .onChange(of: photoPickerItem) { newItem in
                    Task { await loadPickedPhoto(newItem) }
                }

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") { isShowingCamera = true }
                    .accessibilityIdentifier("quickCameraButton")
            }
        }
    }

    private func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        selectedImageData = PhotoCaptureImageProcessing.downscaledJPEGData(from: data) ?? data
    }

    private var voiceSection: some View {
        Section {
            if let message = recorder.permissionDeniedMessage {
                Text(message)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("quickCaptureVoicePermissionMessage")
            }

            Button(voiceRecordButtonTitle) {
                Task { await toggleRecording() }
            }
            .accessibilityIdentifier("quickCaptureRecordButton")

            if recordedAudioURL != nil, !recorder.isRecording {
                Text("Voice note recorded")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("quickCaptureVoiceRecordedLabel")
            }
        }
    }

    private var voiceRecordButtonTitle: String {
        if recorder.isRecording { return "Stop Recording" }
        return recordedAudioURL == nil ? "Record Voice Note" : "Re-record"
    }

    private var contentFieldPlaceholder: String {
        if isPhotoKind { return "Caption (optional)" }
        if isLinkKind { return "Paste a link" }
        return "What's on your mind?"
    }

    private func toggleRecording() async {
        if recorder.isRecording {
            recordedAudioURL = recorder.stopRecording()
        } else {
            recordedAudioURL = nil
            await recorder.startRecording()
        }
    }

    private func save() async -> Bool {
        if isPhotoKind, let selectedImageData {
            return await service.createPhotoCapture(imageData: selectedImageData)
        }
        if isVoiceKind, let recordedAudioURL {
            return await service.createVoiceCapture(audioFileURL: recordedAudioURL)
        }
        return await service.createCapture()
    }
}

#if DEBUG
private struct PreviewCaptureClientAdapting: CaptureClientAdapting {
    func createCapture(_ input: NormalizedCreateCaptureInput) async throws -> Capture {
        fatalError("unused in preview")
    }
    func fetchUnprocessedCaptures() async throws -> [Capture] { [] }
    func fetchCapture(id: UUID) async throws -> Capture { fatalError("unused in preview") }
    func createTask(_ input: NormalizedPromoteToTaskInput) async throws -> TaskItem {
        fatalError("unused in preview")
    }
    func markProcessed(captureId: UUID) async throws {}
    func requestUploadURL(kind: CaptureKind, contentType: String) async throws -> CaptureUploadTarget {
        fatalError("unused in preview")
    }
    func uploadMedia(to uploadURL: URL, data: Data, contentType: String) async throws {}
    func updateCapture(id: UUID, changes: CaptureUpdate) async throws -> Capture {
        fatalError("unused in preview")
    }
    func fetchAllTags() async throws -> [Tag] { [] }
    func createTag(name: String) async throws -> Tag { fatalError("unused in preview") }
    func fetchTags(captureId: UUID) async throws -> [Tag] { [] }
    func addTag(captureId: UUID, tagId: UUID) async throws {}
    func removeTag(captureId: UUID, tagId: UUID) async throws {}
}

#Preview {
    QuickCaptureView(client: PreviewCaptureClientAdapting()) {}
}
#endif
