import SwiftUI
import UserNotifications

struct AppRootView: View {
    @StateObject private var userManager = UserManager.shared
    @State private var isCheckingLoginState = true
    
    @State private var userName: String = "User"
    @State private var isLoadingName = false
    
    @State private var showWelcomeOverlay = true
    
    // Heart Rate Reminder State
    @StateObject private var heartRateReminderManager = HeartRateReminderManager()
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("coreblue"), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Group {
                if isCheckingLoginState {
                    LoadingScreen()
                } else {
                    if userManager.isLoggedIn && userManager.isUserDataValid {
                        HomePageView(userId: userManager.currentUserId ?? 0)
                            .environmentObject(userManager)
                            .transition(.opacity)
                    } else {
                        ContentView()
                            .transition(.opacity)
                    }
                }
            }
            .animation(.spring(), value: isCheckingLoginState)
            .animation(.spring(), value: userManager.isLoggedIn)
            
            // ✅ Only show welcome overlay if logged in
            if showWelcomeOverlay && userManager.isLoggedIn {
                welcomeOverlay
                    .transition(.opacity)
                    .zIndex(999)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showWelcomeOverlay = false
                            }
                        }
                    }
            }
        }
        .onAppear {
            checkLoginState()
            if userManager.isLoggedIn {
                fetchUserName()
                setupHeartRateReminders()
            }
        }
        .onChange(of: userManager.isLoggedIn) { _, newValue in
            if newValue {
                fetchUserName()
                showWelcomeOverlay = true // ✅ show again after login
                setupHeartRateReminders()
            } else {
                // Cancel all notifications when user logs out
                heartRateReminderManager.cancelAllReminders()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Check for reminders when app becomes active
            if userManager.isLoggedIn {
                heartRateReminderManager.checkAndScheduleReminder(userId: userManager.currentUserId ?? 0)
            }
        }
    }
    
    private var welcomeOverlay: some View {
        ZStack {
            LinearGradient(
                colors: [Color("coreblue").opacity(0.8), Color.white.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "heart.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red, Color.pink],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .red.opacity(0.6), radius: 10)
                
                if isLoadingName {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Welcome back, \(userName)!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.black.opacity(0.1))
                    .blur(radius: 10)
            )
            .padding()
        }
    }
    
    private func checkLoginState() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                isCheckingLoginState = false
            }
        }
    }
    
    private func fetchUserName() {
        guard let userId = userManager.currentUserId else {
            userName = "User"
            return
        }
        
        isLoadingName = true
        guard let url = URL(string: "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare/user.php?user_id=\(userId)") else {
            userName = "User"
            isLoadingName = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoadingName = false
                if let data = data, error == nil {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let status = json["status"] as? String, status == "success",
                           let userData = json["data"] as? [String: Any],
                           let name = userData["name"] as? String {
                            userName = name
                        } else {
                            userName = "User"
                        }
                    } catch {
                        userName = "User"
                    }
                } else {
                    userName = "User"
                }
            }
        }.resume()
    }
    
    // MARK: - Heart Rate Reminder Setup
    private func setupHeartRateReminders() {
        guard let userId = userManager.currentUserId else { return }
        
        // Request notification permissions
        heartRateReminderManager.requestNotificationPermission()
        
        // Check and schedule reminder
        heartRateReminderManager.checkAndScheduleReminder(userId: userId)
    }
}

// MARK: - Heart Rate Reminder Manager
class HeartRateReminderManager: ObservableObject {
    private let reminderInterval: TimeInterval = 6 * 60 * 60 // 6 hours in seconds
    private let notificationIdentifier = "HeartRateReminder"
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func checkAndScheduleReminder(userId: Int) {
        guard userId > 0 else {
            print("❌ Invalid user ID for heart rate reminder")
            return
        }
        
        // First, cancel any existing reminders
        cancelAllReminders()
        
        // Fetch last heart rate measurement
        fetchLastHeartRateMeasurement(userId: userId) { [weak self] lastMeasurementDate in
            DispatchQueue.main.async {
                self?.scheduleReminderIfNeeded(lastMeasurementDate: lastMeasurementDate, userId: userId)
            }
        }
    }
    
    private func fetchLastHeartRateMeasurement(userId: Int, completion: @escaping (Date?) -> Void) {
        guard let url = URL(string: "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare/heartbeat.php?user_id=\(userId)&type=latest") else {
            print("❌ Invalid URL for heart rate fetch")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Error fetching last heart rate: \(error?.localizedDescription ?? "Unknown")")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String,
                   status.lowercased() == "success",
                   let timestamp = json["timestamp"] as? String {
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let lastMeasurementDate = formatter.date(from: timestamp)
                    
                    print("✅ Last heart rate measurement: \(timestamp)")
                    completion(lastMeasurementDate)
                } else {
                    print("⚠️ No heart rate data found or invalid response")
                    completion(nil)
                }
            } catch {
                print("❌ Error parsing heart rate response: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    private func scheduleReminderIfNeeded(lastMeasurementDate: Date?, userId: Int) {
        let now = Date()
        let shouldScheduleReminder: Bool
        let triggerTime: TimeInterval
        
        if let lastMeasurement = lastMeasurementDate {
            let timeSinceLastMeasurement = now.timeIntervalSince(lastMeasurement)
            
            if timeSinceLastMeasurement >= reminderInterval {
                // It's been more than 6 hours, send reminder immediately
                shouldScheduleReminder = true
                triggerTime = 10 // 10 seconds delay for immediate reminder
                print("⏰ Scheduling immediate heart rate reminder (last measurement: \(formatTimeAgo(timeSinceLastMeasurement)))")
            } else {
                // Schedule reminder for when 6 hours will have passed
                let remainingTime = reminderInterval - timeSinceLastMeasurement
                shouldScheduleReminder = true
                triggerTime = remainingTime
                print("⏰ Scheduling heart rate reminder in \(formatDuration(remainingTime))")
            }
        } else {
            // No previous measurement found, remind user to take first measurement
            shouldScheduleReminder = true
            triggerTime = 10 // 10 seconds delay for immediate reminder
            print("⏰ No previous heart rate measurement found, scheduling immediate reminder")
        }
        
        if shouldScheduleReminder {
            scheduleNotification(triggerTime: triggerTime, userId: userId, isFirstTime: lastMeasurementDate == nil)
        }
    }
    
    private func scheduleNotification(triggerTime: TimeInterval, userId: Int, isFirstTime: Bool = false) {
        let content = UNMutableNotificationContent()
        
        if isFirstTime {
            content.title = "💗 Welcome to Core Care!"
            content.body = "Let's start tracking your heart health. Tap to measure your heart rate now."
        } else {
            let messages = [
                "It's time for your heart rate check! 💗",
                "Don't forget to monitor your heart health today! ❤️",
                "Your heart deserves attention - take a quick measurement! 💓",
                "Keep your health on track - measure your heart rate now! 🫀",
                "Time for a quick heart rate check-up! 💖"
            ]
            content.title = "Heart Rate Reminder"
            content.body = messages.randomElement() ?? "Time to measure your heart rate!"
        }
        
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "HEART_RATE_REMINDER"
        content.userInfo = ["userId": userId, "type": "heartRateReminder"]
        
        // Create trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerTime, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )
        
        // Add notification actions
        let measureAction = UNNotificationAction(
            identifier: "MEASURE_NOW",
            title: "Measure Now",
            options: [.foreground]
        )
        
        let remindLaterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "Remind in 1 hour",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "HEART_RATE_REMINDER",
            actions: [measureAction, remindLaterAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling heart rate reminder: \(error.localizedDescription)")
            } else {
                print("✅ Heart rate reminder scheduled successfully")
            }
        }
    }
    
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        print("🗑️ Cancelled all heart rate reminders")
    }
    
    // MARK: - Helper Functions
    private func formatTimeAgo(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        }
    }
    
    private func formatDuration(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - App Delegate for Notification Handling
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let userId = userInfo["userId"] as? Int,
           let type = userInfo["type"] as? String,
           type == "heartRateReminder" {
            
            switch response.actionIdentifier {
            case "MEASURE_NOW":
                // Navigate to heart rate measurement
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenHeartRateView"), object: nil)
                }
                
            case "REMIND_LATER":
                // Schedule another reminder in 1 hour
                _ = HeartRateReminderManager()
                let content = UNMutableNotificationContent()
                content.title = "Core Care Reminder"
                content.body = "Don't forget to check your heart rate! 💗"
                content.sound = .default
                content.badge = 1
                content.userInfo = ["userId": userId, "type": "heartRateReminder"]
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false) // 1 hour
                let request = UNNotificationRequest(identifier: "HeartRateReminderLater", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request)
                
            default:
                // Default tap - open app
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenHeartRateView"), object: nil)
                }
            }
        }
        
        completionHandler()
    }
}

struct LoadingScreen: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color("coreblue").opacity(0.5),
                    Color.white,
                    Color("coreblue").opacity(0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image("corecarelogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("coreblue")))
                    .scaleEffect(1.2)
                
                Text("Loading...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    AppRootView()
}
