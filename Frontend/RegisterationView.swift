import SwiftUI

struct RegistrationView: View {
    @State private var emailOrPhone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var currentView: Destination? = nil
    @State private var warningMessage = ""
    @State private var isLoading = false
    
    // Enhanced UI states
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var emailFocused = false
    @State private var passwordFocused = false
    @State private var confirmPasswordFocused = false
    @State private var passwordStrength: PasswordStrength = .none

    // Use UserManager instead of @AppStorage
    @ObservedObject private var userManager = UserManager.shared

    enum Destination {
        case userDetails, login, content
    }
    
    enum PasswordStrength {
        case none, weak, medium, strong
        
        var color: Color {
            switch self {
            case .none: return .gray
            case .weak: return .red
            case .medium: return .orange
            case .strong: return .green
            }
        }
        
        var text: String {
            switch self {
            case .none: return ""
            case .weak: return "Weak"
            case .medium: return "Medium"
            case .strong: return "Strong"
            }
        }
    }

    var body: some View {
        ZStack {
            if currentView == nil {
                mainView
                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                                        removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                                    ))
                    
            }

            if currentView == .userDetails {
                // UPDATED: Pass initialEditMode: true for new user registration
                UserDetailsView(userId: userManager.currentUserId ?? 0, initialEditMode: true)
                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                                        removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                                    ))

                    .environmentObject(userManager) // Pass UserManager to UserDetailsView
            }

            if currentView == .login {
                LoginView()
                    .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
                    
            }

            if currentView == .content {
                ContentView()
                    .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
                    
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentView)
    }

    var mainView: some View {
        GeometryReader { geo in
            ZStack {
                // Enhanced Background with Gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("bluefont").opacity(0.05),
                        Color.white,
                        Color("bluefont").opacity(0.03)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Enhanced Logo with subtle animation
                Image("corecarelogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 260, height: 260)
                    .opacity(0.08)
                    .scaleEffect(emailFocused || passwordFocused || confirmPasswordFocused ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: emailFocused || passwordFocused || confirmPasswordFocused)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.3)

                ScrollView {
                    VStack(spacing: 0) {
                        // Enhanced Header Section
                        VStack(spacing: 20) {
                            HStack {
                                Button(action: { currentView = .content }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "chevron.left")
                                            .font(.title3)
                                            .fontWeight(.medium)
                                        Text("Back")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(Color("bluefont"))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color("bluefont").opacity(0.1))
                                    )
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 60)
                            
                            // Enhanced Title Section
                            VStack(spacing: 8) {
                                Text("Create Account")
                                    .font(.custom("Iceland", size: 38))
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("bluefont"))
                                
                                Text("Join CoreCare for personalized healthcare")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Enhanced Form Container
                        VStack(spacing: 28) {
                            // Enhanced Email/Phone Field
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(Color("bluefont"))
                                        .font(.caption)
                                    Text("Email or mobile number")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            emailFocused ? Color("bluefont") : Color.gray.opacity(0.3),
                                            lineWidth: emailFocused ? 2 : 1
                                        )
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white)
                                                .shadow(
                                                    color: emailFocused ? Color("bluefont").opacity(0.1) : Color.black.opacity(0.02),
                                                    radius: emailFocused ? 8 : 2,
                                                    x: 0,
                                                    y: emailFocused ? 4 : 1
                                                )
                                        )
                                    
                                    HStack {
                                        Image(systemName: "at.circle.fill")
                                            .foregroundColor(Color("bluefont").opacity(0.6))
                                            .font(.title3)
                                        
                                        TextField("Enter email or phone", text: $emailOrPhone, onEditingChanged: { focused in
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                emailFocused = focused
                                            }
                                        })
                                        .font(.body)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .textContentType(.username)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                }
                            }
                            
                            // Enhanced Password Field
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(Color("bluefont"))
                                        .font(.caption)
                                    Text("Password")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            passwordFocused ? Color("bluefont") : Color.gray.opacity(0.3),
                                            lineWidth: passwordFocused ? 2 : 1
                                        )
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white)
                                                .shadow(
                                                    color: passwordFocused ? Color("bluefont").opacity(0.1) : Color.black.opacity(0.02),
                                                    radius: passwordFocused ? 8 : 2,
                                                    x: 0,
                                                    y: passwordFocused ? 4 : 1
                                                )
                                        )
                                    
                                    HStack {
                                        Image(systemName: "key.fill")
                                            .foregroundColor(Color("bluefont").opacity(0.6))
                                            .font(.title3)
                                        
                                        Group {
                                            if isPasswordVisible {
                                                TextField("Enter password", text: $password, onEditingChanged: { focused in
                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        passwordFocused = focused
                                                    }
                                                    updatePasswordStrength()
                                                })
                                            } else {
                                                SecureField("Enter password", text: $password, onCommit: {
                                                    passwordFocused = false
                                                })
                                                .onTapGesture {
                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        passwordFocused = true
                                                    }
                                                }
                                            }
                                        }
                                        .font(.body)
                                        .textContentType(.newPassword)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .onChange(of: password) {
                                            updatePasswordStrength()
                                        }
                                        
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                isPasswordVisible.toggle()
                                            }
                                        } label: {
                                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                                .foregroundColor(Color("bluefont").opacity(0.6))
                                                .font(.title3)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                }
                                
                                // Password Strength Indicator
                                if !password.isEmpty {
                                    HStack {
                                        HStack(spacing: 4) {
                                            ForEach(0..<4, id: \.self) { index in
                                                Rectangle()
                                                    .fill(index < passwordStrengthLevel ? passwordStrength.color : Color.gray.opacity(0.2))
                                                    .frame(height: 3)
                                                    .cornerRadius(1.5)
                                            }
                                        }
                                        .frame(maxWidth: 100)
                                        
                                        if passwordStrength != .none {
                                            Text(passwordStrength.text)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(passwordStrength.color)
                                        }
                                        
                                        Spacer()
                                    }
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                                }
                            }
                            
                            // Enhanced Confirm Password Field
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "lock.rectangle.fill")
                                        .foregroundColor(Color("bluefont"))
                                        .font(.caption)
                                    Text("Re-enter the Password")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            confirmPasswordFocused ?
                                            (password == confirmPassword && !confirmPassword.isEmpty ? Color.green : Color("bluefont")) :
                                            Color.gray.opacity(0.3),
                                            lineWidth: confirmPasswordFocused ? 2 : 1
                                        )
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white)
                                                .shadow(
                                                    color: confirmPasswordFocused ? Color("bluefont").opacity(0.1) : Color.black.opacity(0.02),
                                                    radius: confirmPasswordFocused ? 8 : 2,
                                                    x: 0,
                                                    y: confirmPasswordFocused ? 4 : 1
                                                )
                                        )
                                    
                                    HStack {
                                        Image(systemName: "checkmark.shield.fill")
                                            .foregroundColor(Color("bluefont").opacity(0.6))
                                            .font(.title3)
                                        
                                        Group {
                                            if isConfirmPasswordVisible {
                                                TextField("Confirm password", text: $confirmPassword, onEditingChanged: { focused in
                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        confirmPasswordFocused = focused
                                                    }
                                                })
                                            } else {
                                                SecureField("Confirm password", text: $confirmPassword, onCommit: {
                                                    confirmPasswordFocused = false
                                                })
                                                .onTapGesture {
                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        confirmPasswordFocused = true
                                                    }
                                                }
                                            }
                                        }
                                        .font(.body)
                                        .textContentType(.newPassword)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                isConfirmPasswordVisible.toggle()
                                            }
                                        } label: {
                                            Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                                .foregroundColor(Color("bluefont").opacity(0.6))
                                                .font(.title3)
                                        }
                                        
                                        // Password match indicator
                                        if !confirmPassword.isEmpty {
                                            Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .foregroundColor(password == confirmPassword ? .green : .red)
                                                .font(.title3)
                                                .transition(.asymmetric(
                                                    insertion: .scale.combined(with: .opacity),
                                                    removal: .scale.combined(with: .opacity)
                                                ))
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                }
                            }
                            
                            // Enhanced Warning Message
                            if !warningMessage.isEmpty {
                                HStack(spacing: 10) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(warningMessage)
                                            .foregroundColor(.red)
                                            .font(.footnote)
                                            .fontWeight(.medium)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.red.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                                
                            }
                            
                            // Enhanced Loading Indicator
                            if isLoading {
                                HStack(spacing: 12) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color("bluefont")))
                                        .scaleEffect(0.9)
                                    
                                    Text("Creating your account...")
                                        .font(.subheadline)
                                        .foregroundColor(Color("bluefont"))
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color("bluefont").opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color("bluefont").opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                            }
                            
                            // Enhanced Sign Up Button
                            Button(action: {
                                validateFields()
                            }) {
                                HStack(spacing: 12) {
                                    if !isLoading {
                                        Image(systemName: "person.badge.plus.fill")
                                            .font(.title3)
                                    }
                                    
                                    Text(isLoading ? "Creating Account..." : "Sign up")
                                        .fontWeight(.semibold)
                                        .font(.body)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            isLoading ? Color.gray : Color("bluefont"),
                                            isLoading ? Color.gray.opacity(0.8) : Color("bluefont").opacity(0.8)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(
                                    color: isLoading ? Color.clear : Color("bluefont").opacity(0.3),
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                                .scaleEffect(isLoading ? 0.98 : 1.0)
                            }
                            .disabled(isLoading)
                            .animation(.easeInOut(duration: 0.2), value: isLoading)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 60)
                        
                        // Enhanced Divider
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("OR")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .background(Color.white)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 35)
                        
                        // Enhanced Login Section
                        VStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Text("Already Have an Account?")
                                    .font(.body)
                                    .foregroundColor(.secondary)

                                Button(action: {
                                    currentView = .login
                                }) {
                                    Text("Log in")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color("bluefont"))
                                }
                            }
                            
                            // Enhanced Login Button
                            Button(action: {
                                currentView = .login
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.right.circle")
                                        .font(.title3)
                                    Text("Sign In Instead")
                                        .fontWeight(.medium)
                                        .font(.body)
                                }
                                .foregroundColor(Color("bluefont"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color("bluefont"), lineWidth: 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white)
                                        )
                                )
                                .shadow(
                                    color: Color("bluefont").opacity(0.1),
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        Spacer(minLength: 50)
                    }
                }
                .frame(width: geo.size.width, alignment: .topLeading)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            emailFocused = false
            passwordFocused = false
            confirmPasswordFocused = false
        }
    }
    
    // MARK: - Password Strength Calculator
    var passwordStrengthLevel: Int {
        switch passwordStrength {
        case .none: return 0
        case .weak: return 1
        case .medium: return 2
        case .strong: return 4
        }
    }
    
    func updatePasswordStrength() {
        let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasNumbers = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecialChars = password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil
        let isLongEnough = password.count >= 8
        
        let criteriaCount = [hasLowercase, hasUppercase, hasNumbers, hasSpecialChars, isLongEnough].filter { $0 }.count
        
        withAnimation(.easeInOut(duration: 0.3)) {
            switch criteriaCount {
            case 0...1:
                passwordStrength = password.isEmpty ? .none : .weak
            case 2...3:
                passwordStrength = .medium
            case 4...5:
                passwordStrength = .strong
            default:
                passwordStrength = .none
            }
        }
    }

    // MARK: - Registration Logic (Enhanced with better UX feedback)
    func validateFields() {
        withAnimation(.easeInOut(duration: 0.3)) {
            warningMessage = ""
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isLoading = true
        }

        guard !emailOrPhone.trimmingCharacters(in: .whitespaces).isEmpty else {
            warningMessage = "Please enter your email or phone number."
            isLoading = false
            return
        }

        guard !password.isEmpty, !confirmPassword.isEmpty else {
            warningMessage = "Password fields are required."
            isLoading = false
            return
        }

        guard password == confirmPassword else {
            warningMessage = "Passwords do not match."
            isLoading = false
            return
        }

        // Email or Phone validation
        guard isValidEmail(emailOrPhone) || isValidPhone(emailOrPhone) else {
            warningMessage = "Please enter a valid email or phone number."
            isLoading = false
            return
        }

        // Password strength validation
        guard isValidPassword(password) else {
            warningMessage = """
            Password must be at least 8 characters long and include:
            • 1 uppercase letter
            • 1 lowercase letter
            • 1 number
            • 1 special symbol
            """
            isLoading = false
            return
        }

        performRegistration()
    }

    // MARK: - Enhanced Network Registration Request
    func performRegistration() {
        guard let url = URL(string: "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare/register.php") else {
            warningMessage = "Invalid server URL."
            isLoading = false
            return
        }

        let parameters: [String: String] = [
            "emailOrPhone": emailOrPhone,
            "password": password
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters) else {
            warningMessage = "Failed to encode JSON."
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        print("Starting registration request for: \(emailOrPhone)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.isLoading = false
                }
                
                if let error = error {
                    self.warningMessage = "Network error: \(error.localizedDescription)"
                    print("Registration network error: \(error)")
                    return
                }

                guard let data = data else {
                    self.warningMessage = "No response data from server."
                    print("Registration: No response data")
                    return
                }

                // Log raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Registration raw response: \(responseString)")
                }

                do {
                    let registrationResponse = try JSONDecoder().decode(RegistrationResponse.self, from: data)
                    
                    if registrationResponse.status == "success" {
                        print("✅ Registration successful - User ID: \(registrationResponse.user_id)")
                        
                        // Create LoginData for UserManager
                        let loginData = LoginData(
                            user_id: registrationResponse.user_id,
                            emailOrPhone: self.emailOrPhone
                        )
                        
                        // Set user data in UserManager and mark as logged in
                        self.userManager.setUserData(loginData)
                        
                        // Verify the UserManager state
                        print("UserManager state after registration:")
                        print("- isLoggedIn: \(self.userManager.isLoggedIn)")
                        print("- currentUserId: \(self.userManager.currentUserId ?? -1)")
                        print("- userData: \(self.userManager.userData?.emailOrPhone ?? "nil")")
                        
                        // Verify data was set correctly
                        if self.userManager.isUserDataValid && self.userManager.currentUserId == registrationResponse.user_id {
                            print("✅ UserManager validation: SUCCESS")
                            print("🔄 Navigating to UserDetailsView with initialEditMode: true")
                            
                            // Clear warning messages
                            withAnimation(.easeInOut(duration: 0.3)) {
                                self.warningMessage = ""
                            }
                            
                            // Navigate to UserDetailsView with proper delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                print("Navigating to UserDetailsView with userId: \(registrationResponse.user_id) and initialEditMode: true")
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    self.currentView = .userDetails
                                }
                            }
                        } else {
                            self.warningMessage = "Failed to save user session."
                            print("❌ UserManager validation: FAILED")
                            print("Expected userId: \(registrationResponse.user_id), Got: \(self.userManager.currentUserId ?? -1)")
                        }
                        
                    } else {
                        self.warningMessage = registrationResponse.message
                        print("❌ Registration failed: \(registrationResponse.message)")
                    }
                } catch {
                    self.warningMessage = "Failed to parse server response."
                    print("❌ JSON parsing error: \(error)")
                    print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                }
            }
        }.resume()
    }

    // MARK: - Validation Helper Functions
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }

    func isValidPhone(_ phone: String) -> Bool {
        let phoneRegEx = #"^\+?[0-9 ]{7,15}$"#
        return NSPredicate(format: "SELF MATCHES %@", phoneRegEx).evaluate(with: phone)
    }

    func isValidPassword(_ password: String) -> Bool {
        let passwordRegEx = #"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z]).{8,}$"#
        return NSPredicate(format: "SELF MATCHES %@", passwordRegEx).evaluate(with: password)
    }
}

// MARK: - Data Models
struct RegistrationResponse: Codable {
    let status: String
    let message: String
    let user_id: Int
}

#Preview {
    RegistrationView()
}
