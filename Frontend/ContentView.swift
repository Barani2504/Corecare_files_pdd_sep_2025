import SwiftUI

struct ContentView: View {
    @State private var currentView: Destination? = nil
    @State private var logoScale: CGFloat = 0.8
    @State private var buttonsOffset: CGFloat = 50

    enum Destination {
        case login, register
    }

    var body: some View {
        ZStack {
            // Animated background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white,
                    Color.blue.opacity(0.05),
                    Color.cyan.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating particles effect
            ForEach(0..<6) { index in
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: CGFloat.random(in: 20...40))
                    .position(
                        x: CGFloat.random(in: 50...350),
                        y: CGFloat.random(in: 100...700)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...6))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.5),
                        value: logoScale
                    )
            }
            
            if currentView == nil {
                mainView
                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                                        removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                                    ))
            }

            if currentView == .login {
                LoginView()
                    .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
            }

            if currentView == .register {
                RegistrationView()
                    .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: currentView)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.6)) {
                logoScale = 1.0
                buttonsOffset = 0
            }
        }
    }

    var mainView: some View {
        GeometryReader { geometry in

                VStack(spacing: 0) {
                    // Dynamic top spacing using safe area
                    Spacer()
                        .frame(height: max(geometry.safeAreaInsets.top + 20, geometry.size.height * 0.08))
                    
                    // Logo Section - Perfectly centered with dynamic sizing
                    VStack(spacing: geometry.size.height * 0.02) {
                        // Main Logo with enhanced effects
                        Image("corecarelogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(
                                width: min(geometry.size.width * 0.6, 300),
                                height: min(geometry.size.width * 0.6, 300)
                            )
                            .scaleEffect(logoScale)
                            .shadow(color: Color.blue.opacity(0.3), radius: 15, x: 0, y: 8)
                            .overlay(
                                // Glow effect
                                Image("corecarelogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(
                                        width: min(geometry.size.width * 0.6, 200),
                                        height: min(geometry.size.width * 0.6, 200)
                                    )
                                    .blur(radius: 20)
                                    .opacity(0.3)
                            )
                            .animation(
                                .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                                value: logoScale
                            )
                        
                        // App Title with responsive font sizing
                        Text("Self Monitoring and Cardiac Care App")
                            .font(.custom("Iceland", size: calculateFontSize(for: geometry)))
                            .fontWeight(.heavy)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color("coreblue"), Color.blue, Color.cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .shadow(color: .blue.opacity(0.5), radius: 5, x: 2, y: 2)
                            .padding(.horizontal, geometry.size.width * 0.1)
                            .scaleEffect(logoScale * 0.9)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Flexible spacing between logo and buttons
                    Spacer()
                        .frame(minHeight: 30, maxHeight: geometry.size.height * 0.1)
                    
                    // Buttons Section - Centered with consistent spacing
                    VStack(spacing: calculateButtonSpacing(for: geometry)) {
                        // Login Button
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                currentView = .login
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: calculateIconSize(for: geometry)))
                                    .foregroundColor(.white)
                                
                                Text("Login")
                                    .font(.custom("Iceland", size: calculateButtonFontSize(for: geometry)))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .frame(
                                width: calculateButtonWidth(for: geometry),
                                height: calculateButtonHeight(for: geometry)
                            )
                            .background(
                                ZStack {
                                    // Background gradient
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    
                                    // Shimmer effect
                                    LinearGradient(
                                        colors: [Color.clear, Color.white.opacity(0.3), Color.clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .animation(
                                        .easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: false),
                                        value: logoScale
                                    )
                                }
                            )
                            .cornerRadius(calculateButtonHeight(for: geometry) / 2)
                            .shadow(color: .green.opacity(0.5), radius: 10, x: 0, y: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: calculateButtonHeight(for: geometry) / 2)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityLabel("Login Button")
                        .offset(y: buttonsOffset)
                        
                        // Register Button
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                currentView = .register
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "person.badge.plus.fill")
                                    .font(.system(size: calculateIconSize(for: geometry)))
                                    .foregroundColor(.white)
                                
                                Text("Register")
                                    .font(.custom("Iceland", size: calculateButtonFontSize(for: geometry)))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .frame(
                                width: calculateButtonWidth(for: geometry),
                                height: calculateButtonHeight(for: geometry)
                            )
                            .background(
                                ZStack {
                                    // Background gradient
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    
                                    // Shimmer effect
                                    LinearGradient(
                                        colors: [Color.clear, Color.white.opacity(0.3), Color.clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .animation(
                                        .easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: false)
                                        .delay(0.5),
                                        value: logoScale
                                    )
                                }
                            )
                            .cornerRadius(calculateButtonHeight(for: geometry) / 2)
                            .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: calculateButtonHeight(for: geometry) / 2)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityLabel("Register Button")
                        .offset(y: buttonsOffset)
                        
                        // Decorative dots with responsive sizing
                        HStack(spacing: geometry.size.width * 0.03) {
                            ForEach(0..<5) { index in
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.6), Color.cyan.opacity(0.4)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(
                                        width: calculateDotSize(for: geometry),
                                        height: calculateDotSize(for: geometry)
                                    )
                                    .scaleEffect(index == 2 ? 1.4 : 1.0)
                                    .animation(
                                        .easeInOut(duration: 1.0)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.2),
                                        value: logoScale
                                    )
                            }
                        }
                        .offset(y: buttonsOffset)
                        .padding(.top, 20)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Dynamic bottom spacing
                    Spacer()
                        .frame(minHeight: max(geometry.safeAreaInsets.bottom + 20, 40))
                }
                .frame(minHeight: geometry.size.height)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Dynamic Sizing Functions
    
    private func calculateFontSize(for geometry: GeometryProxy) -> CGFloat {
        let baseSize: CGFloat = 18
        let screenWidth = geometry.size.width
        
        // Scale font size based on screen width with min/max bounds
        let scaledSize = baseSize * (screenWidth / 375) // 375 is iPhone base width
        return max(16, min(scaledSize, 24)) // Min 16, Max 24
    }
    
    private func calculateButtonFontSize(for geometry: GeometryProxy) -> CGFloat {
        let baseSize: CGFloat = 20
        let screenWidth = geometry.size.width
        
        let scaledSize = baseSize * (screenWidth / 375)
        return max(18, min(scaledSize, 26)) // Min 18, Max 26
    }
    
    private func calculateIconSize(for geometry: GeometryProxy) -> CGFloat {
        let baseSize: CGFloat = 20
        let screenWidth = geometry.size.width
        
        let scaledSize = baseSize * (screenWidth / 375)
        return max(18, min(scaledSize, 28)) // Min 18, Max 28
    }
    
    private func calculateButtonWidth(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return min(screenWidth * 0.75, 320) // Max width of 320pt
    }
    
    private func calculateButtonHeight(for geometry: GeometryProxy) -> CGFloat {
        let screenHeight = geometry.size.height
        let baseHeight: CGFloat = 55
        
        // Scale button height based on screen height
        let scaledHeight = baseHeight * (screenHeight / 667) // 667 is iPhone 8 base height
        return max(50, min(scaledHeight, 65)) // Min 50, Max 65
    }
    
    private func calculateButtonSpacing(for geometry: GeometryProxy) -> CGFloat {
        let screenHeight = geometry.size.height
        let baseSpacing: CGFloat = 20
        
        let scaledSpacing = baseSpacing * (screenHeight / 667)
        return max(16, min(scaledSpacing, 30)) // Min 16, Max 30
    }
    
    private func calculateDotSize(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let baseSize: CGFloat = 8
        
        let scaledSize = baseSize * (screenWidth / 375)
        return max(6, min(scaledSize, 12)) // Min 6, Max 12
    }
}

// Custom bouncy button style
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .brightness(configuration.isPressed ? -0.1 : 0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// Preview for different devices

