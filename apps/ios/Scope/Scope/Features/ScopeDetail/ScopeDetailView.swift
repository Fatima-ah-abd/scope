import SwiftUI

private enum ScopeDetailSection: Hashable {
    case focus
    case memory
    case receipts
}

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
                let theme = ScopeThemeSpec.forScope(scope)

                ScrollView {
                    VStack(alignment: .leading, spacing: ScopeTheme.spacingXLarge) {
                        header(for: scope, theme: theme)

                        ForEach(orderedSections(for: theme), id: \.self) { section in
                            sectionView(section, scope: scope, theme: theme)
                        }
                    }
                    .padding(.horizontal, ScopeTheme.spacingLarge)
                    .padding(.vertical, ScopeTheme.spacingXLarge)
                }
                .background {
                    ScopePageBackground(theme: theme).ignoresSafeArea()
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
                .task(id: scopeID) {
                    await appModel.prepareScopeDetail(scopeID)
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

    private func orderedSections(for theme: ScopeThemeSpec) -> [ScopeDetailSection] {
        switch theme.sectionLayout {
        case .focusFirst:
            [.focus, .memory, .receipts]
        case .memoryFirst:
            [.memory, .focus, .receipts]
        }
    }

    @ViewBuilder
    private func sectionView(_ section: ScopeDetailSection, scope: ScopeRecord, theme: ScopeThemeSpec) -> some View {
        switch section {
        case .focus:
            whatMattersCard(for: scope, theme: theme)
        case .memory:
            recentMemorySection(for: scope, theme: theme)
        case .receipts:
            receiptsSection(for: scope, theme: theme)
        }
    }

    private func header(for scope: ScopeRecord, theme: ScopeThemeSpec) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                Text(theme.headerLabel)
                    .font(ScopeTheme.eyebrowFont)
                    .textCase(.uppercase)
                    .tracking(1.1)
                    .foregroundStyle(theme.heroMutedText)

                Spacer()

                headerAccessory(for: scope, theme: theme)
            }

            switch theme.heroStyle {
            case .editorial:
                editorialHeader(scope: scope, theme: theme)
            case .itinerary:
                itineraryHeader(scope: scope, theme: theme)
            case .ledger:
                ledgerHeader(scope: scope, theme: theme)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.heroFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(theme.heroText.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: theme.shadowColor.opacity(0.36), radius: 18, x: 0, y: 10)
    }

    @ViewBuilder
    private func headerAccessory(for scope: ScopeRecord, theme: ScopeThemeSpec) -> some View {
        if showsThemeMenu(for: scope) {
            Menu {
                if appModel.isScopeThemeProviderConfigured {
                    Button {
                        Task {
                            await appModel.regenerateThemeRecipe(for: scope.id)
                        }
                    } label: {
                        Label(scope.themeRecipe == nil ? "Generate look" : "Refresh look", systemImage: "sparkles")
                    }
                }

                if scope.themeRecipe != nil {
                    Button {
                        appModel.useDefaultTheme(for: scope.id)
                    } label: {
                        Label("Use default look", systemImage: "arrow.uturn.backward.circle")
                    }
                }
            } label: {
                headerAccessoryBadge(theme: theme)
            }
        } else {
            headerAccessoryBadge(theme: theme)
        }
    }

    private func showsThemeMenu(for scope: ScopeRecord) -> Bool {
        appModel.isScopeThemeProviderConfigured || scope.themeRecipe != nil
    }

    private func headerAccessoryBadge(theme: ScopeThemeSpec) -> some View {
        Image(systemName: "ellipsis")
            .font(.title3)
            .foregroundStyle(theme.heroMutedText)
            .padding(10)
            .background(theme.heroText.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func editorialHeader(scope: ScopeRecord, theme: ScopeThemeSpec) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(scope.title)
                        .font(.system(size: 34, weight: .black, design: .serif))
                        .foregroundStyle(theme.heroText)
                        .tracking(-0.45)

                    Text(scope.summary)
                        .font(ScopeTheme.bodyFont)
                        .foregroundStyle(theme.heroMutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                heroStamp(theme: theme)
            }

            HStack(spacing: 8) {
                modeBadge(title: scope.memoryMode.rawValue, foreground: theme.heroText, background: theme.heroText.opacity(0.14))

                ForEach(scope.categoryPreview, id: \.self) { category in
                    ScopeDetailChip(
                        title: category,
                        fill: theme.heroText.opacity(0.1),
                        textColor: theme.heroText
                    )
                }
            }
        }
    }

    private func itineraryHeader(scope: ScopeRecord, theme: ScopeThemeSpec) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(scope.title)
                        .font(.system(size: 32, weight: .black, design: .serif))
                        .foregroundStyle(theme.heroText)
                        .tracking(-0.35)

                    Text(scope.summary)
                        .font(ScopeTheme.bodyFont)
                        .foregroundStyle(theme.heroMutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                heroStamp(theme: theme)
            }

            Rectangle()
                .fill(theme.heroText.opacity(0.18))
                .frame(height: 1)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Next up")
                        .font(ScopeTheme.eyebrowFont)
                        .foregroundStyle(theme.heroMutedText)

                    Text(scope.cardSignals.first?.text ?? "Keep tightening the current plan.")
                        .font(ScopeTheme.bodyFont.weight(.medium))
                        .foregroundStyle(theme.heroText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                modeBadge(title: scope.memoryMode.rawValue, foreground: theme.heroText, background: theme.heroText.opacity(0.14))
            }

            HStack(spacing: 8) {
                ForEach(scope.categoryPreview, id: \.self) { category in
                    ScopeDetailChip(
                        title: category,
                        fill: theme.heroText.opacity(0.1),
                        textColor: theme.heroText
                    )
                }
            }
        }
    }

    private func ledgerHeader(scope: ScopeRecord, theme: ScopeThemeSpec) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(scope.title)
                    .font(.system(size: 33, weight: .black, design: .serif))
                    .foregroundStyle(theme.heroText)
                    .tracking(-0.3)

                Spacer(minLength: 0)

                modeBadge(title: scope.memoryMode.rawValue, foreground: theme.heroText, background: theme.heroText.opacity(0.14))
            }

            HStack(alignment: .top, spacing: 16) {
                heroStamp(theme: theme)

                Text(scope.summary)
                    .font(ScopeTheme.bodyFont)
                    .foregroundStyle(theme.heroMutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Rectangle()
                .fill(theme.heroText.opacity(0.18))
                .frame(height: 1)

            HStack(spacing: 8) {
                ForEach(scope.categoryPreview, id: \.self) { category in
                    ScopeDetailChip(
                        title: category,
                        fill: theme.heroText.opacity(0.1),
                        textColor: theme.heroText
                    )
                }
            }
        }
    }

    private func whatMattersCard(for scope: ScopeRecord, theme: ScopeThemeSpec) -> some View {
        ScopeSurfaceCard(theme: theme) {
            VStack(alignment: .leading, spacing: ScopeTheme.spacingMedium) {
                Text("What matters here")
                    .font(ScopeTheme.sectionTitleFont)
                    .foregroundStyle(theme.primaryText)

                Text(scope.summary)
                    .font(ScopeTheme.bodyFont)
                    .foregroundStyle(theme.primaryText)

                HStack(spacing: ScopeTheme.spacingSmall) {
                    ForEach(scope.categoryPreview, id: \.self) { category in
                        ScopeDetailChip(
                            title: category,
                            fill: theme.chipFill,
                            textColor: theme.chipText
                        )
                    }
                }
            }
        }
    }

    private func recentMemorySection(for scope: ScopeRecord, theme: ScopeThemeSpec) -> some View {
        VStack(alignment: .leading, spacing: ScopeTheme.spacingMedium) {
            HStack {
                Text("Recent memory")
                    .font(ScopeTheme.sectionTitleFont)
                    .foregroundStyle(theme.primaryText)

                Spacer()

                Button("Adjust") {
                    isShowingMemoryControls = true
                }
                .buttonStyle(.plain)
                .font(ScopeTheme.captionFont.weight(.semibold))
                .foregroundStyle(theme.accent)
            }

            if scope.recentMemory.isEmpty {
                ScopeSurfaceCard(theme: theme) {
                    Text("Start with a note, photo, or voice memo. We’ll help organize what matters.")
                        .font(ScopeTheme.bodyFont)
                        .foregroundStyle(theme.primaryText)
                }
            } else {
                ForEach(scope.recentMemory.prefix(2)) { memory in
                    ScopeSurfaceCard(theme: theme) {
                        VStack(alignment: .leading, spacing: ScopeTheme.spacingMedium) {
                            Text(memory.title)
                                .font(ScopeTheme.sectionTitleFont)
                                .foregroundStyle(theme.primaryText)

                            Text(memory.body)
                                .font(ScopeTheme.bodyFont)
                                .foregroundStyle(theme.secondaryText)
                                .lineLimit(2)

                            HStack(spacing: 8) {
                                ScopeDetailChip(
                                    title: memory.primaryCategory,
                                    fill: theme.chipFill,
                                    textColor: theme.chipText
                                )

                                if let sourceLabel = sourceLabel(for: memory.sourceKind) {
                                    ScopeDetailChip(
                                        title: sourceLabel,
                                        fill: theme.elevatedSurfaceFill,
                                        textColor: theme.secondaryText
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func receiptsSection(for scope: ScopeRecord, theme: ScopeThemeSpec) -> some View {
        let visibleReceipts = scope.recentMemory.filter { $0.reviewState != .excluded }

        return VStack(alignment: .leading, spacing: ScopeTheme.spacingMedium) {
            Button {
                isShowingReceipts.toggle()
            } label: {
                HStack {
                    Text("Used in this reply: \(min(visibleReceipts.count, 3)) items")
                        .font(ScopeTheme.bodyFont.weight(.medium))
                        .foregroundStyle(theme.primaryText)

                    Spacer()

                    Image(systemName: isShowingReceipts ? "chevron.up" : "chevron.right")
                        .foregroundStyle(theme.secondaryText)
                }
            }
            .buttonStyle(.plain)

            if isShowingReceipts {
                ForEach(visibleReceipts.prefix(2)) { memory in
                    ScopeSurfaceCard(theme: theme) {
                        VStack(alignment: .leading, spacing: ScopeTheme.spacingSmall) {
                            Text(memory.title)
                                .font(ScopeTheme.sectionTitleFont)
                                .foregroundStyle(theme.primaryText)

                            Text("category: \(memory.primaryCategory)")
                                .font(ScopeTheme.captionFont)
                                .foregroundStyle(theme.secondaryText)

                            Text("from this scope • \(receiptSourceLabel(for: memory.sourceKind))")
                                .font(ScopeTheme.captionFont)
                                .foregroundStyle(theme.secondaryText)

                            HStack {
                                Button(memory.reviewState == .excluded ? "Restore" : "Exclude") {
                                    appModel.toggleMemoryExclusion(scopeID: scopeID, memoryID: memory.id)
                                }
                                .buttonStyle(.plain)
                                .font(ScopeTheme.captionFont.weight(.semibold))
                                .foregroundStyle(theme.accent)

                                Spacer()

                                Button("Source") {
                                    selectedMemory = memory
                                }
                                .buttonStyle(.plain)
                                .font(ScopeTheme.captionFont.weight(.semibold))
                                .foregroundStyle(theme.accent)
                            }
                        }
                    }
                }
            }
        }
    }

    private func heroStamp(theme: ScopeThemeSpec) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.heroText.opacity(0.1))
                .frame(width: 62, height: 62)

            ScopeIllustrationView(motif: theme.motif, color: theme.heroText, lineWeight: 0.7)
                .frame(width: 28, height: 28)
        }
    }

    private func modeBadge(title: String, foreground: Color, background: Color) -> some View {
        Text(title)
            .font(ScopeTheme.captionFont.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(background, in: Capsule())
    }

    private func sourceLabel(for sourceKind: MemorySourceKind) -> String? {
        switch sourceKind {
        case .userAuthored:
            return nil
        case .extracted:
            return "from extraction"
        case .simulated:
            return "generated"
        }
    }

    private func receiptSourceLabel(for sourceKind: MemorySourceKind) -> String {
        switch sourceKind {
        case .userAuthored:
            return "note you added"
        case .extracted:
            return "extracted detail"
        case .simulated:
            return "generated summary"
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

private struct ScopeDetailChip: View {
    let title: String
    let fill: Color
    let textColor: Color

    var body: some View {
        Text(title)
            .font(ScopeTheme.captionFont.weight(.semibold))
            .foregroundStyle(textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(fill, in: Capsule())
    }
}
