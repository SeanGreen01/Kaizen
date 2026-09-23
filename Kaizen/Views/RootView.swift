import SwiftUI

struct RootView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    var body: some View {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-calendar") {
            DashboardView(model: TaskViewModel(service: PreviewTaskStore()))
        } else {
            authenticatedContent
        }
#else
        authenticatedContent
#endif
    }

    @ViewBuilder private var authenticatedContent: some View {
        if viewModel.currentUser != nil { DashboardView() }
        else { WelcomeView() }
    }
}
