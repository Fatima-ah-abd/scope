import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel

    @State private var isShowingCreateScope = false
    @State private var isShowingAudioCapture = false
    @State private var isShowingTextCapture = false
    @State private var isShowingSettings = false
    @State private var activeAutomationDialog: AutomationDialogRoute?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ScopeTheme.spacingXLarge) {
                header

                if appModel.activeScopes.isEmpty {
                    emptyState
                } else {
                    populatedState
                }
            }
            .padding(.horizontal, ScopeTheme.spacingLarge)
            .padding(.vertical, ScopeTheme.spacingXLarge)
        }
        .background {
            ScopeBackground().ignoresSafeArea()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                if let automationNotice = appModel.automationNotice {
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isShowingCreateScope) {
            CreateScopeView()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $isShowingTextCapture) {
            CaptureComposerView(preferredScopeID: nil, initialMode: .text)
                .presentationDetents([.large])
        }
        .fullScreenCover(isPresented: $isShowingAudioCapture) {
            CaptureComposerView(preferredScopeID: nil, initialMode: .audio)
        }
        .sheet(isPresented: $isShowingSettings) {
            HomeSettingsView()
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            EditableHomeTitleView()
        }
        .padding(.top, 10)
    }

    private var populatedState: some View {
        VStack(alignment: .leading, spacing: ScopeTheme.spacingLarge) {
            let scopes = appModel.activeScopes

            if let featuredScope = scopes.first {
                NavigationLink {
                    ScopeDetailView(scopeID: featuredScope.id)
                } label: {
                    ScopeCardView(scope: featuredScope, style: .featured)
                }
                .buttonStyle(.plain)
            }

            ForEach(Array(scopes.dropFirst())) { scope in
                NavigationLink {
                    ScopeDetailView(scopeID: scope.id)
                } label: {
                    ScopeCardView(scope: scope, style: .compact)
                }
                .buttonStyle(.plain)
            }

            footerRow
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: ScopeTheme.spacingLarge) {
            Text("Start with one part of life you come back to often.")
                .font(ScopeTheme.bodyFont)
                .foregroundStyle(ScopeTheme.ink)

            card {
                VStack(alignment: .leading, spacing: ScopeTheme.spacingSmall) {
                    Text("A scope keeps memory, notes, and context together so you can pick back up quickly.")
                        .font(ScopeTheme.bodyFont)
                        .foregroundStyle(ScopeTheme.ink)

                    Text("Use the dock below to record or add something fast.")
                        .font(ScopeTheme.captionFont)
                        .foregroundStyle(ScopeTheme.mutedInk)
                }
            }

            Button {
                isShowingCreateScope = true
            } label: {
                Text("Create your first scope")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ScopeSecondaryButtonStyle())
        }
    }

    private var footerRow: some View {
        HStack {
            Button {
            } label: {
                HStack(spacing: ScopeTheme.spacingSmall) {
                    Text("Archived")
                        .font(ScopeTheme.bodyFont.weight(.medium))
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundStyle(ScopeTheme.ink)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                isShowingSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(ScopeIconButtonStyle())
        }
        .padding(.top, ScopeTheme.spacingMedium)
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

private struct EditableHomeTitleView: View {
    @Environment(AppModel.self) private var appModel
    @FocusState private var isFieldFocused: Bool

    @State private var isEditing = false
    @State private var draftName = ""

    var body: some View {
        Group {
            if isEditing {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("", text: $draftName)
                            .textFieldStyle(.plain)
                            .font(ScopeTheme.displayFont)
                            .foregroundStyle(ScopeTheme.accentDeep)
                            .focused($isFieldFocused)
                            .submitLabel(.done)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .frame(minWidth: max(44, measuredFieldWidth), alignment: .leading)
                            .onSubmit(commitEdit)

                        Rectangle()
                            .fill(ScopeTheme.lineStrong.opacity(0.75))
                            .frame(width: max(44, measuredFieldWidth), height: 1)
                    }

                    Text("'s scopes")
                        .font(ScopeTheme.displayFont)
                        .foregroundStyle(ScopeTheme.accentDeep)
                }
                .onAppear {
                    DispatchQueue.main.async {
                        isFieldFocused = true
                    }
                }
                .onChange(of: isFieldFocused) { _, isFocused in
                    if !isFocused {
                        commitEdit()
                    }
                }
            } else {
                Button {
                    draftName = appModel.homeOwnerName
                    isEditing = true
                } label: {
                    Text(appModel.homeTitle)
                        .font(ScopeTheme.displayFont)
                        .foregroundStyle(ScopeTheme.accentDeep)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .accessibilityLabel("Edit title")
            }
        }
    }

    private var measuredFieldWidth: CGFloat {
        let source = draftName.isEmpty ? max(appModel.homeOwnerName.count, 1) : draftName.count
        return CGFloat(max(source, 1)) * 18
    }

    private func commitEdit() {
        appModel.setHomeOwnerName(draftName)
        draftName = appModel.homeOwnerName
        isEditing = false
    }
}

private struct HomeSettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var appModel = appModel

        NavigationStack {
            Form {
                Section {
                    Toggle("Show last updated on scope cards", isOn: $appModel.showScopeCardTimestamps)

                    Text("Keep card metadata hidden until you want the extra context.")
                        .font(ScopeTheme.captionFont)
                        .foregroundStyle(ScopeTheme.mutedInk)
                } header: {
                    Text("Scope cards")
                }
            }
            .scrollContentBackground(.hidden)
            .background(ScopeBackground().ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(ScopeTheme.accent)
                }
            }
        }
    }
}
