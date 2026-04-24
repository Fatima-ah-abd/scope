import SwiftUI

struct ScopeDetailView: View {
    @Environment(AppModel.self) private var appModel
    @State private var isShowingMemoryControls = false
    @State private var isShowingAudioCapture = false
    @State private var isShowingTextCapture = false
    @State private var isShowingReceipts = false
    @State private var activeAutomationDialog: AutomationDialogRoute?
    @State private var selectedMemory: MemoryItemRecord?

    let scopeID: UUID

    var body: some View {
        Group {
            if let scope = appModel.scope(for: scopeID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: ScopeTheme.spacingXLarge) {
                        header(for: scope)
                        whatMattersCard(for: scope)
                        recentMemorySection(for: scope)
                        receiptsSection(for: scope)
                    }
                    .padding(.horizontal, ScopeTheme.spacingLarge)
                    .padding(.vertical, ScopeTheme.spacingXLarge)
                }
                .background {
                    ScopeBackground().ignoresSafeArea()
                }
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 10) {
                        if let automationNotice = relevantAutomationNotice {
                            ScopeInlineNotice(
                                title: automationNotice.title,
                                body: automationNotice.body,
                                primaryActionTitle: automationNotice.primaryActionTitle,
                                secondaryActionTitle: automationNotice.secondaryActionTitle,
                                onPrimaryAction: {
                                    handlePrimaryAutomationAction(for: automationNotice)
                                },
                                onSecondaryAction: {
                                    appModel.dismissAutomationNotice()
                                }
                            )
                        }

                        StickyCaptureDock(
                            onRecord: { isShowingAudioCapture = true },
                            onCompose: { isShowingTextCapture = true }
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, ScopeTheme.spacingLarge)
                    .padding(.top, 6)
                }
                .confirmationDialog(
                    automationDialogTitle,
                    isPresented: Binding(
                        get: { activeAutomationDialog != nil },
                        set: { isPresented in
                            if !isPresented {
                                activeAutomationDialog = nil
                            }
                        }
                    )
                ) {
                    switch activeAutomationDialog {
                    case let .reassignCapture(reference, currentScopeID):
                        ForEach(availableReassignmentScopes(for: currentScopeID)) { scope in
                            Button(scope.title) {
                                appModel.reassignCapture(reference, to: scope.id)
                                activeAutomationDialog = nil
                            }
                        }
                    case let .reviewWaitingSignal(reference):
                        ForEach(orderedWaitingSignals(for: reference)) { signal in
                            Button(signal.text) {
                                appModel.resolveWaitingSignal(signalID: signal.id, in: reference.scopeID)
                                activeAutomationDialog = nil
                            }
                        }
                    case nil:
                        EmptyView()
                    }

                    Button("Cancel", role: .cancel) {
                        activeAutomationDialog = nil
                    }
                }
                .navigationTitle(scope.title)
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $isShowingMemoryControls) {
                    MemoryControlsView(scopeID: scopeID)
                        .presentationDetents([.large])
                    }
                .fullScreenCover(isPresented: $isShowingAudioCapture) {
                    CaptureComposerView(preferredScopeID: scopeID, initialMode: .audio)
                }
                .sheet(isPresented: $isShowingTextCapture) {
                    CaptureComposerView(preferredScopeID: scopeID, initialMode: .text)
                        .presentationDetents([.large])
                }
                .alert(item: $selectedMemory) { memory in
                    Alert(
                        title: Text("Source details"),
                        message: Text(memory.body),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .task {
                    appModel.markScopeOpened(scopeID)
                }
            } else {
                Text("This scope is unavailable.")
                    .font(ScopeTheme.bodyFont)
                    .foregroundStyle(ScopeTheme.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        ScopeBackground().ignoresSafeArea()
                    }
            }
        }
    }

    private func header(for scope: ScopeRecord) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: ScopeTheme.spacingSmall) {
                Text(scope.title)
                    .font(ScopeTheme.displayFont)
                    .foregroundStyle(ScopeTheme.ink)

                Text(scope.memoryMode.rawValue)
                    .font(ScopeTheme.captionFont.weight(.medium))
                    .foregroundStyle(ScopeTheme.mutedInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ScopeTheme.elevatedSurface, in: Capsule())
            }

            Spacer()

            Image(systemName: "ellipsis")
                .font(.title3)
                .foregroundStyle(ScopeTheme.mutedInk)
                .padding(10)
                .background(ScopeTheme.surface, in: RoundedRectangle(cornerRadius: ScopeTheme.radiusChip))
                .overlay {
                    RoundedRectangle(cornerRadius: ScopeTheme.radiusChip)
                        .stroke(ScopeTheme.line, lineWidth: 1)
                }
        }
    }

    private func whatMattersCard(for scope: ScopeRecord) -> some View {
        card {
            VStack(alignment: .leading, spacing: ScopeTheme.spacingMedium) {
                Text("What matters here")
                    .font(ScopeTheme.sectionTitleFont)
                    .foregroundStyle(ScopeTheme.ink)

                Text(scope.summary)
                    .font(ScopeTheme.bodyFont)
                    .foregroundStyle(ScopeTheme.ink)

                HStack(spacing: ScopeTheme.spacingSmall) {
                    ForEach(scope.categoryPreview, id: \.self) { category in
                        CategoryChipView(title: category)
                    }
                }

                Text("Updated \(scope.lastOpenedAt.map { ScopeFormatters.relative.localizedString(for: $0, relativeTo: .now) } ?? "recently")")
                    .font(ScopeTheme.captionFont)
                    .foregroundStyle(ScopeTheme.mutedInk)
            }
        }
    }

    private func recentMemorySection(for scope: ScopeRecord) -> some View {
        VStack(alignment: .leading, spacing: ScopeTheme.spacingMedium) {
            HStack {
                Text("Recent memory")
                    .font(ScopeTheme.sectionTitleFont)
                    .foregroundStyle(ScopeTheme.ink)

                Spacer()

                Button("Adjust") {
                    isShowingMemoryControls = true
                }
                .font(ScopeTheme.captionFont.weight(.medium))
                .foregroundStyle(ScopeTheme.accent)
            }

            if scope.recentMemory.isEmpty {
                card {
                    Text("Start with a note, photo, or voice memo. We’ll help organize what matters.")
                        .font(ScopeTheme.bodyFont)
                        .foregroundStyle(ScopeTheme.ink)
                }
            } else {
                ForEach(scope.recentMemory.prefix(2)) { memory in
                    card {
                        VStack(alignment: .leading, spacing: ScopeTheme.spacingSmall) {
                            Text(memory.title)
                                .font(ScopeTheme.sectionTitleFont)
                                .foregroundStyle(ScopeTheme.ink)

                            Text("\(memory.reviewState.rawValue.capitalized) • \(memory.primaryCategory)")
                                .font(ScopeTheme.captionFont)
                                .foregroundStyle(ScopeTheme.moss)
                        }
                    }
                }
            }
        }
    }

    private func receiptsSection(for scope: ScopeRecord) -> some View {
        let visibleReceipts = scope.recentMemory.filter { $0.reviewState != .excluded }

        return VStack(alignment: .leading, spacing: ScopeTheme.spacingMedium) {
            Button {
                isShowingReceipts.toggle()
            } label: {
                HStack {
                    Text("Used in this reply: \(min(visibleReceipts.count, 3)) items")
                        .font(ScopeTheme.bodyFont.weight(.medium))
                        .foregroundStyle(ScopeTheme.ink)

                    Spacer()

                    Image(systemName: isShowingReceipts ? "chevron.up" : "chevron.right")
                        .foregroundStyle(ScopeTheme.mutedInk)
                }
            }
            .buttonStyle(.plain)

            if isShowingReceipts {
                ForEach(visibleReceipts.prefix(2)) { memory in
                    card {
                        VStack(alignment: .leading, spacing: ScopeTheme.spacingSmall) {
                            Text(memory.title)
                                .font(ScopeTheme.sectionTitleFont)
                                .foregroundStyle(ScopeTheme.ink)

                            Text("category: \(memory.primaryCategory)")
                                .font(ScopeTheme.captionFont)
                                .foregroundStyle(ScopeTheme.mutedInk)

                            Text("from this scope • \(memory.sourceKind.rawValue)")
                                .font(ScopeTheme.captionFont)
                                .foregroundStyle(ScopeTheme.mutedInk)

                            HStack {
                                Button(memory.reviewState == .excluded ? "Restore" : "Exclude") {
                                    appModel.toggleMemoryExclusion(scopeID: scopeID, memoryID: memory.id)
                                }
                                .buttonStyle(ScopeInlineActionStyle())

                                Spacer()

                                Button("Source") {
                                    selectedMemory = memory
                                }
                                .buttonStyle(ScopeInlineActionStyle())
                            }
                        }
                    }
                }
            }
        }
    }

    private var relevantAutomationNotice: AutomationNoticeRecord? {
        guard let automationNotice = appModel.automationNotice,
              automationNotice.scopeID == scopeID else {
            return nil
        }

        return automationNotice
    }

    private func availableReassignmentScopes(for currentScopeID: UUID?) -> [ScopeRecord] {
        appModel.availableScopeChoices().filter { $0.id != currentScopeID }
    }

    private func orderedWaitingSignals(for reference: WaitingSignalReviewReference) -> [ScopeCardSignalRecord] {
        let signals = appModel.waitingSignals(for: reference.scopeID)
        return signals.sorted { lhs, rhs in
            if lhs.id == reference.suggestedSignalID { return true }
            if rhs.id == reference.suggestedSignalID { return false }
            return lhs.text.localizedCaseInsensitiveCompare(rhs.text) == .orderedAscending
        }
    }

    private var automationDialogTitle: String {
        switch activeAutomationDialog {
        case .reassignCapture:
            return "Change scope"
        case .reviewWaitingSignal:
            return "Resolve follow-up"
        case nil:
            return ""
        }
    }

    private func handlePrimaryAutomationAction(for automationNotice: AutomationNoticeRecord) {
        guard let action = automationNotice.action else { return }

        switch action {
        case let .reassignCapture(reference):
            activeAutomationDialog = .reassignCapture(
                reference: reference,
                currentScopeID: automationNotice.scopeID
            )
        case let .restoreWaitingSignal(reference):
            appModel.restoreWaitingSignal(reference)
        case let .reviewWaitingSignal(reference):
            activeAutomationDialog = .reviewWaitingSignal(reference: reference)
        }
    }
}
