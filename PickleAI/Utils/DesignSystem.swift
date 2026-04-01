import SwiftUI

// MARK: - Color Palette

extension Color {
    static let appGreen = Color(red: 0.18, green: 0.72, blue: 0.32)
    static let appDarkGreen = Color(red: 0.10, green: 0.52, blue: 0.22)
    static let appBackground = Color(.systemBackground)
    static let appCardBackground = Color(.secondarySystemBackground)

    // Score colors (0-100 scale)
    static let appScoreExcellent = Color.green
    static let appScoreGood = Color.yellow
    static let appScoreNeedsWork = Color.red
}

// MARK: - Score Helpers

func appScoreColor(_ score: Int) -> Color {
    switch score {
    case 80...100: return .appScoreExcellent
    case 50...79:  return .appScoreGood
    default:       return .appScoreNeedsWork
    }
}

func appScoreLabel(_ score: Int) -> String {
    switch score {
    case 80...100: return "Excellent"
    case 50...79:  return "Good"
    default:       return "Needs Work"
    }
}

// MARK: - Gradients

extension LinearGradient {
    static let appPrimary = LinearGradient(
        colors: [.appGreen, .appDarkGreen],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography

extension Font {
    static let appTitle: Font = .system(.largeTitle, design: .rounded, weight: .bold)
    static let appHeadline: Font = .system(.headline, design: .rounded, weight: .semibold)
    static let appBody: Font = .system(.body, design: .rounded)
    static let appCaption: Font = .system(.caption, design: .rounded)
}

// MARK: - Spacing

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// MARK: - Corner Radius

enum AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 20
}

// MARK: - Text Field Style

struct AppRoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
    }
}

extension TextFieldStyle where Self == AppRoundedTextFieldStyle {
    static var appRounded: AppRoundedTextFieldStyle { .init() }
}

// MARK: - Button Style

struct AppPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(Color.green.opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4))
            )
    }
}

extension ButtonStyle where Self == AppPrimaryButtonStyle {
    static var appPrimary: AppPrimaryButtonStyle { .init() }
}

// MARK: - Card Style

struct AppCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.md)
            .background(.background, in: RoundedRectangle(cornerRadius: AppCornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .strokeBorder(.quaternary, lineWidth: 1)
            )
    }
}

extension View {
    func appCardStyle() -> some View {
        modifier(AppCardStyle())
    }
}

// MARK: - Score Badge

struct AppScoreBadge: View {
    let score: Int

    private var color: Color { appScoreColor(score) }

    var body: some View {
        Text("\(score)")
            .font(.appHeadline)
            .foregroundStyle(color)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(color.opacity(0.12), in: Capsule())
    }
}
