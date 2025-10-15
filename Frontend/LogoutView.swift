import SwiftUI

struct LogoutView: View {
    @EnvironmentObject var userManager: UserManager
    
    enum Route {
        case userDetails
        case content
        case logout
    }

    @State private var route: Route = .logout
    @State private var isLoggingOut = false
    @State private var animateElements = false
    @State private var pulseAnimation = false
    @State private var backgroundAnimation = false
    
    var body: some View {
        ZStack {
            switch route {
            case .logout:
                logoutScreen
                    .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
            case .userDetails:
                UserDetailsView(userId: userManager.currentUserId ?? -1)
                    .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
                    .environmentObject(userManager)
            case .content:
                ContentView()
                    .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
            }
            
            // Enhanced loading overlay during logout
            if isLoggingOut {
                EnhancedLoadingOverlay()
            }
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: route)
        .onAppear {
            // Verify user is logged in
            print("LogoutView appeared - User logged in: \(userManager.isLoggedIn)")
            print("LogoutView appeared - User ID: \(userManager.currentUserId ?? -1)")
            
            // Start animations
            withAnimation(.easeInOut(duration: 1.0)) {
                animateElements = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever()) {
                pulseAnimation = true
                backgroundAnimation = true
            }
        }
    }

    var logoutScreen: some View {
        GeometryReader { geometry in
            ZStack {
                // Enhanced medical background with animated elements
                enhancedMedicalBackground
                    .ignoresSafeArea()
                
                // Floating medical icons
                floatingMedicalElements(geometry: geometry)
                    .ignoresSafeArea()
                
                // Main content
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer().frame(height: max(60, geometry.safeAreaInsets.top + 20))

                        // Enhanced header section
                        enhancedHeaderSection
                            .opacity(animateElements ? 1.0 : 0.0)
                            .offset(y: animateElements ? 0 : -30)
                            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: animateElements)

                        // Enhanced user info section
                        enhancedUserInfoSection
                            .opacity(animateElements ? 1.0 : 0.0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4), value: animateElements)

                        // Enhanced info message section
                        enhancedInfoMessageSection
                            .opacity(animateElements ? 1.0 : 0.0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.6), value: animateElements)

                        Spacer().frame(minHeight: 40)

                        // Enhanced action buttons
                        enhancedActionButtons
                            .opacity(animateElements ? 1.0 : 0.0)
                            .offset(y: animateElements ? 0 : 30)
                            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.8), value: animateElements)

                        Spacer().frame(height: 40)

                        // Enhanced logo section
                        enhancedLogoSection
                            .opacity(animateElements ? 1.0 : 0.0)
                            .scaleEffect(animateElements ? 1.0 : 0.9)
                            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(1.0), value: animateElements)

                        Spacer().frame(height: max(40, geometry.safeAreaInsets.bottom + 20))
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }
    
    // MARK: - Enhanced UI Components
    
    private var enhancedMedicalBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.96, green: 0.97, blue: 1.0),
                    Color(red: 0.94, green: 0.96, blue: 0.99),
                    Color(red: 0.92, green: 0.95, blue: 0.98)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Medical pattern overlay
            Canvas { context, size in
                let gridSize: CGFloat = 50
                let crossSize: CGFloat = 8
                
                for x in stride(from: 0, to: size.width, by: gridSize) {
                    for y in stride(from: 0, to: size.height, by: gridSize) {
                        let opacity = sin(x / 100) * cos(y / 100) * 0.1 + 0.05
                        
                        // Draw medical cross
                        let crossColor = Color.blue.opacity(opacity)
                        let horizontalRect = CGRect(x: x, y: y - 1, width: crossSize, height: 2)
                        let verticalRect = CGRect(x: x + crossSize/2 - 1, y: y - crossSize/2, width: 2, height: crossSize)
                        
                        context.fill(Path(horizontalRect), with: .color(crossColor))
                        context.fill(Path(verticalRect), with: .color(crossColor))
                    }
                }
            }
            
            // Animated pulse circles
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        Color.blue.opacity(0.1),
                        lineWidth: 2
                    )
                    .frame(width: CGFloat(200 + index * 100))
                    .scaleEffect(backgroundAnimation ? 1.2 : 0.8)
                    .opacity(backgroundAnimation ? 0.3 : 0.1)
                    .animation(
                        .easeInOut(duration: 3.0)
                        .repeatForever()
                        .delay(Double(index) * 0.5),
                        value: backgroundAnimation
                    )
                    .position(x: UIScreen.main.bounds.width * 0.7, y: UIScreen.main.bounds.height * 0.3)
            }
        }
    }
    
    private func floatingMedicalElements(geometry: GeometryProxy) -> some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Image(systemName: medicalIcons[index % medicalIcons.count])
                    .font(.system(size: CGFloat.random(in: 15...25), weight: .light))
                    .foregroundColor(medicalIconColors[index % medicalIconColors.count])
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                    .opacity(0.15)
                    .scaleEffect(backgroundAnimation ? 1.1 : 0.9)
                    .rotationEffect(.degrees(backgroundAnimation ? 360 : 0))
                    .animation(
                        .linear(duration: Double.random(in: 20...30))
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.5),
                        value: backgroundAnimation
                    )
            }
        }
    }
    
    private var medicalIcons: [String] {
        ["heart.fill", "cross.fill", "pills.fill", "stethoscope",
         "medical.thermometer.fill", "bandage.fill", "syringe.fill", "lungs.fill"]
    }
    
    private var medicalIconColors: [Color] {
        [Color.red.opacity(0.3), Color.blue.opacity(0.3), Color.green.opacity(0.3),
         Color.orange.opacity(0.3), Color.purple.opacity(0.3), Color.pink.opacity(0.3)]
    }
    
    private var enhancedHeaderSection: some View {
        VStack(spacing: 16) {
            // Medical logout icon with animation
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.red.opacity(0.2),
                                Color.red.opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(), value: pulseAnimation)
                
                Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.red)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(), value: pulseAnimation)
            }
            
            Text("Log out from Core Care")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.1098, green: 0.3059, blue: 0.6039),
                            Color(red: 0.2, green: 0.4, blue: 0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .multilineTextAlignment(.center)
                .shadow(color: Color.blue.opacity(0.3), radius: 2, x: 0, y: 1)
        }
    }
    
    private var enhancedUserInfoSection: some View {
        VStack(spacing: 16) {
            Text("Are you sure you want to\nlog out?")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            // Enhanced user info card
            if let userData = userManager.userData {
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Currently logged in as:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(userData.emailOrPhone)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(color: Color.blue.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
    }
    
    private var enhancedInfoMessageSection: some View {
        VStack(spacing: 20) {
            // Medical security card
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Text("🩺")
                        .font(.system(size: 24))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Medical Data Security")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Your medical data will remain secure and encrypted. You'll need to log in again to access your cardiac health information.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.green.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1.5)
                    )
            )
            .shadow(color: Color.green.opacity(0.1), radius: 10, x: 0, y: 5)
            
            // Additional security features
            HStack(spacing: 24) {
                securityFeatureItem(icon: "lock.shield.fill", text: "Data Protected", color: .blue)
                securityFeatureItem(icon: "key.fill", text: "Encrypted", color: .orange)
            }
            .padding(.horizontal)
        }
    }
    
    private func securityFeatureItem(icon: String, text: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var enhancedActionButtons: some View {
        VStack(spacing: 16) {
            // Enhanced logout button
            Button(action: {
                performLogout()
            }) {
                HStack(spacing: 12) {
                    if isLoggingOut {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    Text(isLoggingOut ? "Logging out..." : "Log Out Securely")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: isLoggingOut ?
                                    [Color.gray, Color.gray.opacity(0.8)] :
                                    [Color.red, Color.red.opacity(0.8)]
                                ),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: isLoggingOut ? Color.gray.opacity(0.4) : Color.red.opacity(0.4),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                )
            }
            .disabled(isLoggingOut)
            .scaleEffect(isLoggingOut ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isLoggingOut)
            
            // Enhanced cancel button
            Button(action: {
                print("LogoutView: Cancel button tapped, navigating back to UserDetails")
                route = .userDetails
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Cancel & Stay Logged In")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black,
                                    Color.black.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
                )
            }
            .disabled(isLoggingOut)
            .scaleEffect(isLoggingOut ? 0.95 : 1.0)
            .opacity(isLoggingOut ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isLoggingOut)
        }
        .padding(.horizontal, 4)
    }
    
    private var enhancedLogoSection: some View {
        VStack(spacing: 12) {
            // Enhanced logo with medical frame
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 240, height: 80)
                    .shadow(color: Color.blue.opacity(0.1), radius: 15, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.3),
                                        Color.blue.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                
                Image("corecarelogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 60)
            }
            .scaleEffect(pulseAnimation ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 3.0).repeatForever(), value: pulseAnimation)
            
            Text("Stay healthy, stay connected")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .italic()
        }
    }
    
    // MARK: - Enhanced Logout Function (Unchanged Logic)
    private func performLogout() {
        guard userManager.isLoggedIn else {
            print("LogoutView: User is not logged in, redirecting to content")
            route = .content
            return
        }
        
        print("LogoutView: Starting logout process for user ID: \(userManager.currentUserId ?? -1)")
        isLoggingOut = true
        
        // Perform logout with a small delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Store user info for logging before clearing
            let loggedOutUserId = self.userManager.currentUserId
            let loggedOutEmail = self.userManager.userData?.emailOrPhone
            
            // Call UserManager logout - this clears all user data and UserDefaults
            self.userManager.logout()
            
            // Verify logout was successful
            if !self.userManager.isLoggedIn && self.userManager.userData == nil {
                print("LogoutView: Successfully logged out user ID: \(loggedOutUserId ?? -1), Email: \(loggedOutEmail ?? "unknown")")
            } else {
                print("LogoutView: Warning - Logout may not have completed successfully")
            }
            
            // Clear any additional app storage that might not be handled by UserManager
            UserDefaults.standard.removeObject(forKey: "userName")
            UserDefaults.standard.removeObject(forKey: "lastLoginDate")
            
            // Reset loading state and navigate
            self.isLoggingOut = false
            
            print("LogoutView: Logout completed, navigating to ContentView")
            self.route = .content
        }
    }
}

// MARK: - Enhanced Loading Overlay Component
struct EnhancedLoadingOverlay: View {
    @State private var rotationAngle: Double = 0
    @State private var scaleEffect: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.3
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { }
            
            VStack(spacing: 24) {
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.red.opacity(0.2), lineWidth: 6)
                        .frame(width: 80, height: 80)
                        .scaleEffect(scaleEffect)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: scaleEffect)
                    
                    // Inner ring
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    // Rotating logout icon
                    Circle()
                        .trim(from: 0.0, to: 0.8)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color.red,
                                    Color.blue,
                                    Color.red.opacity(0.4)
                                ]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(rotationAngle))
                        .animation(.linear(duration: 2.5).repeatForever(autoreverses: false), value: rotationAngle)
                    
                    // Center icon
                    Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                        .opacity(pulseOpacity)
                        .scaleEffect(1.2)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseOpacity)
                }
                
                VStack(spacing: 12) {
                    Text("Logging Out Securely")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Securing your medical data and ending your session safely...")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 20)
                    
                    HStack(spacing: 16) {
                        securityStepIndicator(step: "1", text: "Encrypting", isActive: true)
                        securityStepIndicator(step: "2", text: "Clearing", isActive: true)
                        securityStepIndicator(step: "3", text: "Securing", isActive: false)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.red.opacity(0.3),
                                        Color.blue.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 30, x: 0, y: 15)
            )
        }
        .onAppear {
            rotationAngle = 360
            scaleEffect = 1.3
            pulseOpacity = 0.8
        }
    }
    
    private func securityStepIndicator(step: String, text: String, isActive: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.green : Color.white.opacity(0.3))
                    .frame(width: 24, height: 24)
                
                Text(step)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isActive ? .white : .gray)
            }
            
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(isActive ? .white : .white.opacity(0.6))
        }
    }
}

// MARK: - Button Style
struct LogoutButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    LogoutView()
        .environmentObject(UserManager.shared)
}
