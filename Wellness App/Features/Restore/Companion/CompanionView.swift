//
//  CompanionView.swift
//  Wellness App
//
//  The AI companion chat (spec section 8). A calm, human conversation surface
//  with an independent crisis safety layer pinned above the thread, a one-time
//  disclaimer and consent gate, always-available support resources, and a
//  history control. Pushed from the Restore tab via `CompanionView()`, so it
//  composes onto the surrounding NavigationStack rather than adding its own.
//

import SwiftUI

struct CompanionView: View {
    init() {}

    @Environment(CompanionStore.self) private var companion
    @Environment(UserStore.self) private var user

    @AppStorage("companionDisclaimerShown") private var disclaimerShown = false

    @State private var draft = ""
    @State private var showDisclaimer = false
    @State private var showResources = false
    @State private var showClearConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            if companion.isCrisisActive {
                CompanionCrisisCard(resources: companion.crisisResources)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            messageList

            CompanionInputBar(text: $draft, isResponding: companion.isResponding) {
                sendDraft()
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Companion")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Theme.restore)
        .animation(.snappy, value: companion.isCrisisActive)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showResources) {
            CompanionResourcesView(resources: companion.crisisResources)
        }
        .sheet(isPresented: $showDisclaimer) {
            CompanionDisclaimerView(
                isFirstRun: !disclaimerShown,
                resources: companion.crisisResources
            )
            .onDisappear { disclaimerShown = true }
        }
        .alert("Delete all companion history?", isPresented: $showClearConfirm) {
            Button("Delete", role: .destructive) { companion.clearHistory() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently removes every message in this conversation. This cannot be undone.")
        }
        .onAppear {
            if !disclaimerShown { showDisclaimer = true }
        }
    }

    // MARK: - Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if companion.messages.isEmpty && !companion.isResponding {
                        CompanionWelcome(name: user.profile?.firstName) { suggestion in
                            draft = suggestion
                        }
                        .padding(.top, 24)
                    }

                    ForEach(companion.messages) { message in
                        CompanionBubble(message: message)
                            .id(message.id)
                    }

                    if companion.isResponding {
                        CompanionTypingIndicator()
                            .id(Self.typingAnchor)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(Self.bottomAnchor)
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: companion.messages.count) {
                scrollToBottom(proxy)
            }
            .onChange(of: companion.isResponding) {
                scrollToBottom(proxy)
            }
            .onAppear {
                proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showResources = true
            } label: {
                Label("Support", systemImage: "lifepreserver")
            }
            .accessibilityLabel("Get support resources")
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    showDisclaimer = true
                } label: {
                    Label("About this companion", systemImage: "info.circle")
                }

                Button(role: .destructive) {
                    showClearConfirm = true
                } label: {
                    Label("Delete all companion history", systemImage: "trash")
                }
            } label: {
                Label("More options", systemImage: "ellipsis.circle")
            }
            .accessibilityLabel("More companion options")
        }
    }

    // MARK: - Sending

    private func sendDraft() {
        let text = draft
        draft = ""
        Task { await companion.send(text) }
    }

    private static let bottomAnchor = "companion.bottom"
    private static let typingAnchor = "companion.typing"
}

// MARK: - Welcome / empty state

/// Shown before the first message so the companion opens with warmth and a few
/// gentle starting points instead of an empty scroll.
private struct CompanionWelcome: View {
    var name: String?
    var onSuggestion: (String) -> Void

    private let suggestions = [
        "I would like to sleep better",
        "I am feeling stressed today",
        "Help me plan an easy workout",
        "Give me a calming breath to try"
    ]

    private var greeting: String {
        if let name, !name.isEmpty { return "Hi \(name), I am here for you" }
        return "Hi, I am here for you"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.heart.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.restore)
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text(greeting)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text("Share whatever is on your mind, or start with one of these.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        onSuggestion(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(
                                Color(uiColor: .secondarySystemBackground),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Adds this to the message box so you can edit or send it")
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 8)
    }
}

#Preview("Companion") {
    NavigationStack {
        CompanionView()
    }
    .withSampleStores()
}
