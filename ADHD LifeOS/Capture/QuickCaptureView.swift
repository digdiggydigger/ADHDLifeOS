//
//  QuickCaptureView.swift
//  ADHD LifeOS
//
//  The v3 composer (F-V3-Capture): opened by the capture fan with its kind already chosen, so it
//  reads as a recorder, a camera, a link card or an effort picker — never an empty form. The
//  copy, CTA and destination per kind live in `CaptureComposerCopy` (pure, tested). The optional
//  life-area chips ride the existing create input; the Task kind skips the inbox and lands in
//  Today through the existing task seams (create, then the focus target via the update payload).
//

import PhotosUI
import SwiftUI

struct QuickCaptureView: View {
    /// Internal, not private: the section builders live in `QuickCaptureComponents.swift`.
    @StateObject var service: CaptureInboxService
    @Environment(\.dismiss) private var dismiss
    let onCreated: () -> Void

    private let homeClient: HomeClientAdapting?
    private let taskCreateClient: TaskCreateClientAdapting?
    private let taskDetailClient: TaskDetailClientAdapting?

    @State var photoPickerItem: PhotosPickerItem?
    @State var selectedImageData: Data?
    @State var isShowingCamera = false
    @State var lifeAreas: [LifeArea] = []
    @State var taskEffortSeconds = 900
    @State private var isSubmittingTask = false
    @State var taskErrorMessage: String?

    @StateObject var recorder = VoiceCaptureRecorder()
    @State var recordedAudioURL: URL?

    init(
        client: CaptureClientAdapting,
        kind: CaptureKind = .note,
        homeClient: HomeClientAdapting? = nil,
        taskCreateClient: TaskCreateClientAdapting? = nil,
        taskDetailClient: TaskDetailClientAdapting? = nil,
        onCreated: @escaping () -> Void
    ) {
        _service = StateObject(wrappedValue: {
            let service = CaptureInboxService(client: client)
            service.kind = kind
            return service
        }())
        self.homeClient = homeClient
        self.taskCreateClient = taskCreateClient
        self.taskDetailClient = taskDetailClient
        self.onCreated = onCreated
    }

    var kind: CaptureKind { service.kind }
    var fanSlot: CaptureFan.Slot { CaptureFan.slot(for: kind) }
    var isTaskKind: Bool { kind == .task && taskCreateClient != nil }

    var isSaveDisabled: Bool {
        guard !service.isSubmittingCapture, !isSubmittingTask else { return true }
        if kind == .photo { return selectedImageData == nil }
        if kind == .voice { return recordedAudioURL == nil }
        return !service.isContentValid
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(CaptureComposerCopy.hint(for: kind))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    contentSection
                    if isTaskKind {
                        effortSection
                    }
                    if let errorMessage = service.createCaptureErrorMessage ?? taskErrorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Color("StateRisk"))
                            .accessibilityIdentifier("quickCaptureErrorMessage")
                    }
                    Label(CaptureComposerCopy.footer(for: kind), systemImage: "lock")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    areaSection
                }
                .padding(16)
            }
            .background(Color.pageBackground.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) { footerBar }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(fanSlot.fillAssetName))
                            .frame(width: 10, height: 10)
                        Text(CaptureComposerCopy.title(for: kind))
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { submit() }
                        .disabled(isSaveDisabled)
                        .accessibilityIdentifier("quickCaptureSubmitButton")
                }
            }
            .task {
                await service.refreshWeekCounterweight()
                if let homeClient {
                    lifeAreas = ((try? await homeClient.fetchLifeAreas()) ?? [])
                        .filter { !$0.archived }
                        .sorted { $0.sortOrder < $1.sortOrder }
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

    // MARK: - Behaviour

    var contentFieldPlaceholder: String {
        switch kind {
        case .photo: return "Caption (optional)"
        case .link: return "Paste a link"
        case .task: return "What needs doing?"
        default: return "What's on your mind?"
        }
    }

    var voiceRecordButtonTitle: String {
        if recorder.isRecording { return "Stop Recording" }
        return recordedAudioURL == nil ? "Record Voice Note" : "Re-record"
    }

    func toggleRecording() async {
        if recorder.isRecording {
            recordedAudioURL = recorder.stopRecording()
        } else {
            recordedAudioURL = nil
            await recorder.startRecording()
        }
    }

    func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        selectedImageData = PhotoCaptureImageProcessing.downscaledJPEGData(from: data) ?? data
    }

    /// The per-kind escape hatch, v3's alt button: kinds that switch destination switch kind in
    /// place; media kinds reset their media.
    func performAlt() {
        switch kind {
        case .note: service.kind = .task
        case .task: service.kind = .note
        case .voice:
            recordedAudioURL = nil
            Task { await recorder.startRecording() }
        case .photo:
            selectedImageData = nil
            if UIImagePickerController.isSourceTypeAvailable(.camera) { isShowingCamera = true }
        case .link: service.content = ""
        }
    }

    func submit() {
        Task {
            if await save() {
                onCreated()
                dismiss()
            }
        }
    }

    private func save() async -> Bool {
        if isTaskKind { return await saveTask() }
        if kind == .photo, let selectedImageData {
            return await service.createPhotoCapture(imageData: selectedImageData)
        }
        if kind == .voice, let recordedAudioURL {
            return await service.createVoiceCapture(audioFileURL: recordedAudioURL)
        }
        return await service.createCapture()
    }

    /// The fast-task path: create through the existing seams, then the effort chip lands as
    /// `focusDurationSeconds` via the update payload (the create input has no focus fields).
    private func saveTask() async -> Bool {
        guard let taskCreateClient else { return false }
        taskErrorMessage = nil
        let title = service.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            taskErrorMessage = "Give the task a name first."
            return false
        }
        isSubmittingTask = true
        defer { isSubmittingTask = false }
        do {
            let input = NormalizedCreateTaskInput(
                title: title, notes: nil,
                lifeAreaId: service.newCaptureLifeAreaId,
                dueDate: Calendar.current.startOfDay(for: .now),
                priority: .p3
            )
            let created = try await taskCreateClient.createTask(input)
            if let taskDetailClient {
                var payload = TaskUpdatePayload()
                payload.focusDurationSeconds = taskEffortSeconds
                _ = try await taskDetailClient.updateTask(id: created.id, payload: payload)
            }
            service.content = ""
            service.newCaptureLifeAreaId = nil
            return true
        } catch {
            taskErrorMessage =
                (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }
}
