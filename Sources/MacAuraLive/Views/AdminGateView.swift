import SwiftUI
import CryptoKit

public struct AdminGateView<Content: View>: View {
    @ObservedObject var settings = AppSettings.shared
    let featureTitle: String
    let content: Content

    @State private var passcode: String = ""
    @State private var errorMessage: String? = nil

    // SHA-256 hash of the admin passcode — plaintext never stored in source
    private var passcodeHash: String { "85edab3137ff749a2884e80f6faa513c709d28b45f9cecb7da0aff56ce071959" }

    public init(featureTitle: String, @ViewBuilder content: () -> Content) {
        self.featureTitle = featureTitle
        self.content = content()
    }

    public var body: some View {
        if settings.isAdminUnlocked {
            content
        } else {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 38))
                            .foregroundColor(.purple)
                    }

                    Text("\(featureTitle) (Coming Soon)")
                        .font(.title2)
                        .bold()

                    Text("This feature is currently locked under early access preview.\nEnter the Admin Passcode to unlock.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 440)
                }

                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        SecureField("Enter Admin Passcode...", text: $passcode)
                            .macaTextFieldStyle()
                            .frame(width: 260)
                            .onSubmit { unlock() }

                        Button("Unlock") { unlock() }
                            .macaButtonStyle(.primary)
                    }

                    if let err = errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                            .bold()
                    }
                }
                .padding(24)
                .macaCardStyle(cornerRadius: 14)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func unlock() {
        let input = passcode.trimmingCharacters(in: .whitespacesAndNewlines)
        let inputHash = SHA256.hash(data: Data(input.utf8))
            .compactMap { String(format: "%02x", $0) }.joined()
        if inputHash == passcodeHash {
            settings.isAdminUnlocked = true
            errorMessage = nil
        } else {
            errorMessage = "Invalid Admin Passcode. Access Denied."
        }
    }
}
