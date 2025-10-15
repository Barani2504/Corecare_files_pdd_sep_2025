import SwiftUI
import AVFoundation

struct BreatheView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var isPaused = false
    @State private var timeRemaining = 298 // 4:58
    @State private var isMuted = false
    @State private var breatheText = "Breathe in..."
    @State private var timer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var breathingScale: CGFloat = 1.0
    @State private var breathingAnimation: Timer?

    @State private var goToAI = false
    @State private var goToHome = false
    
    // Enhanced completion tracking
    @State private var showCompletionAlert = false
    @State private var sessionCompleted = false
    @State private var sessionEndedEarly = false
    
    // Completion callback for AIView communication
    var onSessionComplete: ((Bool) -> Void)? // Bool indicates if completed successfully
    var onSessionEnd: (() -> Void)? // Callback for ending session early
    
    // Computed property to get current user ID
    private var currentUserId: Int {
        return userManager.currentUserId ?? 0
    }

    var body: some View {
        ZStack {
            // Enhanced gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.9, green: 0.95, blue: 0.98),
                    Color(red: 1.0, green: 0.96, blue: 0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if goToAI {
                AIView()
                    .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
                    .animation(.easeInOut(duration: 0.4), value: goToAI)
            } else if goToHome {
                HomePageView(userId: currentUserId)
                    .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
                    .animation(.easeInOut(duration: 0.4), value: goToHome)
            } else {
                mainContent
                    .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
                    .animation(.easeInOut(duration: 0.4), value: goToAI || goToHome)
            }
        }
        .environmentObject(userManager)
        .alert("Session Complete! 🎉", isPresented: $showCompletionAlert) {
            Button("Return to Analysis") {
                handleSessionCompletion(completed: true, checkHeartRate: false)
            }
            Button("Go Home") {
                handleSessionCompletion(completed: true, checkHeartRate: false, goHome: true)
            }
        } message: {
            if sessionCompleted {
                Text("Great job! Your 5-minute breathing session is complete. Would you like to check your heart rate to see the improvement?")
            } else {
                Text("Your breathing session ended early. Consider checking your heart rate or returning to stress analysis for better health monitoring.")
            }
        }
    }

    var mainContent: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Enhanced Header
                    HStack {
                        Button {
                            handleEarlySessionEnd()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.7))
                                    .frame(width: 36, height: 36)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.black.opacity(0.8))
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }

                        Spacer()
                        
                        VStack(spacing: 2) {
                            Text("Breathing Exercise")
                                .font(.system(size: min(20, geometry.size.width * 0.055), weight: .bold, design: .rounded))
                                .foregroundColor(.black.opacity(0.9))
                            
                            Text("Mindful Meditation")
                                .font(.system(size: min(12, geometry.size.width * 0.032), weight: .medium))
                                .foregroundColor(.orange.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // Music control button
                        Button {
                            isMuted.toggle()
                            if isMuted {
                                audioPlayer?.pause()
                            } else {
                                audioPlayer?.play()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.7))
                                    .frame(width: 36, height: 36)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                
                                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .foregroundColor(.orange.opacity(0.9))
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                    }
                    .padding(.top, max(10, geometry.safeAreaInsets.top + 10))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 15)

                    // Enhanced subtitle
                    VStack(spacing: 5) {
                        Text("Let's calm your heart with a")
                            .font(.system(size: min(16, geometry.size.width * 0.042), weight: .regular, design: .rounded))
                            .foregroundColor(.black.opacity(0.7))
                        
                        Text("5-minute guided session")
                            .font(.system(size: min(16, geometry.size.width * 0.042), weight: .semibold, design: .rounded))
                            .foregroundColor(.orange.opacity(0.9))
                    }
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)

                    // Enhanced Breathing Animation with floating particles
                    ZStack {
                        // Floating particles background
                        ForEach(0..<6, id: \.self) { index in
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 4, height: 4)
                                .offset(
                                    x: CGFloat.random(in: -60...60),
                                    y: CGFloat.random(in: -60...60)
                                )
                                .scaleEffect(breathingScale * 0.8)
                                .animation(
                                    Animation.easeInOut(duration: 4.0)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.2),
                                    value: breathingScale
                                )
                        }
                        
                        // Enhanced ripple circles
                        ForEach(1..<4) { i in
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.orange.opacity(Double(5 - i) * 0.15),
                                            Color.pink.opacity(Double(5 - i) * 0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                                .frame(width: CGFloat(i * 50 + 80), height: CGFloat(i * 50 + 80))
                                .scaleEffect(breathingScale)
                                .opacity(isPaused ? 0.5 : 1.0)
                                .animation(
                                    Animation.easeInOut(duration: 4.0)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.3),
                                    value: breathingScale
                                )
                        }

                        // Enhanced center circle
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.orange.opacity(0.3),
                                            Color.pink.opacity(0.2),
                                            Color.yellow.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: min(150, geometry.size.width * 0.4),
                                       height: min(150, geometry.size.width * 0.4))
                                .scaleEffect(breathingScale)
                                .shadow(color: .orange.opacity(0.3), radius: 15, x: 0, y: 0)
                            
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                .frame(width: min(150, geometry.size.width * 0.4),
                                       height: min(150, geometry.size.width * 0.4))
                                .scaleEffect(breathingScale)
                            
                            VStack(spacing: 6) {
                                Text(breatheText)
                                    .font(.system(size: min(18, geometry.size.width * 0.048), weight: .semibold, design: .rounded))
                                    .foregroundColor(.black.opacity(0.8))
                                
                                Circle()
                                    .fill(Color.orange.opacity(0.6))
                                    .frame(width: 6, height: 6)
                                    .scaleEffect(breathingScale * 0.8)
                            }
                        }
                        .animation(
                            Animation.easeInOut(duration: 4.0)
                                .repeatForever(autoreverses: true),
                            value: breathingScale
                        )
                    }
                    .frame(height: min(220, geometry.size.height * 0.3))
                    .padding(.bottom, 25)

                    // Enhanced Time Display
                    VStack(spacing: 8) {
                        Text("\(timeString(from: timeRemaining))")
                            .font(.system(size: min(28, geometry.size.width * 0.08), weight: .bold, design: .rounded))
                            .foregroundColor(.black.opacity(0.9))
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        Text("remaining")
                            .font(.system(size: min(14, geometry.size.width * 0.037), weight: .medium))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    .padding(.bottom, 20)

                    // Enhanced Progress Bar
                    VStack(spacing: 8) {
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 6)
                                .frame(height: 8)
                                .foregroundColor(Color.white.opacity(0.5))
                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                            
                            // Progress fill
                            RoundedRectangle(cornerRadius: 6)
                                .frame(
                                    width: (geometry.size.width - 80) * CGFloat((300 - timeRemaining)) / 300,
                                    height: 8
                                )
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.orange, Color.pink]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                )
                                .shadow(color: .orange.opacity(0.4), radius: 4, x: 0, y: 2)
                        }
                        .frame(height: 8)
                        .padding(.horizontal, 40)
                        
                        // Progress percentage
                        Text("\(Int((300 - timeRemaining) * 100 / 300))% Complete")
                            .font(.system(size: min(12, geometry.size.width * 0.032), weight: .medium))
                            .foregroundColor(.black.opacity(0.5))
                    }
                    .padding(.bottom, 25)

                    // Enhanced Control Button
                    Button(action: togglePause) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.orange,
                                            Color.orange.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 65, height: 65)
                                .shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 4)
                            
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                .frame(width: 65, height: 65)
                            
                            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 22, weight: .medium))
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        }
                        .scaleEffect(isPaused ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPaused)
                    }
                    .padding(.bottom, 20)

                    // Enhanced End Session Button
                    Button {
                        handleEarlySessionEnd()
                    } label: {
                        HStack(spacing: 8) {
                            Text("End Session")
                                .font(.system(size: min(16, geometry.size.width * 0.042), weight: .semibold, design: .rounded))
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: min(14, geometry.size.width * 0.037), weight: .medium))
                        }
                        .foregroundColor(.orange.opacity(0.9))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                                .background(Color.white.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        )
                    }
                    .padding(.bottom, max(20, geometry.safeAreaInsets.bottom + 20))
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .onAppear {
            startTimer()
            setupAudio()
            startBreathingAnimation()
        }
        .onDisappear {
            cleanupSession()
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Enhanced Session Management
    
    func handleEarlySessionEnd() {
        sessionEndedEarly = true
        sessionCompleted = false
        stopAudio()
        cleanupTimers()
        
        // Call the session end callback to notify AIView
        onSessionEnd?()
        
        // Show completion alert with options
        showCompletionAlert = true
    }
    
    func handleNaturalSessionCompletion() {
        sessionCompleted = true
        sessionEndedEarly = false
        
        // Add completion haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Call the completion callback
        onSessionComplete?(true)
        
        // Show completion alert
        showCompletionAlert = true
    }
    
    func handleSessionCompletion(completed: Bool, checkHeartRate: Bool, goHome: Bool = false) {
        if checkHeartRate {
            // Return to AIView for heart rate check
            withAnimation(.easeInOut(duration: 0.4)) {
                goToAI = true
            }
        } else if goHome {
            // Go directly to home page
            withAnimation(.easeInOut(duration: 0.3)) {
                goToHome = true
            }
        } else {
            // Return to AIView for analysis
            withAnimation(.easeInOut(duration: 0.4)) {
                goToAI = true
            }
        }
    }
    
    func cleanupSession() {
        cleanupTimers()
        stopAudio()
    }
    
    func cleanupTimers() {
        timer?.invalidate()
        timer = nil
        breathingAnimation?.invalidate()
        breathingAnimation = nil
    }

    // MARK: - Timer and Animation Management

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            cleanupTimers()
            audioPlayer?.pause()
        } else {
            startTimer()
            startBreathingAnimation()
            if !isMuted {
                audioPlayer?.play()
            }
        }
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                breatheText = timeRemaining % 6 < 3 ? "Breathe in..." : "Breathe out..."
            } else {
                // Session completed naturally
                cleanupTimers()
                stopAudio()
                handleNaturalSessionCompletion()
            }
        }
    }
    
    func startBreathingAnimation() {
        breathingAnimation = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 2.0)) {
                breathingScale = timeRemaining % 6 < 3 ? 1.2 : 0.8
            }
        }
    }
    
    // MARK: - Audio Management
    
    func setupAudio() {
        // Create a URL for breathing exercise music
        if let path = Bundle.main.path(forResource: "breathing_music", ofType: "mp3") {
            let url = URL(fileURLWithPath: path)
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1 // Loop indefinitely
                audioPlayer?.volume = 0.5
                if !isMuted {
                    audioPlayer?.play()
                }
            } catch {
                print("Error setting up audio: \(error)")
            }
        } else {
            // Fallback: Generate a simple tone using system sounds
            generateBreathingTone()
        }
    }
    
    func generateBreathingTone() {
        // Placeholder for breathing tone generation
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    func timeString(from seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Enhanced BreatheView with Callbacks

struct EnhancedBreatheView: View {
    @EnvironmentObject var userManager: UserManager
    
    let onSessionComplete: ((Bool) -> Void)?
    let onSessionEnd: (() -> Void)?
    
    var body: some View {
        BreatheView()
            .environmentObject(userManager)
    }
}

#Preview {
    BreatheView()
        .environmentObject(UserManager.shared)
}
