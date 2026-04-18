import SwiftUI

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

struct MenuRowButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 6

    func makeBody(configuration: Configuration) -> some View {
        MenuRowLabel(cornerRadius: cornerRadius, configuration: configuration)
    }

    private struct MenuRowLabel: View {
        let cornerRadius: CGFloat
        let configuration: ButtonStyle.Configuration
        @State private var isHovered = false

        var body: some View {
            configuration.label
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(backgroundColor)
                )
                .onHover { isHovered = $0 }
                .animation(.easeOut(duration: 0.12), value: isHovered)
        }

        private var backgroundColor: Color {
            if configuration.isPressed { return Color.themePressed }
            if isHovered { return Color.themeHover }
            return .clear
        }
    }
}

extension ButtonStyle where Self == MenuRowButtonStyle {
    static var menuRow: MenuRowButtonStyle { MenuRowButtonStyle() }
    static func menuRow(cornerRadius: CGFloat) -> MenuRowButtonStyle {
        MenuRowButtonStyle(cornerRadius: cornerRadius)
    }
}
