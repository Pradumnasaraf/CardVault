import SwiftUI

@main
struct CardVaultApp: App {
    private static let dependenciesResult: Result<AppDependencies, Error> = {
        do {
            return .success(try AppDependencies.live())
        } catch {
            return .failure(error)
        }
    }()

    var body: some Scene {
        WindowGroup {
            switch Self.dependenciesResult {
            case .success(let dependencies):
                RootView(dependencies: dependencies)
            case .failure(let error):
                StartupErrorView(message: error.localizedDescription)
            }
        }
    }
}

private struct StartupErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
            Text("Unable to Start CardVault")
                .font(.title2.weight(.semibold))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
