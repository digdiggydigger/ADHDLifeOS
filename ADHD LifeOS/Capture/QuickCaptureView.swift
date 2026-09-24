//
//  QuickCaptureView.swift
//  ADHD LifeOS
//
//  The v3 composer (F-V3-Capture): opened by the capture fan with its kind already chosen, so it
//  reads as a recorder, a camera, a link card or an effort picker — never an empty form. The
//  copy, CTA and destination per kind live in `CaptureComposerCopy` (pure, tested). The optional
//  life-area chips ride the existing create input.
//
//  **No Task kind any more** (`F-D1-ComposerBothDoors`): the capture disc's Task tile opens
//  `TaskCreateView`, the one task composer, so the fast-task path that lived here — its effort
//  chips, `saveTask()` and the two task clients only it used — was deleted rather than left
//  unreachable. `CaptureKind.task` itself stays: the fan tile and stored captures still carry it.
//

import PhotosUI
import SwiftUI

struct QuickCaptureView: View {
    /// Internal, not private: the section builders live in `QuickCaptureComponents.swift`.
    @StateObject var service: CaptureInboxService
    @Environment(\.dismiss) private var dismiss
    let onCreated: () -> Void

    /// `F-C2-DraftsToInbox`: kept so the draft filer can write through the same seam the service
    /// already uses. The service takes the client but does not hand it back.
    private let captureClient: CaptureClientAdapting
    private let homeClient: HomeClientAdapting?

    @State var photoPickerItem: PhotosPickerItem?
    @State var selectedImageData: Data?
    @State var isShowingCamera = false
    @State var lifeAreas: [LifeArea] = []
    @State var availableTags: [Tag] = []
    @State var draftTagName = ""
    /// `F-C2-DraftsToInbox`: a composer that SUBMITTED files no draft on the way out. Without it
    /// the text is still in the service when the sheet dismisses, and the just-saved words would
    /// be filed a second time as an abandoned draft.
    @State private var didSubmit = false

    @Environment(\.recordAction) private var recordAction
    @Environment(\.openCapture) private var openCapture

    @StateObject var recorder = VoiceCaptureRecorder()
    @State var recordedAudioURL: URL?

    init(
        client: CaptureClientAdapting,
        kind: CaptureKind = .note,
        homeClient: HomeClientAdapting? = nil,
        onCreated: @escaping () -> Void
    ) {
        _service = StateObject(wrappedValue: {
            let service = CaptureInboxService(client: client)
            service.kind = kind
            return service
        }())
        self.captureClient = client
        self.homeClient = homeClient
        self.onCreated = onCreated
    }

    var kind: CaptureKind { service.kind }
    var fanSlot: CaptureFan.Slot { CaptureFan.slot(for: kind) }

    var isSaveDisabled: Bool {
        guard !service.isSubmittingCapture else { return true }
        if kind == .photo { return selectedImageData == nil }
        if kind == .voice { return recordedAudioURL == nil }
        return !service.isContentValid
    }

    /// The per-capture location switch (E, 2026-08-27). Only shown when permission actually
    /// allows a fix — a switch that cannot do anything invites a tap that achieves nothing
    /// silently. Its default is the global Settings toggle, and it resets after every capture,
    /// because this is a decision about THIS capture rather than a preference.
    @ViewBuilder
    private var locationSection: some View {
        if CaptureLocationChoice.isAvailable(
            authorization: CoreLocationFixProvider.shared.authorizationState
        ) {
            Toggle(isOn: $service.attachLocation) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Remember where I am")
                            .font(.subheadline)
                        Text(service.attachLocation
                             ? "This capture will record where you made it."
                             : "This capture won't record where you made it.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: service.attachLocation ? "location.fill" : "location.slash")
                        .foregroundStyle(service.attachLocation ? Color.accentColor : .secondary)
                }
            }
            .onChange(of: service.attachLocation) { Haptics.play(.selection) }
            .accessibilityIdentifier("captureLocationToggle")
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(CaptureComposerCopy.hint(for: kind))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    contentSection
                    if let errorMessage = service.createCaptureErrorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Color("StateRisk"))
                            .accessibilityIdentifier("quickCaptureErrorMessage")
                    }
                    Label(CaptureComposerCopy.footer(for: kind), systemImage: "lock")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    areaSection
                    tagsSection
                    locationSection
                }
                .padding(16)
            }
            .background(Color.pageBackground.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) { footerBar }
            .navigationBarTitleDisplayMode(.inline)
            // **`F-C2-DraftsToInbox`, and `.onDisappear` is deliberate** (Step 0 answer 2: prefer
            // filing once the sheet has ACTUALLY gone, so a swipe keeps dismissing as it does
            // today). It is also the only hook that covers both of this composer's presentations:
            // a `.fullScreenCover` from the capture disc, where there is no swipe, and a `.sheet`
            // from the Capture Inbox, where there is. A half-swipe that springs back never calls
            // it, so a cancelled dismissal files nothing by construction.
            .onDisappear { fileDraftIfNeeded() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // **"Close", not "Cancel"** (E, round 2). `sheets.md › Best practices`:
                    // Cancel means *without saving*, and this control no longer discards — typed
                    // text is filed into the inbox on the way out.
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("quickCaptureCloseButton")
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
            }
            .task {
                await service.refreshWeekCounterweight()
                availableTags = await service.fetchAllTags()
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

    /// Files whatever was typed and not sent — E, round 2: *"A composer closed with text files it
    /// into the Capture Inbox as a note."*
    ///
    /// **Only the typed content**, which is the spec's accepted cost named out loud: a voice or
    /// photo capture's media is not "typed text" and is unaffected, and the area and tags are
    /// dropped — a filed draft is an ordinary note, not a richer draft
    /// object nobody else knows how to read.
    private func fileDraftIfNeeded() {
        guard !didSubmit else { return }
        let text = service.content
        let filer = ComposerDraftFiler(
            client: captureClient, record: recordAction, openCapture: openCapture
        )
        Task { await filer.fileIfNeeded(text) }
    }

    func submit() {
        Task {
            if await save() {
                didSubmit = true
                Haptics.play(.solid)
                onCreated()
                dismiss()
            } else {
                Haptics.play(.error)
            }
        }
    }

    private func save() async -> Bool {
        if kind == .photo, let selectedImageData {
            return await service.createPhotoCapture(imageData: selectedImageData)
        }
        if kind == .voice, let recordedAudioURL {
            return await service.createVoiceCapture(audioFileURL: recordedAudioURL)
        }
        return await service.createCapture()
    }
}
