import SwiftUI

// MARK: - Supporting Enums and Models

enum MoodType: String, CaseIterable, Codable {
    case veryHappy = "Very Happy"
    case happy = "Happy"
    case neutral = "Neutral"
    case sad = "Sad"
    case verySad = "Very Sad"
    case anxious = "Anxious"
    case stressed = "Stressed"

    var emoji: String {
        switch self {
        case .veryHappy: return "😄"
        case .happy: return "😊"
        case .neutral: return "😐"
        case .sad: return "😔"
        case .verySad: return "😢"
        case .anxious: return "😰"
        case .stressed: return "😤"
        }
    }

    var color: Color {
        switch self {
        case .veryHappy: return .yellow
        case .happy: return .green
        case .neutral: return .blue
        case .sad: return .gray
        case .verySad: return .purple
        case .anxious: return .orange
        case .stressed: return .red
        }
    }
}

enum SymptomType: String, CaseIterable, Codable {
    case fatigue = "Fatigue"
    case shortnessOfBreath = "Shortness of Breath"
    case palpitations = "Heart Palpitations"
    case headache = "Headache"
    case dizziness = "Dizziness"
    case chestPain = "Chest Pain"
    case jointPain = "Joint Pain"
    case muscleAches = "Muscle Aches"
    case sleepIssues = "Sleep Issues"

    var icon: String {
        switch self {
        case .fatigue: return "bed.double.fill"
        case .shortnessOfBreath: return "lungs.fill"
        case .palpitations: return "waveform.path.ecg"
        case .headache: return "brain.head.profile"
        case .dizziness: return "tornado"
        case .chestPain: return "heart.text.square"
        case .jointPain: return "figure.walk"
        case .muscleAches: return "figure.strengthtraining.traditional"
        case .sleepIssues: return "moon.zzz.fill"
        }
    }

    var color: Color {
        switch self {
        case .fatigue: return .indigo
        case .shortnessOfBreath: return .red
        case .palpitations: return .red
        case .headache: return .purple
        case .dizziness: return .cyan
        case .chestPain: return .pink
        case .jointPain: return .brown
        case .muscleAches: return .orange
        case .sleepIssues: return .mint
        }
    }

    var description: String {
        switch self {
        case .fatigue: return "Feeling tired or lacking energy"
        case .shortnessOfBreath: return "Difficulty breathing or feeling winded"
        case .palpitations: return "Irregular or rapid heartbeat"
        case .headache: return "Pain or pressure in the head"
        case .dizziness: return "Feeling lightheaded or unsteady"
        case .chestPain: return "Discomfort or pain in chest area"
        case .jointPain: return "Aching or stiffness in joints"
        case .muscleAches: return "Soreness or tension in muscles"
        case .sleepIssues: return "Difficulty falling or staying asleep"
        }
    }
}

struct MoodWellnessEntry: Codable {
    let userId: Int
    let mood: MoodType
    let symptoms: [SymptomType]
    let heartRate: Int
    let contextNote: String
    let timestamp: Date
}

struct BloodSugarView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var currentBPM: Int = 0
    @State private var selectedMood: MoodType = .neutral
    @State private var selectedSymptoms: Set<SymptomType> = []
    @State private var contextNote: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var lastUpdated = ""
    @State private var toHome: Bool = false
    @State private var animateMood = false
    @State private var animateHeartbeat = false
    @State private var recentEntries: [MoodWellnessEntry] = []
    @State private var showSuccessAnimation = false
    @State private var isDataLoaded = false

    @AppStorage("userID") private var userID: Int = 1

    // ENHANCED: Animation states for better UI feedback
    @State private var pulseAnimation = false
    @State private var floatingElements = false
    @State private var cardAppearance = false

    // Computed property to get current user ID
    private var currentUserId: Int {
        if let managerId = userManager.currentUserId, managerId > 0 {
            return managerId
        } else if userID > 0 {
            return userID
        } else {
            return 1
        }
    }

    // MODIFIED: Automatically show insights when mood is not neutral or symptoms are selected
    private var shouldShowInsights: Bool {
        return selectedMood != .neutral || !selectedSymptoms.isEmpty
    }

    // Dynamic insights based on mood and symptoms (without stress level)
    private var dynamicInsights: [HealthInsight] {
        var insights: [HealthInsight] = []

        // Mood-based insights
        switch selectedMood {
        case .veryHappy:
            insights.append(HealthInsight(icon: "sun.max.fill", title: "Positive Energy", description: "Great mood can boost immune system", color: .yellow, urgency: .positive))
        case .happy:
            insights.append(HealthInsight(icon: "heart.fill", title: "Good Vibes", description: "Positive mood supports heart health", color: .green, urgency: .positive))
        case .neutral:
            if !selectedSymptoms.isEmpty {
                insights.append(HealthInsight(icon: "minus.circle", title: "Steady Mood", description: "Balanced mood while experiencing symptoms", color: .blue, urgency: .neutral))
            }
        case .sad:
            insights.append(HealthInsight(icon: "cloud.rain.fill", title: "Low Mood Alert", description: "Consider gentle exercise or talking to someone", color: .gray, urgency: .moderate))
        case .verySad:
            insights.append(HealthInsight(icon: "heart.slash.fill", title: "Mood Support Needed", description: "Reach out to friends or healthcare provider", color: .purple, urgency: .critical))
        case .anxious:
            insights.append(HealthInsight(icon: "bolt.fill", title: "Anxiety Alert", description: "Try breathing exercises or meditation", color: .orange, urgency: .moderate))
        case .stressed:
            insights.append(HealthInsight(icon: "exclamationmark.triangle.fill", title: "Stress Management", description: "Consider relaxation techniques", color: .red, urgency: .critical))
        }

        // Symptom-based insights
        if selectedSymptoms.contains(.fatigue) {
            insights.append(HealthInsight(icon: "bed.double.fill", title: "Rest Needed", description: "Fatigue may indicate need for better sleep", color: .indigo, urgency: .moderate))
        }
        if selectedSymptoms.contains(.shortnessOfBreath) {
            insights.append(HealthInsight(icon: "lungs.fill", title: "Breathing Concern", description: "Monitor closely, consider consulting doctor", color: .red, urgency: .critical))
        }
        if selectedSymptoms.contains(.palpitations) {
            insights.append(HealthInsight(icon: "waveform.path.ecg", title: "Heart Rhythm", description: "Palpitations with mood changes worth tracking", color: .red, urgency: .critical))
        }
        if selectedSymptoms.contains(.headache) {
            insights.append(HealthInsight(icon: "brain.head.profile", title: "Head Pain", description: "Consider hydration and rest", color: .purple, urgency: .moderate))
        }

        return insights
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Enhanced background with animated particles and gradients
                enhancedBackgroundView

                if toHome {
                    HomePageView(userId: currentUserId)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                } else {
                    mainContent
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }

                if showSuccessAnimation {
                    DebugSuccessAnimation()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSuccessAnimation = false
                            }
                        }
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: toHome)
        .alert("Error", isPresented: $showError) {
            Button("Retry", action: loadInitialData)
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            if !isDataLoaded {
                loadInitialData()
                startAnimations()

                // ENHANCED: Staggered card appearance animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                        cardAppearance = true
                    }
                }
            }
        }
        .environmentObject(userManager)
    }

    // MARK: - FIXED: Load Initial Data Method
    
    private func loadInitialData() {
        isLoading = true
        isDataLoaded = true
        
        // Load heart rate data
        fetchHeartRateForCorrelation()
        
        // Load saved mood/wellness data from backend
        loadSavedMoodWellnessData()
        
        // Load local entries for recent data
        recentEntries = loadLocalEntries()
        
        print("Loading initial data for user: \(currentUserId)")
    }
    
    // MARK: - NEW: Load Saved Mood/Wellness Data
    
    private func loadSavedMoodWellnessData() {
        guard let url = URL(string: "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare/mood_wellness.php?user_id=\(currentUserId)&type=latest") else {
            print("Invalid URL for loading mood wellness data")
            return
        }
        
        print("Loading saved mood/wellness data for user: \(currentUserId)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error loading mood wellness data: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data,
                      let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let status = jsonResponse["status"] as? String else {
                    print("Invalid response when loading mood wellness data")
                    return
                }
                
                if status.lowercased() == "success" {
                    // Parse mood data
                    if let moodString = jsonResponse["mood"] as? String,
                       let mood = MoodType.allCases.first(where: { $0.rawValue == moodString }) {
                        self.selectedMood = mood
                        print("Loaded mood: \(moodString)")
                    }
                    
                    // Parse symptoms data
                    if let symptomsArray = jsonResponse["symptoms"] as? [String] {
                        let loadedSymptoms = symptomsArray.compactMap { symptomString in
                            SymptomType.allCases.first(where: { $0.rawValue == symptomString })
                        }
                        self.selectedSymptoms = Set(loadedSymptoms)
                        print("Loaded symptoms: \(symptomsArray)")
                    }
                    
                    // Parse heart rate
                    if let heartRate = jsonResponse["heart_rate"] as? Int {
                        self.currentBPM = heartRate
                        print("Loaded heart rate: \(heartRate)")
                    }
                    
                    // Parse context note
                    if let note = jsonResponse["context_note"] as? String {
                        self.contextNote = note
                        print("Loaded context note: \(note)")
                    }
                    
                    // Parse timestamp
                    if let timestamp = jsonResponse["timestamp"] as? String {
                        self.lastUpdated = timestamp
                        print("Loaded timestamp: \(timestamp)")
                    }
                    
                    print("Successfully loaded saved mood/wellness data")
                } else {
                    print("No saved mood/wellness data found or error in response")
                }
            }
        }.resume()
    }

    // MARK: - Enhanced Background View

    private var enhancedBackgroundView: some View {
        ZStack {
            // ENHANCED: Multi-layer gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    selectedMood.color.opacity(0.03),
                    Color(.systemGray6).opacity(0.2),
                    selectedMood.color.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // ENHANCED: Animated mesh gradient overlay
            Rectangle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            selectedMood.color.opacity(0.08),
                            Color.clear,
                            selectedMood.color.opacity(0.04)
                        ]),
                        center: UnitPoint(x: 0.7, y: 0.3),
                        startRadius: 50,
                        endRadius: 300
                    )
                )
                .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                .opacity(pulseAnimation ? 0.6 : 0.3)
                .animation(
                    .easeInOut(duration: 4)
                    .repeatForever(autoreverses: true),
                    value: pulseAnimation
                )
                .ignoresSafeArea()

            // ENHANCED: Floating geometric shapes
            ForEach(0..<12, id: \.self) { index in
                let shapes = ["circle", "diamond", "hexagon"]
                let shape = shapes[index % shapes.count]

                GeometryReader { geometry in
                    ZStack {
                        if shape == "circle" {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            selectedMood.color.opacity(0.12),
                                            selectedMood.color.opacity(0.04),
                                            Color.clear
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        } else if shape == "diamond" {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            selectedMood.color.opacity(0.12),
                                            selectedMood.color.opacity(0.04),
                                            Color.clear
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .rotationEffect(Angle.degrees(45))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            selectedMood.color.opacity(0.12),
                                            selectedMood.color.opacity(0.04),
                                            Color.clear
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .frame(width: CGFloat.random(in: 30...70))
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                    .opacity(0.4)
                    .scaleEffect(floatingElements ? CGFloat.random(in: 0.6...1.4) : CGFloat.random(in: 0.8...1.2))
                    .rotationEffect(Angle.degrees(floatingElements ? Double.random(in: -45...45) : 0))
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...6))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: floatingElements
                    )
                }
            }
        }
    }

    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                // Enhanced Header with glassmorphism effect
                enhancedHeaderView
                    .opacity(cardAppearance ? 1 : 0)
                    .offset(y: cardAppearance ? 0 : -50)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1), value: cardAppearance)

                if isLoading {
                    enhancedLoadingView
                        .opacity(cardAppearance ? 1 : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: cardAppearance)
                } else {
                    // ENHANCED: All cards with staggered animations
                    Group {
                        // Mood Selection Card
                        enhancedMoodCard
                            .opacity(cardAppearance ? 1 : 0)
                            .offset(y: cardAppearance ? 0 : 30)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: cardAppearance)

                        // Symptoms Selection Card - FIXED text display
                        enhancedSymptomsCard
                            .opacity(cardAppearance ? 1 : 0)
                            .offset(y: cardAppearance ? 0 : 30)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3), value: cardAppearance)

                        // Heart rate correlation card
                        enhancedHeartRateCard
                            .opacity(cardAppearance ? 1 : 0)
                            .offset(y: cardAppearance ? 0 : 30)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.4), value: cardAppearance)

                        // Context Notes Card
                        enhancedContextNotesCard
                            .opacity(cardAppearance ? 1 : 0)
                            .offset(y: cardAppearance ? 0 : 30)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.5), value: cardAppearance)

                        // Dynamic insights section - MODIFIED: Automatically shown
                        enhancedDynamicInsightsSection
                            .opacity(cardAppearance ? 1 : 0)
                            .offset(y: cardAppearance ? 0 : 30)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.6), value: cardAppearance)

                        // Action buttons
                        enhancedActionButtons
                            .opacity(cardAppearance ? 1 : 0)
                            .offset(y: cardAppearance ? 0 : 30)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.7), value: cardAppearance)
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .refreshable {
            await refreshData()
        }
    }

    // MARK: - Enhanced UI Components

    private var enhancedHeaderView: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    toHome = true
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.9),
                                    Color.blue.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.white.opacity(0.4), Color.clear]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.blue.opacity(0.4), radius: 15, x: 0, y: 5)
                )
            }
            .buttonStyle(EnhancedButtonStyle())

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        selectedMood.color.opacity(0.3),
                                        selectedMood.color.opacity(0.1)
                                    ]),
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 30
                                )
                            )
                            .frame(width: 44, height: 44)
                            .scaleEffect(animateMood ? 1.15 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(), value: animateMood)

                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(selectedMood.color)
                            .scaleEffect(animateMood ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(), value: animateMood)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mood & Wellness")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("Track your mental health")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                if !lastUpdated.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.blue.opacity(0.5))
                        Text("Updated \(lastUpdated)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray5).opacity(0.8))
                            .overlay(
                                Capsule()
                                    .stroke(Color(.systemGray4), lineWidth: 0.5)
                            )
                    )
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 10)
    }

    private var enhancedLoadingView: some View {
        VStack(spacing: 32) {
            ZStack {
                // ENHANCED: Multiple animated rings with different speeds
                ForEach(0..<4) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    selectedMood.color.opacity(0.8),
                                    selectedMood.color.opacity(0.2),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(
                                lineWidth: CGFloat(4 - index),
                                lineCap: .round,
                                dash: [CGFloat(20 + index * 10), CGFloat(10)]
                            )
                        )
                        .frame(width: CGFloat(80 + index * 25))
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                        .scaleEffect(isLoading ? 1.1 : 0.9)
                        .opacity(isLoading ? 0.4 : 0.8)
                        .animation(
                            .linear(duration: Double(2 + index))
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.1),
                            value: isLoading
                        )
                }

                // Central brain icon with breathing effect
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    selectedMood.color.opacity(0.2),
                                    selectedMood.color.opacity(0.05)
                                ]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 40
                            )
                        )
                        .frame(width: 70, height: 70)
                        .scaleEffect(isLoading ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(), value: isLoading)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(selectedMood.color)
                        .scaleEffect(isLoading ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.2).repeatForever(), value: isLoading)
                }
            }

            VStack(spacing: 8) {
                Text("Loading your wellness data...")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Please wait while we restore your information")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 300)
        .padding(.vertical, 40)
        .padding(.horizontal, 32)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground),
                            selectedMood.color.opacity(0.02)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    selectedMood.color.opacity(0.3),
                                    selectedMood.color.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: selectedMood.color.opacity(0.2), radius: 25, x: 0, y: 12)
        )
    }

    private var enhancedMoodCard: some View {
        VStack(spacing: 28) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    selectedMood.color.opacity(0.3),
                                    selectedMood.color.opacity(0.1)
                                ]),
                                center: .center,
                                startRadius: 15,
                                endRadius: 30
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(selectedMood.color.opacity(0.4), lineWidth: 2)
                        )

                    Image(systemName: "face.smiling.inverse")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(selectedMood.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("How are you feeling?")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Select your current emotional state")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // ENHANCED: Mood selection grid with better spacing and animations
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 20) {
                ForEach(MoodType.allCases, id: \.self) { mood in
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            selectedMood = mood
                        }

                        // ENHANCED: Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    } label: {
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                mood.color.opacity(selectedMood == mood ? 0.4 : 0.1),
                                                mood.color.opacity(selectedMood == mood ? 0.2 : 0.05)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 68, height: 68)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        mood.color.opacity(selectedMood == mood ? 0.8 : 0.3),
                                                        mood.color.opacity(selectedMood == mood ? 0.4 : 0.1)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: selectedMood == mood ? 3 : 1.5
                                            )
                                    )
                                    .shadow(
                                        color: mood.color.opacity(selectedMood == mood ? 0.4 : 0.1),
                                        radius: selectedMood == mood ? 12 : 6,
                                        x: 0,
                                        y: selectedMood == mood ? 6 : 3
                                    )

                                Text(mood.emoji)
                                    .font(.system(size: 32))
                                    .scaleEffect(selectedMood == mood ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.4), value: selectedMood)

                                // ENHANCED: Selection indicator
                                if selectedMood == mood {
                                    Circle()
                                        .fill(mood.color.opacity(0.2))
                                        .frame(width: 78, height: 78)
                                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                                        .opacity(pulseAnimation ? 0.3 : 0.6)
                                        .animation(.easeInOut(duration: 1.5).repeatForever(), value: pulseAnimation)
                                }
                            }

                            Text(mood.rawValue)
                                .font(.system(
                                    size: selectedMood == mood ? 13 : 12,
                                    weight: selectedMood == mood ? .bold : .medium
                                ))
                                .foregroundColor(selectedMood == mood ? mood.color : .secondary)
                                .animation(.easeInOut(duration: 0.2), value: selectedMood)
                        }
                    }
                    .buttonStyle(EnhancedButtonStyle())
                }
            }
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground),
                            selectedMood.color.opacity(0.02)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    selectedMood.color.opacity(0.3),
                                    selectedMood.color.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: selectedMood.color.opacity(0.15), radius: 20, x: 0, y: 8)
        )
    }

    // FIXED: Enhanced Symptoms Card with proper text display
    private var enhancedSymptomsCard: some View {
        VStack(spacing: 28) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple.opacity(0.3),
                                    Color.purple.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.purple.opacity(0.4), lineWidth: 1.5)
                        )

                    Image(systemName: "stethoscope")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.purple)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Physical Symptoms")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Select any symptoms you're experiencing")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // FIXED: Symptoms grid with better text display
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 1), spacing: 16) {
                ForEach(SymptomType.allCases, id: \.self) { symptom in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            if selectedSymptoms.contains(symptom) {
                                selectedSymptoms.remove(symptom)
                            } else {
                                selectedSymptoms.insert(symptom)
                            }
                        }

                        // ENHANCED: Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    } label: {
                        HStack(spacing: 16) {
                            // Icon section
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                symptom.color.opacity(selectedSymptoms.contains(symptom) ? 0.4 : 0.15),
                                                symptom.color.opacity(selectedSymptoms.contains(symptom) ? 0.2 : 0.05)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(
                                                symptom.color.opacity(selectedSymptoms.contains(symptom) ? 0.6 : 0.3),
                                                lineWidth: selectedSymptoms.contains(symptom) ? 2 : 1
                                            )
                                    )
                                    .shadow(
                                        color: symptom.color.opacity(selectedSymptoms.contains(symptom) ? 0.3 : 0.1),
                                        radius: selectedSymptoms.contains(symptom) ? 8 : 4,
                                        x: 0,
                                        y: selectedSymptoms.contains(symptom) ? 4 : 2
                                    )

                                Image(systemName: symptom.icon)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(symptom.color)
                                    .scaleEffect(selectedSymptoms.contains(symptom) ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3), value: selectedSymptoms)
                            }

                            // Text content section - FIXED for better display
                            VStack(alignment: .leading, spacing: 6) {
                                Text(symptom.rawValue)
                                    .font(.system(
                                        size: 16,
                                        weight: selectedSymptoms.contains(symptom) ? .bold : .semibold
                                    ))
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text(symptom.description)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Spacer()

                            // Selection indicator
                            ZStack {
                                Circle()
                                    .fill(symptom.color.opacity(selectedSymptoms.contains(symptom) ? 0.2 : 0.05))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                symptom.color.opacity(selectedSymptoms.contains(symptom) ? 0.8 : 0.3),
                                                lineWidth: selectedSymptoms.contains(symptom) ? 2.5 : 1.5
                                            )
                                    )

                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(symptom.color)
                                    .scaleEffect(selectedSymptoms.contains(symptom) ? 1.0 : 0.0)
                                    .opacity(selectedSymptoms.contains(symptom) ? 1 : 0)
                                    .animation(.spring(response: 0.4), value: selectedSymptoms)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            selectedSymptoms.contains(symptom) ? symptom.color.opacity(0.08) : Color(.systemGray6).opacity(0.5),
                                            selectedSymptoms.contains(symptom) ? symptom.color.opacity(0.04) : Color(.systemGray6).opacity(0.3)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(
                                            selectedSymptoms.contains(symptom) ?
                                            symptom.color.opacity(0.4) : Color(.systemGray4).opacity(0.6),
                                            lineWidth: selectedSymptoms.contains(symptom) ? 1.5 : 1
                                        )
                                )
                                .shadow(
                                    color: selectedSymptoms.contains(symptom) ?
                                    symptom.color.opacity(0.2) : Color.black.opacity(0.05),
                                    radius: selectedSymptoms.contains(symptom) ? 8 : 4,
                                    x: 0,
                                    y: selectedSymptoms.contains(symptom) ? 4 : 2
                                )
                        )
                        .scaleEffect(selectedSymptoms.contains(symptom) ? 1.02 : 1.0)
                        .animation(.spring(response: 0.4), value: selectedSymptoms)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 26)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground),
                            Color.purple.opacity(0.02)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple.opacity(0.3),
                                    Color.purple.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .purple.opacity(0.15), radius: 20, x: 0, y: 8)
        )
    }

    private var enhancedHeartRateCard: some View {
        HStack(spacing: 24) {
            ZStack {
                // ENHANCED: Multi-layer heart animation
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.red.opacity(0.3),
                                Color.red.opacity(0.05)
                            ]),
                            center: .center,
                            startRadius: 20,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(animateHeartbeat ? 1.15 : 1.0)
                    .opacity(animateHeartbeat ? 0.8 : 0.6)
                    .animation(.easeInOut(duration: 0.8).repeatForever(), value: animateHeartbeat)

                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.red.opacity(0.2),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 35
                        )
                    )
                    .frame(width: 60, height: 60)
                    .scaleEffect(animateHeartbeat ? 1.3 : 1.0)
                    .opacity(animateHeartbeat ? 0.4 : 0.8)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(0.1), value: animateHeartbeat)

                Image(systemName: "heart.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.red)
                    .scaleEffect(animateHeartbeat ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(), value: animateHeartbeat)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("Heart Rate")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)

                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 14))
                        .foregroundColor(.red.opacity(0.7))
                }

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(currentBPM)")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())

                    Text("BPM")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Text("Correlated with mood data")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.green.opacity(0.5))
            }

            Spacer()

            // ENHANCED: Heart rate status with better visual design
            VStack(spacing: 12) {
                enhancedHeartRateStatus

                VStack(spacing: 4) {
                    Image(systemName: heartRateTrendIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(heartRateColor)

                    Text("Trend")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 28)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground),
                            Color.red.opacity(0.02)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.red.opacity(0.3),
                                    Color.red.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .red.opacity(0.15), radius: 20, x: 0, y: 8)
        )
    }

    private var enhancedContextNotesCard: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.indigo.opacity(0.3),
                                    Color.indigo.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.indigo.opacity(0.4), lineWidth: 1.5)
                        )

                    Image(systemName: "note.text")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.indigo)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Context Notes")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Add any relevant context (optional)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // ENHANCED: Better text field design
            VStack(spacing: 12) {
                TextField("What's happening today? Any triggers or events?", text: $contextNote, axis: .vertical)
                    .font(.system(size: 16))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .lineLimit(3...6)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6).opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        contextNote.isEmpty ? Color(.systemGray4) : Color.indigo.opacity(0.6),
                                        lineWidth: contextNote.isEmpty ? 1 : 1.5
                                    )
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: contextNote.isEmpty)

                HStack {
                    Spacer()
                    Text("\(contextNote.count)/300")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red.opacity(0.5))
                }
            }
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 26)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground),
                            Color.indigo.opacity(0.02)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.indigo.opacity(0.3),
                                    Color.indigo.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .indigo.opacity(0.15), radius: 20, x: 0, y: 8)
        )
    }

    private var enhancedHeartRateStatus: some View {
        VStack(spacing: 8) {
            Text(heartRateCategory)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(heartRateColor)

            Circle()
                .fill(heartRateColor)
                .frame(width: 12, height: 12)
                .scaleEffect(pulseAnimation ? 1.5 : 1.0)
                .opacity(pulseAnimation ? 0.6 : 1.0)
                .animation(.easeInOut(duration: 1).repeatForever(), value: pulseAnimation)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(heartRateColor.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(heartRateColor.opacity(0.4), lineWidth: 1)
                )
        )
    }

    // MARK: - MODIFIED: Auto-Showing Dynamic Insights Section

    private var enhancedDynamicInsightsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan.opacity(0.4),
                                    Color.cyan.opacity(0.1)
                                ]),
                                center: .center,
                                startRadius: 15,
                                endRadius: 30
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(Color.cyan.opacity(0.5), lineWidth: 1.5)
                        )

                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.cyan)
                        .font(.system(size: 22, weight: .medium))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Wellness Insights")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Automatically generated based on your selections")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // MODIFIED: Status indicator instead of toggle button
                if shouldShowInsights {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.green.opacity(0.4), lineWidth: 1.5)
                            )

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
            }

            // MODIFIED: Show insights automatically when conditions are met
            if shouldShowInsights {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 18) {
                    ForEach(Array(dynamicInsights.enumerated()), id: \.offset) { index, insight in
                        enhancedInsightCard(insight: insight, index: index)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 0.9).combined(with: .opacity)
                            ))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: shouldShowInsights)
                    }
                }
            } else {
                // Show placeholder when no insights to display
                VStack(spacing: 16) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.cyan.opacity(0.3))
                    
                    VStack(spacing: 8) {
                        Text("Select a mood or symptoms")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text("Insights will appear automatically based on your selections")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.easeInOut(duration: 0.4), value: shouldShowInsights)
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 26)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground),
                            Color.cyan.opacity(0.02)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan.opacity(0.3),
                                    Color.cyan.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .cyan.opacity(0.15), radius: 20, x: 0, y: 8)
        )
        .animation(.easeInOut(duration: 0.4), value: shouldShowInsights)
    }

    private func enhancedInsightCard(insight: HealthInsight, index: Int) -> some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    insight.color.opacity(0.25),
                                    insight.color.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(insight.color.opacity(0.4), lineWidth: 1.5)
                        )

                    Image(systemName: insight.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(insight.color)
                }

                Spacer()

                enhancedUrgencyIndicator(for: insight.urgency)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(insight.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(insight.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            insight.color.opacity(0.06),
                            insight.color.opacity(0.02)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    insight.color.opacity(0.3),
                                    insight.color.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: insight.color.opacity(0.15), radius: 12, x: 0, y: 6)
        )
        .scaleEffect(cardAppearance && animateMood ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 3).delay(Double(index) * 0.3), value: animateMood)
    }

    private func enhancedUrgencyIndicator(for urgency: InsightUrgency) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<urgency.dots, id: \.self) { dotIndex in
                Circle()
                    .fill(urgency.color)
                    .frame(width: 6, height: 6)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.8)
                        .repeatForever()
                        .delay(Double(dotIndex) * 0.2),
                        value: pulseAnimation
                    )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(urgency.color.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(urgency.color.opacity(0.4), lineWidth: 1)
                )
        )
    }

    private var enhancedActionButtons: some View {
        VStack(spacing: 20) {
            Button(action: {
                saveMoodSymptomEntryLocally()
                saveMoodSymptomEntryToBackend()
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                        }
                    }
                    .frame(width: 24, height: 24)

                    Text(isLoading ? "Saving Entry..." : "Save Wellness Entry")
                        .font(.system(size: 18, weight: .bold))
                        .animation(.easeInOut(duration: 0.2), value: isLoading)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    selectedMood.color.opacity(0.9),
                                    selectedMood.color.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: selectedMood.color.opacity(0.4), radius: 20, x: 0, y: 10)
                )
                .foregroundColor(.white)
            }
            .disabled(isLoading)
            .buttonStyle(EnhancedButtonStyle())
            .scaleEffect(isLoading ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isLoading)
        }
    }

    // MARK: - Computed Properties

    private var heartRateColor: Color {
        switch currentBPM {
        case ..<60: return .blue
        case 60...100: return .green
        case 101...120: return .orange
        default: return .red
        }
    }

    private var heartRateCategory: String {
        switch currentBPM {
        case ..<60: return "Low"
        case 60...100: return "Normal"
        case 101...120: return "Elevated"
        default: return "High"
        }
    }

    private var heartRateTrendIcon: String {
        switch currentBPM {
        case ..<60: return "arrow.down"
        case 60...100: return "minus"
        case 101...120: return "arrow.up"
        default: return "arrow.up.right"
        }
    }

    // MARK: - Helper Methods

    private func startAnimations() {
        animateMood = true
        animateHeartbeat = true
        pulseAnimation = true
        floatingElements = true
    }

    // MARK: - LOCAL STORAGE Methods (Frontend-Only)

    private func saveMoodSymptomEntryLocally() {
        isLoading = true

        let entry = MoodWellnessEntry(
            userId: currentUserId,
            mood: selectedMood,
            symptoms: Array(selectedSymptoms),
            heartRate: currentBPM,
            contextNote: contextNote,
            timestamp: Date()
        )

        var entries = loadLocalEntries()
        entries.append(entry)

        if entries.count > 100 {
            entries = Array(entries.suffix(100))
        }

        do {
            let encodedData = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(encodedData, forKey: "moodEntries_\(currentUserId)")

            DispatchQueue.main.async {
                self.isLoading = false
                self.lastUpdated = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
                self.showSuccessAnimation = true

                NotificationCenter.default.post(name: NSNotification.Name("MoodEntryAdded"), object: nil)

                // ENHANCED: Better haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()

                print("Mood entry saved locally successfully")
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.showError(message: "Failed to save entry locally")
            }
        }
    }
    
    private func saveMoodSymptomEntryToBackend() {
        guard let url = URL(string: "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare/mood_wellness.php") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let symptomsArray = Array(selectedSymptoms).map { $0.rawValue }
        let postData: [String: Any] = [
            "user_id": currentUserId,
            "mood": selectedMood.rawValue,
            "symptoms": symptomsArray,
            "heart_rate": currentBPM,
            "context_note": contextNote
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: postData)
        } catch {
            showError(message: "Failed to encode data")
            return
        }
        
        isLoading = true
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.showError(message: "Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data,
                      let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let status = response["status"] as? String else {
                    self.showError(message: "Invalid response from server")
                    return
                }
                
                if status.lowercased() == "success" {
                    self.lastUpdated = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
                    self.showSuccessAnimation = true
                    
                    // Enhanced haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    print("Mood entry saved successfully to backend")
                } else {
                    let msg = response["message"] as? String ?? "Unknown error"
                    self.showError(message: msg)
                }
            }
        }.resume()
    }

    private func loadLocalEntries() -> [MoodWellnessEntry] {
        guard let data = UserDefaults.standard.data(forKey: "moodEntries_\(currentUserId)"),
              let entries = try? JSONDecoder().decode([MoodWellnessEntry].self, from: data) else {
            return []
        }
        return entries
    }

    // MARK: - Backend Methods (Heart Rate Only)

    private func fetchHeartRateForCorrelation() {
        guard let url = URL(string: "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare/heartbeat.php?user_id=\(currentUserId)&type=latest") else { return }

        print("Fetching heart rate for mood correlation for user ID: \(currentUserId)")
        isLoading = true
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.showError(message: "Failed to fetch heart rate: \(error.localizedDescription)")
                    return
                }

                guard let data = data,
                      let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let status = response["status"] as? String else {
                    self.showError(message: "Invalid response from server")
                    return
                }

                if status.lowercased() == "success" {
                    self.currentBPM = response["bpm"] as? Int ?? 0
                    self.lastUpdated = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
                } else {
                    let msg = response["message"] as? String ?? "Unknown error"
                    self.showError(message: msg)
                }
            }
        }.resume()
    }

    // MARK: - FIXED: Refresh Data Method
    
    private func refreshData() async {
        await withCheckedContinuation { continuation in
            // Reset the data loaded flag to force reload
            isDataLoaded = false
            
            // Reload all data
            loadInitialData()
            
            // Load recent entries
            recentEntries = loadLocalEntries()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                continuation.resume()
            }
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Supporting Data Models

struct HealthInsight {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let urgency: InsightUrgency
}

enum InsightUrgency {
    case positive, neutral, moderate, critical

    var color: Color {
        switch self {
        case .positive: return .green
        case .neutral: return .blue
        case .moderate: return .orange
        case .critical: return .red
        }
    }

    var dots: Int {
        switch self {
        case .positive: return 1
        case .neutral: return 1
        case .moderate: return 2
        case .critical: return 3
        }
    }
}

// MARK: - Enhanced Success Animation

struct DebugSuccessAnimation: View {
    @State private var animateCheckmark = false
    @State private var animateGlow = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    // ENHANCED: Animated glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.green.opacity(0.3),
                                    Color.green.opacity(0.1),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateGlow ? 1.5 : 1.0)
                        .opacity(animateGlow ? 0.4 : 0.8)
                        .animation(.easeInOut(duration: 2).repeatForever(), value: animateGlow)

                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(.green)
                        .scaleEffect(animateCheckmark ? 1.2 : 1.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateCheckmark)

            
                }

                VStack(spacing: 12) {
                    Text("Entry Saved!")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.red.opacity(0.75))

                    Text("Your mood and wellness data has been recorded")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground).opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: .green.opacity(0.3), radius: 30, x: 0, y: 15)
            )
        }
        .onAppear {
            animateCheckmark = true
            animateGlow = true
        }
    }
}

// MARK: - Enhanced Custom Button Style

struct EnhancedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct BloodSugarView_Previews: PreviewProvider {
    static var previews: some View {
        BloodSugarView()
            .environmentObject(UserManager.shared)
    }
}
