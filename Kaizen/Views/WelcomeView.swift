import SwiftUI

struct WelcomeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer(minLength: 40)
                        ZStack {
                            Circle().stroke(KaizenTheme.accent.opacity(0.08), lineWidth: 1).frame(width: 260, height: 260)
                            Circle().stroke(KaizenTheme.accent.opacity(0.18), lineWidth: 1).frame(width: 210, height: 210)
                            Circle().fill(KaizenTheme.surface).frame(width: 150, height: 150)
                            Image(systemName: "leaf.fill").font(.system(size: 60, weight: .ultraLight))
                                .foregroundStyle(KaizenTheme.accent)
                                .rotationEffect(.degrees(appeared ? 0 : -25))
                        }
                        .scaleEffect(appeared ? 1 : 0.82)
                        .accessibilityHidden(true)
                        VStack(spacing: 16) {
                            Text("KAIZEN").font(.system(size: 16, weight: .semibold)).tracking(7).foregroundStyle(KaizenTheme.accent)
                            Text("A little better.\nEvery day.").font(.system(size: 44, weight: .semibold, design: .rounded))
                            Text("Space for your health, your work, and you.\nStart small. Make it meaningful.")
                                .font(.body).foregroundStyle(KaizenTheme.muted)
                        }.multilineTextAlignment(.center)
                        Spacer(minLength: 40)
                        NavigationLink { LoginView() } label: {
                            HStack { Text("Get started"); Spacer(); Image(systemName: "arrow.right") }
                        }.buttonStyle(PrimaryButtonStyle())
                        NavigationLink("Privacy Policy") { PrivacyPolicyView() }
                            .font(.footnote)
                            .foregroundStyle(KaizenTheme.muted)
                        Text("SMALL STEPS. LASTING CHANGE.").font(.caption2).tracking(2).foregroundStyle(KaizenTheme.muted)
                    }
                    .padding(28).frame(maxWidth: 560).frame(minHeight: geometry.size.height)
                    .frame(maxWidth: .infinity)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared || reduceMotion ? 0 : 18)
                }
            }
            .background(KaizenTheme.background)
            .onAppear {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 1.1)) { appeared = true }
            }
        }.tint(KaizenTheme.accent).preferredColorScheme(.dark)
    }
}

#Preview { WelcomeView() }
