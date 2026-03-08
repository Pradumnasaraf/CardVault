import SwiftUI

struct RootView: View {
    let dependencies: AppDependencies

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var lockViewModel: AppLockViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _lockViewModel = StateObject(wrappedValue: AppLockViewModel(authenticationService: dependencies.authenticationService))
    }

    var body: some View {
        ZStack {
            CardListView(
                repository: dependencies.repository,
                authenticationService: dependencies.authenticationService
            )
                .blur(radius: lockViewModel.isUnlocked ? 0 : 12)
                .disabled(!lockViewModel.isUnlocked)
                .animation(.easeInOut(duration: 0.24), value: lockViewModel.isUnlocked)

            if !lockViewModel.isUnlocked {
                AppLockGateView(
                    isAuthenticating: lockViewModel.isAuthenticating,
                    errorMessage: lockViewModel.errorMessage,
                    unlockAction: {
                        Task {
                            await lockViewModel.unlock()
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .task {
            await lockViewModel.unlockIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await lockViewModel.unlockIfNeeded()
                }
            case .background:
                lockViewModel.lock()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}

private struct AppLockGateView: View {
    let isAuthenticating: Bool
    let errorMessage: String?
    let unlockAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.16)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "faceid")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.tint)

                Text("CardVault Locked")
                    .font(.title2.weight(.semibold))

                Text("Authenticate with Face ID to access your cards.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button(action: unlockAction) {
                    HStack(spacing: 8) {
                        if isAuthenticating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "faceid")
                                .font(.headline)
                        }

                        Text(isAuthenticating ? "Authenticating..." : "Unlock with Face ID")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.blue.opacity(isAuthenticating ? 0.70 : 0.90))
                    )
                }
                .buttonStyle(.plain)
                .disabled(isAuthenticating)

                if let errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(28)
            .frame(maxWidth: 360)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding()
        }
    }
}
