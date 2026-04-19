import SwiftUI

struct AboutView: View {
    @StateObject private var updater = Updater()

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "dev"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return short == build ? "Version \(short)" : "Version \(short) (\(build))"
    }

    private var copyrightString: String {
        let info = Bundle.main.infoDictionary
        return info?["NSHumanReadableCopyright"] as? String ?? ""
    }

    private var statusCaption: String? {
        switch updater.status {
        case .idle: return nil
        case .checking: return "Checking…"
        case .upToDate: return "You're up to date."
        case .updateAvailable: return "Update available — follow the prompt."
        case let .failed(message): return "Check failed: \(message)"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Image.brandWordmark
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 220)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.themeInk.opacity(0.06), lineWidth: 1)
                )
                .accessibilityLabel("CutBar")

            Text("Quiet meal tracking for your menu bar.")
                .font(.appSubheadline)
                .foregroundStyle(Color.themeInk.opacity(0.7))

            Text(versionString)
                .font(.appCaption)
                .foregroundStyle(Color.themeInk.opacity(0.6))
                .monospacedDigit()

            Link("View on GitHub", destination: URL(string: "https://github.com/ezzabuzaid/CutBar")!)
                .font(.appSubheadlineMedium)
                .tint(Color.themeAccent)

            VStack(spacing: 6) {
                Button("Check for Updates…") {
                    updater.checkForUpdates()
                }
                .buttonStyle(.bordered)
                .disabled(!updater.canCheckForUpdates)

                if let statusCaption {
                    Text(statusCaption)
                        .font(.appCaption2)
                        .foregroundStyle(Color.themeInk.opacity(0.5))
                }
            }

            if !copyrightString.isEmpty {
                Text(copyrightString)
                    .font(.appCaption2)
                    .foregroundStyle(Color.themeInk.opacity(0.5))
            }
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 32)
        .frame(minWidth: 360, minHeight: 360)
        .background(Color.themeSurface)
    }
}
