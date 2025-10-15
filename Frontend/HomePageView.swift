//
//  HomePageView.swift
//  Core Care
//
//  Enhanced Dashboard with Mood & Wellness Integration
//

import SwiftUI
import HealthKit

// MARK: - Enums & Models

enum HomePageSection: CaseIterable {
    case home, userDetails, hrCheck, weight, bp, ai, history, moodWellness
}

// MARK: - Response Models

struct HeartRateResponse: Codable {
    let status: String
    let bpm: Int
    let timestamp: String?
}

struct WeightResponse: Codable {
    let status: String
    let message: String?
    let data: WeightData
}

struct WeightData: Codable {
    let user_id: Int
    let weight: Double
    let height: Double
    let bmi: Double
    let category: String
}

struct BloodPressureResponse: Codable {
    let status: String
    let message: String?
    let data: BPData
}

struct BPData: Codable {
    let user_id: Int
    let bpm: Int
    let systolic: Int
    let diastolic: Int
    let category: String
    let recorded_at: String
}

// MARK: - NEW: Mood & Wellness Response Models

struct MoodWellnessResponse: Codable {
    let status: String
    let mood: String?
    let symptoms: [String]
    let heart_rate: Int
    let context_note: String?
    let timestamp: String?
    let message: String?
}

// MARK: - HealthKit Data Manager

class HealthDataManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var todayStepCount: Int = 0
    @Published var lastSleepHours: Double = 0
    @Published var healthKitAvailable = true

    init() {
        if HKHealthStore.isHealthDataAvailable() {
            requestAuthorization()
        } else {
            healthKitAvailable = false
        }
    }

    func requestAuthorization() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return
        }

        healthStore.requestAuthorization(toShare: [], read: [stepType, sleepType]) { success, error in
            if success {
                self.fetchTodaySteps()
                self.fetchRecentSleep()
            } else {
                print("HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    func fetchTodaySteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch step count: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            DispatchQueue.main.async {
                self.todayStepCount = Int(sum.doubleValue(for: HKUnit.count()))
            }
        }
        healthStore.execute(query)
    }

    func fetchRecentSleep() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -7, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: [])

        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 10, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, error in
            guard let samples = samples as? [HKCategorySample] else {
                print("Failed to fetch sleep data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            // Filter for in-bed sleep analysis and calculate total sleep time for most recent night
            let sleepSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue }
            var totalSleepTime: TimeInterval = 0
            if let mostRecentSleep = sleepSamples.first {
                totalSleepTime = mostRecentSleep.endDate.timeIntervalSince(mostRecentSleep.startDate)
            }

            DispatchQueue.main.async {
                self.lastSleepHours = totalSleepTime / 3600 // Convert to hours
            }
        }
        healthStore.execute(query)
    }
}

// MARK: - Main View

struct HomePageView: View {
    let userId: Int
    @EnvironmentObject var userManager: UserManager
    @State private var selectedAvatar: String = ""
    @State private var currentPage: HomePageSection = .home
    @State private var latestBPM: String = "--"
    @State private var bpmCategory: String = "Rate: --"
    @State private var weight: String = "--"
    @State private var height: Double = 170.0 // Default height in cm
    @State private var bmiCategory: String = "BMI: --"
    @State private var systolic: String = "--"
    @State private var diastolic: String = "--"
    @State private var bpCategory: String = "BP: --"

    // UPDATED: Mood & Wellness State Variables
    @State private var currentMood: String = "😐 Neutral"
    @State private var moodWellnessStatus: String = "Status: --"
    @State private var lastMoodEntry: String = "No entries"
    @State private var moodEmoji: String = "😐"
    @State private var moodColor: Color = Color.blue

    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var fetchedUserName: String = ""
    @State private var scrollOffset: CGFloat = 0

    @StateObject private var healthManager = HealthDataManager()

    // Get user data from UserManager with proper validation
    private var currentUserId: Int {
        let managerId = userManager.currentUserId
        print("HomePageView - UserManager ID: \(managerId ?? -1), Passed ID: \(userId)")
        if let managerId = managerId, managerId > 0 {
            return managerId
        } else if userId > 0 {
            return userId
        } else {
            print("WARNING: No valid user ID available!")
            return 0
        }
    }

    private var userName: String {
        if !fetchedUserName.isEmpty {
            return fetchedUserName
        }
        return "User"
    }

    // Enhanced Color Palette
    private let primaryColor = Color(red: 0.05, green: 0.07, blue: 0.12)
    private let secondaryColor = Color(red: 0.98, green: 0.98, blue: 1.0)
    private let accentColor = Color(red: 0.24, green: 0.55, blue: 1.0)
    private let surfaceColor = Color.white
    private let textPrimary = Color(red: 0.11, green: 0.13, blue: 0.19)
    private let textSecondary = Color(red: 0.42, green: 0.47, blue: 0.57)

    // Enhanced Gradients
    private let heroGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.24, green: 0.55, blue: 1.0),
            Color(red: 0.32, green: 0.43, blue: 0.98),
            Color(red: 0.45, green: 0.32, blue: 0.95)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let aiGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.15, green: 0.85, blue: 0.65),
            Color(red: 0.08, green: 0.75, blue: 0.58)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Enhanced Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        secondaryColor,
                        Color(red: 0.96, green: 0.97, blue: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                contentView(geo: geo)

                if currentPage == .home {
                    bottomNavigation(geo: geo)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                            removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                        ))
                }

                if isLoading {
                    LoadingOverlay()
                }
            }
        }
        .onAppear {
            validateUserSession()
            loadAllHealthMetrics()
            refreshUserName()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserAvatarChanged"))) { notification in
            if let avatar = notification.userInfo?["avatar"] as? String {
                self.selectedAvatar = avatar
                print("HomePageView: Avatar updated to \(avatar)")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MoodEntryAdded"))) { _ in
            // Refresh mood data when returning from mood entry screen
            loadLatestMoodEntry()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    @ViewBuilder
    private func contentView(geo: GeometryProxy) -> some View {
        switch currentPage {
        case .home:
            homeContentView(geo: geo)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
        case .userDetails:
            UserDetailsView(userId: currentUserId)
                .environmentObject(userManager)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
        case .hrCheck:
            HRCheckView()
                .environmentObject(userManager)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
        case .weight:
            WeightView()
                .environmentObject(userManager)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
        case .bp:
            BPView()
                .environmentObject(userManager)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
        case .ai:
            AIView()
                .environmentObject(userManager)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
        case .history:
            HistoryView()
                .environmentObject(userManager)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
        case .moodWellness:
            BloodSugarView() // This is now the Mood & Wellness view
                .environmentObject(userManager)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
        }
    }

    // MARK: - User Session Validation
    private func validateUserSession() {
        print("Validating user session...")
        print("UserManager isLoggedIn: \(userManager.isLoggedIn)")
        print("UserManager userData: \(userManager.userData?.user_id ?? -1)")
        print("Passed userId: \(userId)")
        print("Computed currentUserId: \(currentUserId)")

        if currentUserId == 0 {
            showError = true
            errorMessage = "Invalid user session. Please log in again."
        }
    }

    // MARK: - Enhanced Home Content View
    @ViewBuilder
    private func homeContentView(geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            headerView(geo: geo)
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        welcomeHeroSection(geo: geo)
                            .id("hero")
                        quickCheckSection(geo: geo)
                            .id("quickcheck")
                        healthMetricsGrid(geo: geo)
                            .id("metrics")
                        appleHealthSection(geo: geo)
                            .id("applehealth")
                        aiAssistantSection(geo: geo)
                            .id("ai")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, geo.size.height * 0.2)
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                    }
                )
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
                .coordinateSpace(name: "scroll")
            }
        }
    }

    // MARK: - Enhanced Header with Dynamic Effects and Avatar Support
    private func headerView(geo: GeometryProxy) -> some View {
        let headerOpacity = min(1.0, max(0.3, 1.0 - (scrollOffset / -100)))
        return HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome back,")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textSecondary)
                    .opacity(headerOpacity)
                Text(userName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(textPrimary)
                    .scaleEffect(0.9 + (headerOpacity * 0.1))

            }
            Spacer()
            Button {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    currentPage = .userDetails
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(surfaceColor)
                        .frame(width: 50, height: 50)
                        .shadow(color: accentColor.opacity(0.2), radius: 8, x: 0, y: 4)

                    // Display selected avatar or default icon
                    if !selectedAvatar.isEmpty {
                        Image(selectedAvatar)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 45, height: 45)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(accentColor)
                    }
                }
                .scaleEffect(headerOpacity)
            }
            .buttonStyle(BouncyButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.top, geo.safeAreaInsets.top > 0 ? geo.safeAreaInsets.top + 10 : 30)
        .padding(.bottom, 20)
        .background(
            surfaceColor.opacity(0.95)
                .blur(radius: scrollOffset < -50 ? 10 : 0)
        )
    }

    // MARK: - New Welcome Hero Section
    private func welcomeHeroSection(geo: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Health")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text("Dashboard")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                    Text("Track, monitor, and improve your wellbeing")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(24)
        .background(heroGradient)
        .cornerRadius(20)
        .shadow(color: accentColor.opacity(0.3), radius: 15, x: 0, y: 8)
    }

    // MARK: - Enhanced Quick Check Section
    private func quickCheckSection(geo: GeometryProxy) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Check")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(textPrimary)
                Spacer()
                Button("View All") {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        currentPage = .history
                    }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accentColor)
            }

            Button {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    currentPage = .hrCheck
                }
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 50, height: 50)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Measure Heart Rate")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(textPrimary)
                        Text("Get instant heart rate reading")
                            .font(.system(size: 14))
                            .foregroundColor(textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accentColor)
                }
                .padding(20)
                .background(surfaceColor)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(CardButtonStyle())
        }
    }

    // MARK: - Enhanced Health Metrics Grid
    private func healthMetricsGrid(geo: GeometryProxy) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Health Metrics")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(textPrimary)
                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible())
            ], spacing: 16) {
                enhancedHealthMetricCard(
                    title: "Heart Rate",
                    value: latestBPM,
                    subtitle: bpmCategory,
                    icon: "heart.fill",
                    color: Color.red,
                    gradient: LinearGradient(
                        gradient: Gradient(colors: [Color.red.opacity(0.8), Color.red]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            currentPage = .hrCheck
                        }
                    }
                )

                enhancedHealthMetricCard(
                    title: "Weight",
                    value: weight,
                    subtitle: bmiCategory,
                    icon: "scalemass.fill",
                    color: Color.orange,
                    gradient: LinearGradient(
                        gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.orange]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            currentPage = .weight
                        }
                    }
                )

                enhancedHealthMetricCard(
                    title: "Blood Pressure",
                    value: "\(systolic)/\(diastolic)",
                    subtitle: bpCategory,
                    icon: "waveform.path.ecg",
                    color: Color.purple,
                    gradient: LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            currentPage = .bp
                        }
                    }
                )

                // UPDATED: Mood & Wellness Card with dynamic colors
                enhancedHealthMetricCard(
                    title: "Mood & Wellness",
                    value: currentMood,
                    subtitle: moodWellnessStatus,
                    icon: "brain.head.profile",
                    color: moodColor,
                    gradient: LinearGradient(
                        gradient: Gradient(colors: [moodColor.opacity(0.8), moodColor]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            currentPage = .moodWellness
                        }
                    }
                )
            }
        }
    }

    // MARK: - Enhanced Health Metric Card
    private func enhancedHealthMetricCard(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        color: Color,
        gradient: LinearGradient,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(color)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(textSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.system(size: title == "Mood & Wellness" ? 16 : 20, weight: .bold))
                        .foregroundColor(textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(textSecondary)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(color.opacity(0.1))
                        .cornerRadius(8)
                }
                Spacer()
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
            .background(surfaceColor)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(CardButtonStyle())
    }

    // MARK: - Apple Health Data Section (Display Only)
    private func appleHealthSection(geo: GeometryProxy) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Apple Health")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(textPrimary)
                Spacer()
            }

            VStack {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 50, height: 50)
                        Image(systemName: "figure.walk")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.green)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(healthManager.todayStepCount)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(textPrimary)
                            Text("steps today")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(textSecondary)
                        }

                        HStack {
                            Image(systemName: "bed.double.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text("Sleep: \(String(format: "%.1f", healthManager.lastSleepHours)) hours")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(textSecondary)
                        }
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Image(systemName: healthManager.healthKitAvailable ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(healthManager.healthKitAvailable ? .green : .orange)
                        Text(healthManager.healthKitAvailable ? "Synced" : "No Access")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(healthManager.healthKitAvailable ? .green : .orange)
                    }
                }
                .padding(20)
                .background(surfaceColor)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
            }
        }
    }

    // MARK: - Enhanced AI Assistant Section
    private func aiAssistantSection(geo: GeometryProxy) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("AI Assistant")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(textPrimary)
                Spacer()
            }

            Button {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    currentPage = .ai
                }
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 50, height: 50)
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Core Care AI")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("Get personalized health insights")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(20)
                .background(aiGradient)
                .cornerRadius(18)
                .shadow(color: Color.green.opacity(0.3), radius: 15, x: 0, y: 8)
            }
            .buttonStyle(CardButtonStyle())
        }
    }

    // MARK: - Enhanced Bottom Navigation
    private func bottomNavigation(geo: GeometryProxy) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 0) {
                ForEach([
                    ("house.fill", "Home", HomePageSection.home),
                    ("clock.fill", "History", HomePageSection.history),
                    ("person.fill", "Profile", HomePageSection.userDetails)
                ], id: \.1) { icon, label, page in
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            currentPage = page
                        }
                    } label: {
                        EnhancedBottomNavItem(
                            systemName: icon,
                            label: label,
                            isActive: currentPage == page
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(surfaceColor)
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -5)
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                }
            )
            .padding(.horizontal, 20)
            .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? geo.safeAreaInsets.bottom + 10 : 30)
        }
    }

    // MARK: - Refresh Functions
    func refreshUserName() {
        guard currentUserId > 0,
              let url = URL(string: "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare/user.php?user_id=\(currentUserId)") else {
            print("Invalid userId or URL for refreshing user name")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("Error refreshing user name: \(error?.localizedDescription ?? "Unknown")")
                    return
                }

                do {
                    let response = try JSONDecoder().decode(ServerUserResponse.self, from: data)
                    if response.status == "success", let user = response.data {
                        self.fetchedUserName = user.name ?? "User"
                        self.selectedAvatar = user.profile_picture ?? ""
                        print("User name refreshed: \(self.fetchedUserName)")
                        print("Avatar loaded: \(self.selectedAvatar)")
                    }
                } catch {
                    print("Error parsing user data for name refresh: \(error)")
                }
            }
        }.resume()
    }

    func loadAllHealthMetrics() {
        loadLatestHeartRate()
        loadLatestBloodPressure()
        loadLatestWeight()
        loadLatestMoodEntry() // UPDATED: Load mood data from API

        if healthManager.healthKitAvailable {
            healthManager.fetchTodaySteps()
            healthManager.fetchRecentSleep()
        }
    }

    // MARK: - Load Latest Heart Rate
    func loadLatestHeartRate() {
        guard currentUserId > 0,
              let url = URL(string: "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare/heartbeat.php?user_id=\(currentUserId)&type=latest") else {
            print("Invalid userId or URL for heartbeat")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("Error loading heartbeat: \(error?.localizedDescription ?? "Unknown")")
                    return
                }

                if let result = try? JSONDecoder().decode(HeartRateResponse.self, from: data),
                   result.status.lowercased() == "success" {
                    self.latestBPM = "\(result.bpm) BPM"

                    let category: String
                    if result.bpm < 60 {
                        category = "Low"
                    } else if result.bpm <= 100 {
                        category = "Normal"
                    } else {
                        category = "High"
                    }
                    self.bpmCategory = "Rate: \(category)"
                    print("Latest heart rate loaded: \(result.bpm) BPM")
                }
            }
        }.resume()
    }

    // MARK: - Load Latest Blood Pressure
    func loadLatestBloodPressure() {
        guard currentUserId > 0,
              let url = URL(string: "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare/bp.php?user_id=\(currentUserId)&type=latest") else {
            print("Invalid userId or URL for blood pressure")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("Error loading latest blood pressure: \(error?.localizedDescription ?? "Unknown")")
                    return
                }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String,
                   status.lowercased() == "success",
                   let bpData = json["data"] as? [String: Any],
                   let systolic = bpData["systolic"] as? Int,
                   let diastolic = bpData["diastolic"] as? Int,
                   let category = bpData["category"] as? String {
                    self.systolic = "\(systolic)"
                    self.diastolic = "\(diastolic)"
                    self.bpCategory = category
                    print("Latest BP loaded: \(systolic)/\(diastolic) - \(category)")
                } else {
                    print("No latest blood pressure data found or failed to parse")
                    self.systolic = "--"
                    self.diastolic = "--"
                    self.bpCategory = "BP: No Data"
                }
            }
        }.resume()
    }

    // MARK: - Load Latest Weight
    func loadLatestWeight() {
        guard currentUserId > 0,
              let url = URL(string: "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare/weight.php?user_id=\(currentUserId)") else {
            print("Invalid userId or URL for weight")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("Error loading weight: \(error?.localizedDescription ?? "Unknown")")
                    return
                }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String,
                   status.lowercased() == "success",
                   let weightData = json["data"] as? [String: Any],
                   let weight = weightData["weight"] as? Double,
                   let bmiCategory = weightData["bmi_category"] as? String {
                    self.weight = "\(Int(weight)) KGS"
                    self.bmiCategory = "BMI: \(bmiCategory)"
                    print("Latest weight loaded: \(weight) kg - \(bmiCategory)")
                } else {
                    print("No weight data found or failed to parse")
                }
            }
        }.resume()
    }

    // MARK: - NEW: Load Latest Mood Entry from API
    func loadLatestMoodEntry() {
        guard currentUserId > 0,
              let url = URL(string: "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare/mood_wellness.php?user_id=\(currentUserId)&type=latest") else {
            print("Invalid userId or URL for mood wellness")
            return
        }

        print("Loading latest mood entry for user \(currentUserId)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("Error loading mood wellness: \(error?.localizedDescription ?? "Unknown")")
                    self.setDefaultMoodValues()
                    return
                }

                do {
                    let result = try JSONDecoder().decode(MoodWellnessResponse.self, from: data)
                    if result.status.lowercased() == "success" {
                        // Parse mood data from API response
                        let moodText = result.mood ?? "Neutral"
                        let symptoms = result.symptoms
                        _ = result.heart_rate
                        let timestamp = result.timestamp
                        
                        // Set mood emoji and color based on mood text
                        let (emoji, color) = self.getMoodEmojiAndColor(for: moodText)
                        self.moodEmoji = emoji
                        self.moodColor = color
                        self.currentMood = "\(emoji) \(moodText)"
                        
                        // Create status message based on symptoms
                        let symptomCount = symptoms.count
                        if symptomCount == 0 {
                            self.moodWellnessStatus = "No symptoms"
                        } else if symptomCount == 1 {
                            self.moodWellnessStatus = "1 symptom"
                        } else {
                            self.moodWellnessStatus = "\(symptomCount) symptoms"
                        }
                        
                        // Format last entry time
                        if let timestamp = timestamp {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            if let date = formatter.date(from: timestamp) {
                                formatter.dateStyle = .short
                                formatter.timeStyle = .short
                                self.lastMoodEntry = "Last: \(formatter.string(from: date))"
                            } else {
                                self.lastMoodEntry = "Last: \(timestamp)"
                            }
                        } else {
                            self.lastMoodEntry = "Recent entry"
                        }
                        
                        print("Latest mood entry loaded: \(moodText) - \(symptomCount) symptoms")
                        
                    } else {
                        print("API returned error: \(result.message ?? "Unknown error")")
                        self.setDefaultMoodValues()
                    }
                } catch {
                    print("Error decoding mood wellness response: \(error)")
                    self.setDefaultMoodValues()
                }
            }
        }.resume()
    }
    
    // Helper function to set default mood values
    private func setDefaultMoodValues() {
        self.currentMood = "😐 Neutral"
        self.moodEmoji = "😐"
        self.moodColor = Color.blue
        self.moodWellnessStatus = "No entries yet"
        self.lastMoodEntry = "Start tracking!"
        print("Set default mood values for user \(self.currentUserId)")
    }
    
    // Helper function to get emoji and color for mood
    private func getMoodEmojiAndColor(for mood: String) -> (String, Color) {
        switch mood.lowercased() {
        case "very happy":
            return ("😄", Color.green)
        case "happy":
            return ("😊", Color.green.opacity(0.8))
        case "neutral":
            return ("😐", Color.blue)
        case "sad":
            return ("😔", Color.orange)
        case "very sad":
            return ("😢", Color.red.opacity(0.8))
        case "anxious":
            return ("😰", Color.yellow)
        case "stressed":
            return ("😤", Color.red)
        default:
            return ("😐", Color.blue)
        }
    }

    // MARK: - Send Data Functions (keeping all original functionality)
    func sendHeartbeat(bpm: Int) {
        guard currentUserId > 0,
              let url = URL(string: "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare/heartbeat.php") else {
            print("Invalid user ID or URL for heartbeat")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["user_id": currentUserId, "bpm": bpm]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        print("Sending heartbeat data for user \(currentUserId): \(bpm) BPM")
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error sending heartbeat: \(error?.localizedDescription ?? "Unknown")")
                return
            }

            if let result = try? JSONDecoder().decode(HeartRateResponse.self, from: data),
               result.status.lowercased() == "success" {
                DispatchQueue.main.async {
                    self.loadLatestHeartRate()
                    print("Heartbeat data saved successfully")
                }
            } else {
                print("Failed to save heartbeat data")
            }
        }.resume()
    }

    func sendWeight(weight: Double, height: Double) {
        guard currentUserId > 0,
              let url = URL(string: "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare/weight.php") else {
            print("Invalid user ID or URL for weight")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "user_id": currentUserId,
            "weight": weight,
            "height": height
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        print("Sending weight data for user \(currentUserId): \(weight) kg, height: \(height) cm")
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("Error sending weight: \(error?.localizedDescription ?? "Unknown")")
                    return
                }

                if let result = try? JSONDecoder().decode(WeightResponse.self, from: data),
                   result.status.lowercased() == "success" {
                    self.loadLatestWeight()
                    self.height = result.data.height
                    print("Weight data saved successfully")
                } else {
                    print("Failed to save weight data")
                }
            }
        }.resume()
    }

    func sendBloodPressureFromBPM(bpm: Int) {
        guard currentUserId > 0,
              let url = URL(string: "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare/bp.php") else {
            print("Invalid user ID or URL for blood pressure")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["user_id": currentUserId, "bpm": bpm]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        print("Sending BP calculation from BPM for user \(currentUserId): \(bpm) BPM")
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("Error sending BP: \(error?.localizedDescription ?? "Unknown")")
                    return
                }

                if let result = try? JSONDecoder().decode(BloodPressureResponse.self, from: data),
                   result.status.lowercased() == "success" {
                    self.loadLatestBloodPressure()
                    print("BP data calculated and saved successfully")
                } else {
                    print("Failed to save BP data")
                }
            }
        }.resume()
    }
}

// MARK: - Enhanced Supporting Views

struct EnhancedBottomNavItem: View {
    var systemName: String
    var label: String
    var isActive: Bool

    private let accentColor = Color(red: 0.24, green: 0.55, blue: 1.0)
    private let textSecondary = Color(red: 0.42, green: 0.47, blue: 0.57)

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if isActive {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                        .scaleEffect(isActive ? 1.0 : 0.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
                }

                Image(systemName: systemName)
                    .font(.system(size: isActive ? 20 : 18, weight: isActive ? .bold : .medium))
                    .foregroundColor(isActive ? accentColor : textSecondary)
                    .scaleEffect(isActive ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
            }

            Text(label)
                .font(.system(size: 11, weight: isActive ? .semibold : .medium))
                .foregroundColor(isActive ? accentColor : textSecondary)
                .animation(.easeInOut(duration: 0.2), value: isActive)
        }
        .frame(height: 60)
    }
}

// MARK: - Custom Button Styles

struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Enhanced Visual Effect View

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: effect)
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}

// MARK: - Enhanced Loading Overlay

struct LoadingOverlay: View {
    @State private var rotationAngle: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { }

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 50, height: 50)

                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(rotationAngle))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: rotationAngle)
                }

                Text("Loading...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .blur(radius: 20)
            )
        }
        .onAppear {
            rotationAngle = 360
        }
    }
}

// MARK: - Server Response Models with Avatar Support

struct ServerUserResponse: Codable {
    let status: String
    let data: ServerUserData?
    let message: String?
}

struct ServerUserData: Codable {
    let name: String?
    let age: Int?
    let sex: String?
    let height: String?
    let phone: String?
    let email: String?
    let profile_picture: String? // Avatar field
}

// Keeping original BottomNavBarItem for backward compatibility
struct BottomNavBarItem: View {
    var systemName: String
    var label: String
    var geo: GeometryProxy
    var isActive: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.system(size: isActive ? 22 : 20, weight: isActive ? .bold : .medium))
                .foregroundColor(isActive ? Color(red: 0.33, green: 0.42, blue: 0.95) : Color.gray)

            Text(label)
                .font(.system(size: 12, weight: isActive ? .semibold : .medium))
                .foregroundColor(isActive ? Color(red: 0.33, green: 0.42, blue: 0.95) : Color.gray)
        }
        .frame(width: 60)
        .padding(.vertical, 15)
        .background(isActive ? Color(red: 0.33, green: 0.42, blue: 0.95).opacity(0.1) : Color.clear)
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct HomePageView_Previews: PreviewProvider {
    static var previews: some View {
        HomePageView(userId: 1)
            .environmentObject(UserManager.shared)
    }
}
