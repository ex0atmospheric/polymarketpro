import SwiftUI

struct SettingsView: View {
    @State private var apiKeyInput: String = ""
    @State private var savedKey: String = UserDefaults.standard.string(forKey: "anthropic_api_key") ?? ""
    @State private var showSavedBanner = false

    private var maskedKey: String {
        guard savedKey.count > 8 else { return String(repeating: "•", count: savedKey.count) }
        let prefix = String(savedKey.prefix(4))
        let suffix = String(savedKey.suffix(4))
        return "\(prefix)••••••••\(suffix)"
    }

    var body: some View {
        ZStack {
            Color(hex: "#080a0f").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Label("API Configuration", systemImage: "key.fill")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Configure your Anthropic API key to enable the AI Analyst.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Divider()
                        .background(Color.white.opacity(0.1))

                    // Current key status
                    if !savedKey.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Current API Key")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.5))
                                .textCase(.uppercase)
                                .tracking(1)

                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(Color(hex: "#10d67d"))
                                Text(maskedKey)
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundColor(Color(hex: "#10d67d"))
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "#10d67d").opacity(0.08))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hex: "#10d67d").opacity(0.25), lineWidth: 1)
                            )
                        }
                    }

                    // Input section
                    VStack(alignment: .leading, spacing: 10) {
                        Text(savedKey.isEmpty ? "Enter API Key" : "Update API Key")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.5))
                            .textCase(.uppercase)
                            .tracking(1)

                        SecureField("sk-ant-api03-…", text: $apiKeyInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color(hex: "#0e1117"))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )

                        Text("Your API key is stored locally in UserDefaults and never sent anywhere except Anthropic's servers.")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.35))
                    }

                    // Buttons
                    HStack(spacing: 12) {
                        Button(action: saveKey) {
                            Label("Save Key", systemImage: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(
                                    apiKeyInput.isEmpty
                                    ? Color(hex: "#4f8ef7").opacity(0.4)
                                    : Color(hex: "#4f8ef7")
                                )
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .disabled(apiKeyInput.isEmpty)

                        if !savedKey.isEmpty {
                            Button(action: clearKey) {
                                Label("Clear", systemImage: "trash")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "#f04f5a"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(Color(hex: "#f04f5a").opacity(0.12))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(hex: "#f04f5a").opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Saved banner
                    if showSavedBanner {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "#10d67d"))
                            Text("API key saved successfully!")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "#10d67d"))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "#10d67d").opacity(0.08))
                        .cornerRadius(10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Divider()
                        .background(Color.white.opacity(0.1))

                    // Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to get an API key")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.5))
                            .textCase(.uppercase)
                            .tracking(1)

                        Text("1. Visit console.anthropic.com\n2. Sign in or create an account\n3. Navigate to API Keys\n4. Create a new key and paste it above")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                            .lineSpacing(4)
                    }

                    Spacer()
                }
                .padding(24)
            }
        }
        .navigationTitle("Settings")
    }

    private func saveKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        UserDefaults.standard.set(trimmed, forKey: "anthropic_api_key")
        savedKey = trimmed
        apiKeyInput = ""
        withAnimation { showSavedBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { showSavedBanner = false }
        }
    }

    private func clearKey() {
        UserDefaults.standard.removeObject(forKey: "anthropic_api_key")
        savedKey = ""
        apiKeyInput = ""
        showSavedBanner = false
    }
}
