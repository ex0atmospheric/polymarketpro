import SwiftUI

struct AIAnalystView: View {
    @StateObject private var claude = ClaudeService()
    @State private var inputText = ""
    @State private var scrollProxy: ScrollViewProxy? = nil

    var body: some View {
        ZStack {
            Color(hex: "#080a0f").ignoresSafeArea()

            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            // Welcome message
                            WelcomeBubble()
                                .id("welcome")

                            ForEach(claude.messages) { msg in
                                MessageBubble(message: msg)
                                    .id(msg.id)
                            }

                            if claude.isThinking {
                                ThinkingBubble()
                                    .id("thinking")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: claude.messages.count) { _ in
                        if let last = claude.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                    .onChange(of: claude.isThinking) { thinking in
                        if thinking {
                            withAnimation { proxy.scrollTo("thinking", anchor: .bottom) }
                        }
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                // Input bar
                HStack(spacing: 10) {
                    TextField("Ask about markets, probabilities, strategies…", text: $inputText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#0e1117"))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .onSubmit { sendMessage() }

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(inputText.isEmpty || claude.isThinking
                                             ? Color.white.opacity(0.3)
                                             : Color(hex: "#4f8ef7"))
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.isEmpty || claude.isThinking)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(hex: "#080a0f"))
            }
        }
        .navigationTitle("AI Analyst")
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !claude.isThinking else { return }
        inputText = ""
        Task { await claude.send(text) }
    }
}

struct WelcomeBubble: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundColor(Color(hex: "#4f8ef7"))
                .frame(width: 36, height: 36)
                .background(Color(hex: "#4f8ef7").opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text("AI Analyst")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#4f8ef7"))
                Text("Hello! I'm your quantitative analyst for prediction markets. Ask me about:\n• Market probabilities and implied odds\n• Trading strategies and risk management\n• Historical trends and pattern analysis\n• Specific Polymarket markets")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color(hex: "#0e1117"))
            .cornerRadius(12)

            Spacer()
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(isUser ? "You" : "AI Analyst")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(isUser ? Color(hex: "#4f8ef7") : Color.white.opacity(0.5))

                Text(message.content)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(isUser ? Color(hex: "#4f8ef7").opacity(0.25) : Color(hex: "#0e1117"))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isUser ? Color(hex: "#4f8ef7").opacity(0.4) : Color.white.opacity(0.06),
                                lineWidth: 1
                            )
                    )
                    .fixedSize(horizontal: false, vertical: true)

                Text(formattedTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.35))
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}

struct ThinkingBubble: View {
    @State private var dotOpacity: [Double] = [0.3, 0.3, 0.3]
    @State private var animating = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundColor(Color(hex: "#4f8ef7"))
                .frame(width: 36, height: 36)
                .background(Color(hex: "#4f8ef7").opacity(0.15))
                .clipShape(Circle())

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color(hex: "#4f8ef7"))
                        .frame(width: 8, height: 8)
                        .opacity(dotOpacity[i])
                }
            }
            .padding(14)
            .background(Color(hex: "#0e1117"))
            .cornerRadius(12)

            Spacer()
        }
        .onAppear {
            animateDots()
        }
    }

    private func animateDots() {
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    dotOpacity[i] = 1.0
                }
            }
        }
    }
}
