//
//  FocusLockView.swift
//  Wellness App
//
//  Set up and view a focus lock. Pick distracting apps and sites, choose how
//  many hours to lock them, and commit. Once locked, there is no way here to
//  shorten or cancel it until the timer runs out.
//

import SwiftUI

#if os(iOS)
import FamilyControls
#endif

struct FocusLockView: View {
    @Environment(FocusManager.self) private var focus
    @State private var hours = 2
    @State private var showPicker = false

    var body: some View {
        Group {
            if !focus.isSupported {
                unsupported
            } else if focus.isLocked {
                lockedView
            } else {
                setupView
            }
        }
        .navigationTitle("Focus Lock")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focus.refresh() }
    }

    // MARK: - Setup

    private var setupView: some View {
        Form {
            Section {
                Text("Block distracting apps and sites for a set number of hours. Once you commit, you cannot shorten or cancel the lock until it ends. Choose a length you can honor.")
                    .foregroundStyle(.secondary)
            }

            Section {
                NavigationLink {
                    ProductiveFeedView()
                } label: {
                    Label("Try the productive feed", systemImage: "brain.head.profile")
                }
            } footer: {
                Text("Craving a scroll? Swap it for a reel of quick lessons, topics, and free books.")
            }

            if !focus.isAuthorized {
                Section {
                    Button {
                        Task { await focus.requestAuthorization() }
                    } label: {
                        Label("Allow Screen Time access", systemImage: "hand.raised.fill")
                    }
                } footer: {
                    Text("Plato Wellness needs Screen Time permission to shield the apps you choose. It never sees which specific apps they are.")
                }
            }

            Section("What to block") {
                Button {
                    showPicker = true
                } label: {
                    HStack {
                        Label("Choose apps and sites", systemImage: "apps.iphone")
                        Spacer()
                        Text(focus.selectionCount == 0 ? "None" : "\(focus.selectionCount) selected")
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!focus.isAuthorized)
            }

            Section("For how long") {
                Stepper(value: $hours, in: 1...24) {
                    Text(hours == 1 ? "1 hour" : "\(hours) hours")
                }
            }

            Section {
                Button {
                    focus.startLock(hours: hours)
                    Haptics.success()
                } label: {
                    Label("Start focus lock", systemImage: "lock.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.restore)
                .disabled(!focus.isAuthorized || focus.selectionCount == 0)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } footer: {
                Text("You will not be able to change or remove the block until the \(hours) hour lock finishes.")
            }
        }
        .modifier(FocusPickerModifier(isPresented: $showPicker, focus: focus))
    }

    // MARK: - Locked

    private var lockedView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.restore)
                .accessibilityHidden(true)
            Text("Focus lock is on")
                .font(.title2.bold())
            Text(focus.remainingText)
                .font(.title3)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Text("\(focus.selectionCount) apps and sites are blocked. Stay with it. The lock lifts on its own when the time is up.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    // MARK: - Unsupported

    private var unsupported: some View {
        ContentUnavailableView {
            Label("Not available here", systemImage: "iphone.slash")
        } description: {
            Text("Focus Lock uses Apple Screen Time, which only works on a real iPhone or iPad, not the simulator.")
        }
    }
}

/// The Family Activity picker only exists when Family Controls is available, so
/// the modifier is isolated here behind the availability guard.
private struct FocusPickerModifier: ViewModifier {
    @Binding var isPresented: Bool
    var focus: FocusManager

    func body(content: Content) -> some View {
        #if os(iOS)
        let bindable = Bindable(focus)
        return content.familyActivityPicker(isPresented: $isPresented, selection: bindable.selection)
        #else
        return content
        #endif
    }
}
