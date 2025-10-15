import SwiftUI

@main
struct Core_CareApp: App {
    // Register AppDelegate for notification handling
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenHeartRateView"))) { _ in
                    // Handle notification tap to open heart rate view
                    // This will be handled by the navigation logic in AppRootView/HomePageView
                }
        }
    }
}
class Manager {
    static let shared = Manager()
    private init () {}
    var userData: LoginData?
}
