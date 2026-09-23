import SwiftUI

struct LoginView: View {
    var body: some View { AuthFormView(registering: false) }
}

struct AuthFormView: View {
    let registering: Bool
    @EnvironmentObject private var model: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var showingPasswordReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Image(systemName: "leaf.fill").font(.system(size: 40)).foregroundStyle(KaizenTheme.accent).padding(.top, 32)
                VStack(alignment: .leading, spacing: 10) {
                    Text(registering ? "Your next chapter." : "Welcome back.")
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                    Text(registering ? "Make a little space for what matters." : "Small steps start here.")
                        .foregroundStyle(KaizenTheme.muted)
                }
                VStack(spacing: 22) {
                    InputView(text: $email, title: "Email address", plcaeholder: "name@example.com")
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .keyboardType(.emailAddress).textContentType(.emailAddress)
                    InputView(text: $password, title: "Password", plcaeholder: "Enter your password", isSecureField: true)
                        .textContentType(registering ? .newPassword : .password)
                    if registering {
                        InputView(text: $confirmation, title: "Confirm password", plcaeholder: "Enter your password again", isSecureField: true)
                            .textContentType(.newPassword)
                    }
                }
                if let error = model.errorMessage {
                    Text(error).font(.callout).foregroundStyle(.red).accessibilityLabel("Error: \(error)")
                }
                if !registering {
                    Button("Forgot password?") { showingPasswordReset = true }
                }
                Button {
                    Task {
                        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                        if registering {
                            await model.register(email: cleanEmail, password: password, confirmPassword: confirmation)
                        } else {
                            await model.login(email: cleanEmail, password: password)
                        }
                    }
                } label: {
                    HStack {
                        Text(model.isLoading ? "Please wait…" : registering ? "Create account" : "Sign in")
                        Spacer()
                        if model.isLoading { ProgressView() } else { Image(systemName: "arrow.right") }
                    }
                }.buttonStyle(PrimaryButtonStyle())
                    .disabled(model.isLoading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty || (registering && confirmation.isEmpty))
                if registering {
                    Button("Already have an account? Sign in") { dismiss() }
                } else {
                    NavigationLink("New here? Create an account") { RegisterView() }
                }
            }.padding(28).frame(maxWidth: 560).frame(maxWidth: .infinity)
        }
        .background(KaizenTheme.background).tint(KaizenTheme.accent).preferredColorScheme(.dark)
        .disabled(model.isLoading)
        .onAppear { model.errorMessage = nil }
        .sheet(isPresented: $showingPasswordReset) {
            ForgotPasswordView(email: email)
        }
        .navigationTitle(registering ? "Create account" : "Sign in").navigationBarTitleDisplayMode(.inline)
    }
}
