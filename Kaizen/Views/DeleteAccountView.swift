import SwiftUI

struct DeleteAccountView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("This permanently deletes your Kaizen account. Your tasks, events, reviews, and backburner items will no longer be available.")
                        .font(.subheadline).foregroundStyle(KaizenTheme.muted)
                }
                Section("Confirm your identity") {
                    SecureField("Current password", text: $password).textContentType(.password)
                }
                Section {
                    Button("Delete my account", role: .destructive) { confirmDelete = true }
                        .disabled(password.isEmpty || authViewModel.isLoading)
                }
                if let message = authViewModel.errorMessage {
                    Text(message).font(.footnote).foregroundStyle(.red)
                }
            }
            .scrollContentBackground(.hidden).background(KaizenTheme.background)
            .navigationTitle("Delete account").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(authViewModel.isLoading)
                }
            }
            .confirmationDialog("Delete your account permanently?", isPresented: $confirmDelete) {
                Button("Delete account", role: .destructive) {
                    Task { if await authViewModel.deleteAccount(password: password) { dismiss() } }
                }
                Button("Cancel", role: .cancel) { }
            } message: { Text("This action cannot be undone.") }
            .interactiveDismissDisabled(authViewModel.isLoading)
        }
        .tint(KaizenTheme.accent).preferredColorScheme(.dark)
    }
}
