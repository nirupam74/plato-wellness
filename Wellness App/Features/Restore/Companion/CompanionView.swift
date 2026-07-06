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

#Preview("Companion") {
    NavigationStack {
        CompanionView()
    }
    .withSampleStores()
}
