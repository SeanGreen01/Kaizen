import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email: String
    @State private var isSending = false
    @State private var submittedEmail: String?
    @State private var errorMessage: String?

    init(email: String = "") {
        _email = State(initialValue: email)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(submittedEmail == nil ? "Reset your password" : "Check your email")
                        .font(.title.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                    if let submittedEmail {
                        Text("If an account exists for \(submittedEmail), you’ll receive an email with a link to reset your password. Check your spam folder too.")
                            .foregroundStyle(KaizenTheme.muted)
                        Text("After setting your new password, return to Kaizen and sign in.")
                            .foregroundStyle(KaizenTheme.muted)
                        Button("Back to sign in") { dismiss() }
                            .buttonStyle(PrimaryButtonStyle())
                        Button("Use a different email") {
                            self.submittedEmail = nil
                            errorMessage = nil
                        }
                    } else {
                        Text("Enter your account email and we’ll send you a password reset link.")
                            .foregroundStyle(KaizenTheme.muted)
                        InputView(text: $email, title: "Email address", plcaeholder: "name@example.com")
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .disabled(isSending)
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.callout).foregroundStyle(.red)
                                .accessibilityLabel("Error: \(errorMessage)")
                        }
                        Button {
                            Task { await sendResetEmail() }
                        } label: {
                            HStack {
                                Text(isSending ? "Sending…" : "Send reset link")
                                Spacer()
                                if isSending { ProgressView() }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isSending || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(28).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }
            .background(KaizenTheme.background)
            .navigationTitle("Password reset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.disabled(isSending)
                }
            }
            .interactiveDismissDisabled(isSending)
        }
        .tint(KaizenTheme.accent).preferredColorScheme(.dark)
    }

    @MainActor private func sendResetEmail() async {
        guard !isSending else { return }
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanEmail.isEmpty else {
            errorMessage = "Please enter your email address."
            return
        }
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        do {
            try await AuthService().sendPasswordReset(email: cleanEmail)
            submittedEmail = cleanEmail
        } catch {
            switch AuthErrorCode(rawValue: (error as NSError).code) {
            case .userNotFound:
                // Keep the same response whether or not this address has an account.
                submittedEmail = cleanEmail
            case .invalidEmail:
                errorMessage = "Please enter a valid email address."
            case .networkError:
                errorMessage = "Unable to connect. Check your internet connection and try again."
            case .tooManyRequests:
                errorMessage = "Too many requests. Please wait a few minutes before trying again."
            default:
                errorMessage = "Unable to send a reset email right now. Please try again later."
            }
        }
    }
}
