//
//  CompanionChatComponents.swift
//  Wellness App
//
//  The soft chat furniture: message bubbles, a subtle animated typing
//  indicator, and the bottom input bar. Kept small and calm on purpose, this is
//  a companion, not a support ticket (spec section 8).
//

import SwiftUI

/// A single chat bubble. User messages are tinted and trailing aligned,
/// assistant messages are soft and leading aligned with generous spacing.
struct CompanionBubble: View {
    var message: CompanionMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 44) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(isUser ? Color.white : Color.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleBackground)
                    .clipShape(bubbleShape)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !isUser { Spacer(minLength: 44) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isUser ? "You said" : "Companion said")
        .accessibilityValue(message.text)
    }

    private var bubbleShape: some Shape {
        UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(
                topLeading: 18,
                bottomLeading: isUser ? 18 : 6,
                bottomTrailing: isUser ? 6 : 18,
                topTrailing: 18
            ),
            style: .continuous
        )
    }

    @ViewBuilder private var bubbleBackground: some View {
        if isUser {
            Theme.restore
        } else {
            Color(uiColor: .secondarySystemBackground)
        }
    }
}

/// Three dots that breathe gently while the companion is composing a reply.
struct CompanionTypingIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase = 0.0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Theme.restore.opacity(0.55))
                        .frame(width: 7, height: 7)
                        .scaleEffect(scale(for: i))
                        .opacity(0.5 + 0.5 * scale(for: i))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            Spacer(minLength: 44)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            // A forever-repeating pulse is exactly the kind of motion Reduce
            // Motion should stop; leave the dots static and rely on the label.
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
        .accessibilityLabel("Companion is typing")
    }

    /// Stagger each dot so the wave reads left to right.
    private func scale(for index: Int) -> Double {
        let offset = Double(index) * 0.2
        let value = sin((phase + offset) * .pi)
        return 0.7 + 0.3 * max(0, value)
    }
}

/// Bottom input bar: a growing text field plus a send button.
struct CompanionInputBar: View {
    @Binding var text: String
    var isResponding: Bool
    var onSend: () -> Void

    @FocusState private var focused: Bool

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isResponding
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Share what is on your mind", text: $text, axis: .vertical)
                .lineLimit(1...5)
                .textInputAutocapitalization(.sentences)
                .focused($focused)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    Color(uiColor: .secondarySystemBackground),
                    in: Capsule(style: .continuous)
                )
                .onSubmit(send)

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(canSend ? Theme.restore : Color.secondary)
            }
            .disabled(!canSend)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func send() {
        guard canSend else { return }
        onSend()
    }
}

#Preview("Bubbles") {
    ScrollView {
        VStack(spacing: 16) {
            CompanionBubble(message: CompanionMessage(role: .assistant, text: "Hi Nirupam. How are you feeling today?"))
            CompanionBubble(message: CompanionMessage(role: .user, text: "A little overwhelmed, honestly."))
            CompanionTypingIndicator()
        }
        .padding()
    }
    .withSampleStores()
}
