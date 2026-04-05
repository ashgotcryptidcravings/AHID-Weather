import SwiftUI

struct AIChatView: View {
    @ObservedObject var vm: WeatherViewModel
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 14) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(vm.chatMessages) { msg in
                            chatBubble(msg)
                                .id(msg.id)
                        }

                        if vm.isChatLoading {
                            typingIndicator
                                .id("typing")
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(maxHeight: 280)
                .onChange(of: vm.chatMessages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(vm.chatMessages.last?.id, anchor: .bottom)
                    }
                }
                .onChange(of: vm.isChatLoading) { loading in
                    if loading {
                        withAnimation {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    }
                }
            }

            // Input row
            HStack(spacing: 8) {
                TextField("What should I wear today?", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .tracking(0.5)
                    .foregroundColor(ThemeColors.white)
                    .padding(10)
                    .background(ThemeColors.void3)
                    .overlay(
                        Rectangle()
                            .stroke(
                                isInputFocused ? ThemeColors.accentBright : ThemeColors.accent.opacity(0.25),
                                lineWidth: 1
                            )
                    )
                    .focused($isInputFocused)
                    .onSubmit { sendMessage() }

                Button(action: sendMessage) {
                    Text("TRANSMIT")
                        .font(.system(size: 9, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(ThemeColors.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(ThemeColors.accent)
                        .overlay(Rectangle().stroke(ThemeColors.accentBright, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(vm.isChatLoading || inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(vm.isChatLoading ? 0.4 : 1)
            }
        }
        .panelStyle()
    }

    private func chatBubble(_ msg: ChatMessage) -> some View {
        HStack {
            if msg.role == .user { Spacer(minLength: 40) }

            VStack(alignment: msg.role == .user ? .trailing : .leading, spacing: 4) {
                Text(msg.role == .user ? "YOU" : "AI")
                    .font(.system(size: 8, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(
                        msg.role == .user ? ThemeColors.white.opacity(0.3) : ThemeColors.accentBright
                    )

                Text(msg.text)
                    .font(.system(size: 11, design: .monospaced))
                    .tracking(0.5)
                    .lineSpacing(4)
                    .foregroundColor(
                        msg.role == .user ? ThemeColors.white : ThemeColors.whiteDim
                    )
            }
            .padding(10)
            .background(
                msg.role == .user ? ThemeColors.accentDim : ThemeColors.void3
            )
            .overlay(
                Rectangle()
                    .fill(msg.role == .user ? ThemeColors.accentBright : ThemeColors.white.opacity(0.15))
                    .frame(width: 2),
                alignment: msg.role == .user ? .trailing : .leading
            )

            if msg.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(ThemeColors.accentBright)
                        .frame(width: 4, height: 4)
                        .opacity(0.3)
                }
            }
            .padding(10)
            Spacer()
        }
    }

    private func sendMessage() {
        let text = inputText
        inputText = ""
        Task { await vm.sendChatMessage(text) }
    }
}
