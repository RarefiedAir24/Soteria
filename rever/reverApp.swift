import SwiftUI
import FirebaseCore

@main
struct ReverApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var savingsService = SavingsService()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(savingsService)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if authService.isAuthenticated {
                // User is signed in → main app
                MainTabView()
            } else {
                // User is signed out → auth flow
                AuthView()
            }
        }
    }
}
