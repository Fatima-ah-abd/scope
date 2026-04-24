import SwiftUI

enum CaptureComposerMode {
    case text
    case audio
}

struct CaptureComposerView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let preferredScopeID: UUID?
    let initialMode: CaptureComposerMode

    @State private var selectedScopeID: UUID?
    @State private var assignmentSource: ScopeAssignmentSource = .autoSuggested
    @State private var noteText = ""
    @State private var includesPhoto = false
    @State private var includesVideo = false
    @State private var elapsedSeconds: TimeInterval
    @State private var isRecording: Bool
    @State private var didBootstrap = false
    @State private var isShowingScopePicker = false
    @State private var autoScopeSuggestion: CaptureScopeSuggestion?
    @State private var saveErrorMessage = ""
    @State private var isShowingSaveError = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(preferredScopeID: UUID?, initialMode: CaptureComposerMode) {
        self.preferredScopeID = preferredScopeID
        self.initialMode = initialMode
        _elapsedSeconds = State(initialValue: 0)
        _isRecording = State(initialValue: initialMode == .audio)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ScopeTheme.spacingLarge) {
                    header

                    switch initialMode {
                    case .text:
                        textComposer
                    case .audio:
                        audioComposer
                    }
                }
                .padding(.horizontal, ScopeTheme.spacingLarge)
                .padding(.vertical, ScopeTheme.spacingXLarge)
            }
            .background {
                ScopeBackground().ignoresSafeArea()
            }
            .safeAreaInset(edge: .bottom) {
                footerPanel
                    .padding(.horizontal, ScopeTheme.spacingLarge)
                    .padding(.top, 10)
                .padding(.bottom, 6)
                .background(.clear)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold, design: .default))
                            .foregroundStyle(ScopeTheme.accentDeep)
                            .frame(width: 36, height: 36)
                            .background(
                                ScopeTheme.surface.opacity(0.96),
                                in: Circle()
                            )
                            .shadow(color: ScopeTheme.shadow.opacity(0.16), radius: 8, x: 0, y: 3)
                    }
                    .accessibilityLabel("Close")
                }
            }
            .confirmationDialog("Scope", isPresented: $isShowingScopePicker) {
                if preferredScopeID == nil {
                    Button("Auto-scope") {
                        selectedScopeID = nil
                        assignmentSource = .autoSuggested
                        refreshSuggestedScope()
                    }
                }

                ForEach(appModel.availableScopeChoices()) { scope in
                    Button(scope.title) {
                        selectedScopeID = scope.id
                        assignmentSource = .userSelected
                    }
                }
            }
            .onReceive(timer) { _ in
                guard initialMode == .audio, isRecording else { return }
                elapsedSeconds += 1
            }
            .onChange(of: noteText) { _, _ in
                refreshSuggestedScope()
            }
            .onChange(of: includesPhoto) { _, _ in
                refreshSuggestedScope()
            }
            .onChange(of: includesVideo) { _, _ in
                refreshSuggestedScope()
            }
            .task {
                guard !didBootstrap else { return }
                didBootstrap = true
                refreshSuggestedScope()
            }
            .alert("Can't save capture", isPresented: $isShowingSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveErrorMessage)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(initialMode == .audio ? "Recording" : "Capture")
                .font(ScopeTheme.displayFont)
                .foregroundStyle(ScopeTheme.ink)

            Text(initialMode == .audio ? "Recording starts right away." : "Write first, add image or video if needed.")
                .font(ScopeTheme.bodyFont)
                .foregroundStyle(ScopeTheme.mutedInk)
        }
    }

    private var textComposer: some View {
        VStack(alignment: .leading, spacing: ScopeTheme.spacingLarge) {
            VStack(alignment: .leading, spacing: ScopeTheme.spacingSmall) {
                Text("Text")
                    .font(ScopeTheme.captionFont.weight(.medium))
                    .foregroundStyle(ScopeTheme.mutedInk)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: ScopeTheme.radiusCard, style: .continuous)
                        .fill(ScopeTheme.surface)

                    if noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Leave yourself the clearest possible next step.")
                            .font(ScopeTheme.bodyFont)
                            .foregroundStyle(ScopeTheme.mutedInk.opacity(0.78))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 18)
                    }

                    TextEditor(text: $noteText)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .frame(minHeight: 190)
                        .background(Color.clear)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: ScopeTheme.radiusCard, style: .continuous)
                        .stroke(ScopeTheme.line, lineWidth: 1)
                }
            }

            VStack(alignment: .leading, spacing: ScopeTheme.spacingSmall) {
                Text("Add")
                    .font(ScopeTheme.captionFont.weight(.medium))
                    .foregroundStyle(ScopeTheme.mutedInk)

                HStack(spacing: ScopeTheme.spacingMedium) {
                    attachmentButton(
                        title: "Image",
                        systemImage: "photo",
                        isSelected: includesPhoto
                    ) {
                        includesPhoto.toggle()
                    }

                    attachmentButton(
                        title: "Video",
                        systemImage: "video",
                        isSelected: includesVideo
                    ) {
                        includesVideo.toggle()
                    }
                }

                if includesPhoto || includesVideo {
                    Text(attachmentSummary)
                        .font(ScopeTheme.captionFont)
                        .foregroundStyle(ScopeTheme.mutedInk)
                }
            }
        }
    }

    private var audioComposer: some View {
        VStack(alignment: .leading, spacing: ScopeTheme.spacingLarge) {
            card {
                VStack(alignment: .leading, spacing: ScopeTheme.spacingLarge) {
                    HStack {
                        Text(isRecording ? "Recording now" : "Paused")
                            .font(ScopeTheme.sectionTitleFont)
                            .foregroundStyle(ScopeTheme.ink)

                        Spacer()

                        Text(ScopeFormatters.duration.string(from: elapsedSeconds) ?? "0:00")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(ScopeTheme.accentDeep)
                    }

                    RoundedRectangle(cornerRadius: ScopeTheme.radiusCard)
                        .fill(ScopeTheme.canvas)
                        .frame(height: 132)
                        .overlay {
                            WaveformView()
                                .stroke(ScopeTheme.accent, lineWidth: 2)
                                .padding(.horizontal, ScopeTheme.spacingLarge)
                        }

                    Button(isRecording ? "Pause" : "Resume") {
                        isRecording.toggle()
                    }
                    .buttonStyle(ScopeSecondaryButtonStyle())
                }
            }

            Text("We’ll keep the original and pull the useful parts into the scope.")
                .font(ScopeTheme.bodyFont)
                .foregroundStyle(ScopeTheme.ink)
        }
    }

    private var footerActions: some View {
        HStack(spacing: ScopeTheme.spacingMedium) {
            Button(initialMode == .audio ? "Discard" : "Cancel") {
                dismiss()
            }
            .buttonStyle(ScopeSecondaryButtonStyle())

            Button(initialMode == .audio ? "Save recording" : "Save capture") {
                saveCapture()
            }
            .buttonStyle(ScopePrimaryButtonStyle())
            .disabled(!canSave)
        }
    }

    private var footerPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let autoScopeSuggestion,
               assignmentSource != .userSelected,
               autoScopeSuggestion.requiresManualReview {
                ScopeInlineNotice(
                    title: "Needs scope",
                    body: autoScopeSuggestion.reason,
                    primaryActionTitle: "Choose",
                    secondaryActionTitle: nil,
                    onPrimaryAction: { isShowingScopePicker = true },
                    onSecondaryAction: nil
                )
            }

            HStack(alignment: .center, spacing: 12) {
                Text("Scope")
                    .font(ScopeTheme.captionFont.weight(.medium))
                    .foregroundStyle(ScopeTheme.mutedInk)

                scopeHandoffChip

                Spacer(minLength: 0)
            }

            footerActions
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            ScopeTheme.surface.opacity(0.94),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .shadow(color: ScopeTheme.shadow.opacity(0.28), radius: 14, x: 0, y: 6)
    }

    private var scopeHandoffChip: some View {
        Button {
            isShowingScopePicker = true
        } label: {
            HStack(spacing: 8) {
                Text(scopeChipTitle)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold, design: .default))
            }
            .font(.system(size: 11, weight: .semibold, design: .default))
            .foregroundStyle(scopeChipTextColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                scopeChipFill,
                in: Capsule(style: .continuous)
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(scopeChipStroke, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Scope")
    }

    private func attachmentButton(title: String, systemImage: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: ScopeTheme.spacingSmall) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.system(.footnote, design: .default, weight: .semibold))
            .foregroundStyle(isSelected ? ScopeTheme.accentDeep : ScopeTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                (isSelected ? ScopeTheme.actionSurface : ScopeTheme.surface),
                in: RoundedRectangle(cornerRadius: ScopeTheme.radiusCard, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: ScopeTheme.radiusCard, style: .continuous)
                    .stroke(isSelected ? ScopeTheme.lineStrong : ScopeTheme.line, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func saveCapture() {
        refreshSuggestedScope()

        switch initialMode {
        case .audio:
            let result = appModel.saveQuickRecording(
                duration: max(elapsedSeconds, 1),
                scopeID: selectedScopeID,
                assignmentSource: assignmentSource,
                suggestion: assignmentSource == .userSelected ? nil : autoScopeSuggestion
            )
            handleSaveResult(result)
        case .text:
            let result = appModel.saveCaptureBundle(
                scopeID: selectedScopeID,
                assignmentSource: assignmentSource,
                noteText: noteText,
                includesPhoto: includesPhoto,
                includesVideo: includesVideo,
                suggestion: assignmentSource == .userSelected ? nil : autoScopeSuggestion
            )
            handleSaveResult(result)
        }
    }

    private var canSave: Bool {
        switch initialMode {
        case .audio:
            return elapsedSeconds > 0
        case .text:
            return !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || includesPhoto || includesVideo
        }
    }

    private var selectedScopeLabel: String {
        guard let selectedScopeID, let scope = appModel.scope(for: selectedScopeID) else {
            return "Choose a scope"
        }
        return scope.title
    }

    private var scopeChipTitle: String {
        if let autoScopeSuggestion,
           assignmentSource != .userSelected,
           autoScopeSuggestion.requiresManualReview {
            return "Choose scope"
        }

        switch assignmentSource {
        case .autoSuggested, .autoAssigned:
            return "Auto-scope"
        case .inScope, .userSelected:
            return "Scope: \(selectedScopeLabel)"
        }
    }

    private var scopeChipFill: Color {
        if let autoScopeSuggestion,
           assignmentSource != .userSelected,
           autoScopeSuggestion.requiresManualReview {
            return ScopeTheme.surface
        }

        return switch assignmentSource {
        case .autoSuggested, .autoAssigned:
            ScopeTheme.actionSurface
        case .inScope, .userSelected:
            ScopeTheme.surface
        }
    }

    private var scopeChipTextColor: Color {
        if let autoScopeSuggestion,
           assignmentSource != .userSelected,
           autoScopeSuggestion.requiresManualReview {
            return ScopeTheme.ink
        }

        return switch assignmentSource {
        case .autoSuggested, .autoAssigned:
            ScopeTheme.accentDeep
        case .inScope, .userSelected:
            ScopeTheme.ink
        }
    }

    private var scopeChipStroke: Color {
        if let autoScopeSuggestion,
           assignmentSource != .userSelected,
           autoScopeSuggestion.requiresManualReview {
            return ScopeTheme.lineStrong
        }

        return switch assignmentSource {
        case .autoSuggested, .autoAssigned:
            ScopeTheme.lineStrong
        case .inScope, .userSelected:
            ScopeTheme.line
        }
    }

    private var attachmentSummary: String {
        switch (includesPhoto, includesVideo) {
        case (true, true):
            "Image and video will be attached."
        case (true, false):
            "Image will be attached."
        case (false, true):
            "Video will be attached."
        default:
            ""
        }
    }

    private func refreshSuggestedScope() {
        guard assignmentSource != .userSelected else { return }

        let suggestion = appModel.suggestedDestination(
            preferredScopeID: preferredScopeID,
            noteText: noteText,
            includesPhoto: includesPhoto,
            includesVideo: includesVideo
        )

        autoScopeSuggestion = suggestion
        assignmentSource = suggestion.assignmentSource

        if suggestion.requiresManualReview {
            selectedScopeID = nil
        } else {
            selectedScopeID = suggestion.scopeID
        }
    }

    private func handleSaveResult(_ result: CapturePersistResult) {
        switch result {
        case .saved:
            dismiss()
        case .requiresManualScope:
            if appModel.activeScopes.isEmpty {
                saveErrorMessage = "Create a scope first to save this capture."
                isShowingSaveError = true
            } else {
                isShowingScopePicker = true
            }
        }
    }
}

struct CaptureReviewView: View {
    let preferredScopeID: UUID?

    var body: some View {
        CaptureComposerView(preferredScopeID: preferredScopeID, initialMode: .text)
    }
}
