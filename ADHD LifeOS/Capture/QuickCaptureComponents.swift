//
//  QuickCaptureComponents.swift
//  ADHD LifeOS
//
//  The composer's chip-flow helper and previews, split from `QuickCaptureView.swift` for its
//  length budgets.
//

import PhotosUI
import SwiftUI

/// A minimal wrapping HStack for the area chips — rows of chips that flow onto new lines.
struct FlowingChips<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        // iOS 16 floor: no Layout-protocol flow here — a wrapping LazyVGrid keeps it simple and
        // predictable (chips share a two-per-row rhythm at accessibility sizes too).
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 132), spacing: spacing)],
            alignment: .leading,
            spacing: spacing
        ) {
            content()
        }
    }
}

#if DEBUG
#Preview("Note Light") {
    QuickCaptureView(client: QuickCapturePreviewClient(), kind: .note) {}
        .preferredColorScheme(.light)
}

#Preview("Task Dark") {
    QuickCaptureView(client: QuickCapturePreviewClient(), kind: .task) {}
        .preferredColorScheme(.dark)
}

private struct QuickCapturePreviewClient: CaptureClientAdapting {
    func createCapture(_ input: NormalizedCreateCaptureInput) async throws -> Capture {
        Capture(id: UUID(), content: input.content, kind: input.kind, processed: false, createdAt: Date())
    }
    func fetchUnprocessedCaptures() async throws -> [Capture] { [] }
    func fetchCaptures() async throws -> [Capture] { [] }
    func fetchCapture(id: UUID) async throws -> Capture { fatalError("unused in preview") }
    func createTask(_ input: NormalizedPromoteToTaskInput) async throws -> TaskItem {
        fatalError("unused in preview")
    }
    func markProcessed(captureId: UUID) async throws {}
    func requestUploadURL(kind: CaptureKind, contentType: String) async throws -> CaptureUploadTarget {
        fatalError("unused in preview")
    }
    func fetchProcessedCaptures() async throws -> [Capture] { [] }
    func fetchSeenCaptures() async throws -> [Capture] { [] }
    func deleteCapture(id: UUID) async throws {}
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
#endif

// MARK: - Sections

extension QuickCaptureView {
    @ViewBuilder
    var contentSection: some View {
        if kind != .voice {
            TextField(
                contentFieldPlaceholder,
                text: $service.content, axis: .vertical
            )
            .keyboardType(kind == .link ? .URL : .default)
            .textInputAutocapitalization(kind == .link ? .never : .sentences)
            .autocorrectionDisabled(kind == .link)
            .lineLimit(4...8)
            .padding(16)
            .background(Color("CardSurfaceSecondary"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.cardBorder, lineWidth: 1)
            )
            .accessibilityIdentifier("quickCaptureContentField")
        }
        if kind == .photo {
            photoSection
        }
        if kind == .voice {
            voiceSection
        }
    }

    var effortSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How long will it take?")
                .sectionLabel()
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                effortChip(seconds: 900, label: "15 min")
                effortChip(seconds: 1800, label: "30 min")
                effortChip(seconds: 3600, label: "1 hr")
            }
        }
    }

    private func effortChip(seconds: Int, label: String) -> some View {
        let selected = taskEffortSeconds == seconds
        return Button {
            taskEffortSeconds = seconds
        } label: {
            Text(label)
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(selected ? Color(fanSlot.onAssetName) : Color("LabelSecondary"))
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(
                    selected
                        ? AnyShapeStyle(Color(fanSlot.fillAssetName))
                        : AnyShapeStyle(Color("CardSurfaceSecondary")),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("quickCaptureEffort-\(seconds)")
    }

    @ViewBuilder
    var areaSection: some View {
        if !lifeAreas.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("Life area")
                        .sectionLabel()
                        .foregroundStyle(.secondary)
                    Text("optional")
                        .font(.footnote)
                        .foregroundStyle(Color("LabelTertiary"))
                }
                FlowingChips(spacing: 8) {
                    areaChip(id: nil, label: "Decide later", family: nil)
                    ForEach(lifeAreas) { area in
                        areaChip(
                            id: area.id,
                            label: "\(area.colour) \(area.name)",
                            family: AreaPalette.family(for: area)
                        )
                    }
                }
            }
        }
    }

    private func areaChip(id: UUID?, label: String, family: AreaPalette?) -> some View {
        let selected = service.newCaptureLifeAreaId == id
        let background: AnyShapeStyle
        let foreground: Color
        if selected, let family {
            (background, foreground) = (AnyShapeStyle(family.tint), family.color)
        } else if selected {
            (background, foreground) = (AnyShapeStyle(Color(fanSlot.fillAssetName)), Color(fanSlot.onAssetName))
        } else {
            (background, foreground) = (AnyShapeStyle(Color("CardSurfaceSecondary")), Color("LabelSecondary"))
        }
        return Button {
            service.newCaptureLifeAreaId = id
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(foreground)
                .padding(.horizontal, 8)
                .frame(minHeight: 36)
                .background(background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityIdentifier("quickCapturePhotoPreview")
            }
            PhotosPicker("Choose Photo", selection: $photoPickerItem, matching: .images)
                .buttonStyle(MomentumBorderedButtonStyle())
                .accessibilityIdentifier("quickCapturePhotoPickerButton")
                .onChange(of: photoPickerItem) { newItem in
                    Task { await loadPickedPhoto(newItem) }
                }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") { isShowingCamera = true }
                    .buttonStyle(MomentumBorderedButtonStyle())
                    .accessibilityIdentifier("quickCameraButton")
            }
        }
    }

    private var voiceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let message = recorder.permissionDeniedMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color("StateRisk"))
                    .accessibilityIdentifier("quickCaptureVoicePermissionMessage")
            }
            Button {
                Task { await toggleRecording() }
            } label: {
                Label(
                    voiceRecordButtonTitle,
                    systemImage: recorder.isRecording ? "stop.fill" : "waveform"
                )
            }
            .buttonStyle(MomentumSolidButtonStyle(
                fill: recorder.isRecording ? Color("StateRisk") : Color(fanSlot.fillAssetName),
                foreground: recorder.isRecording ? .white : Color(fanSlot.onAssetName)
            ))
            .accessibilityIdentifier("quickCaptureRecordButton")
            if recordedAudioURL != nil, !recorder.isRecording {
                Label("Voice note recorded", systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(Color("StateGo"))
                    .accessibilityIdentifier("quickCaptureVoiceRecordedLabel")
            }
        }
    }

    var footerBar: some View {
        VStack(spacing: 8) {
            // S1's counterweight to the frictionless button (Concept C, M5 + M10): nothing
            // needs filing NOW — and the week's ledger backs that up when there are numbers.
            if let weekLine = service.weekCounterweightLine {
                Text(weekLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("quickCaptureWeekCounterweight")
            }
            Button {
                submit()
            } label: {
                Label(
                    CaptureComposerCopy.ctaLabel(for: kind),
                    systemImage: kind == .task ? "checkmark.circle.fill" : "tray.and.arrow.down.fill"
                )
            }
            .buttonStyle(MomentumSolidButtonStyle(
                fill: Color(fanSlot.fillAssetName), foreground: Color(fanSlot.onAssetName)
            ))
            .disabled(isSaveDisabled)
            .accessibilityIdentifier("quickCaptureCTAButton")
            Button(CaptureComposerCopy.altLabel(for: kind), action: performAlt)
                .buttonStyle(MomentumBorderedButtonStyle(minHeight: 44))
                .accessibilityIdentifier("quickCaptureAltButton")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(.bar)
    }
}
