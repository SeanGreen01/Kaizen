import SwiftUI

enum KaizenTheme {
    static let background = Color(red: 0.065, green: 0.067, blue: 0.075)
    static let surface = Color(white: 0.12)
    static let accent = Color(white: 0.92)
    static let muted = Color(white: 0.52)
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 16, weight: .medium)).frame(maxWidth: .infinity).padding(17)
            .background(KaizenTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(KaizenTheme.accent)
            .opacity(configuration.isPressed ? 0.55 : 1)
    }
}

struct CategoryTabs: View {
    @Binding var selection: TaskCategory
    var completion: ((TaskCategory) -> (completed: Int, total: Int))? = nil
    var body: some View {
        HStack(spacing: 6) {
            ForEach(TaskCategory.allCases) { category in
                Button { selection = category } label: {
                    VStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Text(category.rawValue).font(.system(size: 14, weight: .medium))
                            if let completion {
                                let score = completion(category)
                                Text(score.total == 0 ? "–" : "\(Int((Double(score.completed) / Double(score.total)) * 100))%")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(selection == category ? KaizenTheme.accent : KaizenTheme.muted)
                            }
                        }
                        Rectangle().fill(selection == category ? .white : .clear).frame(height: 1)
                    }
                    .frame(maxWidth: .infinity).padding(.top, 12)
                    .foregroundStyle(selection == category ? .white : KaizenTheme.muted)
                }
                .accessibilityAddTraits(selection == category ? .isSelected : [])
            }
        }
    }
}

struct TaskErrorModifier: ViewModifier {
    @ObservedObject var model: TaskViewModel
    func body(content: Content) -> some View {
        content.alert("Something needs attention", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) { Button("OK", role: .cancel) { model.errorMessage = nil } }
        message: { Text(model.errorMessage ?? "") }
    }
}


extension TaskCategory {
    var color: Color {
        switch self {
        case .health: return Color(red: 0.71, green: 0.53, blue: 0.92)
        case .work: return Color(red: 0.40, green: 0.63, blue: 0.95)
        case .personal: return Color(red: 0.95, green: 0.61, blue: 0.37)
        }
    }
}
