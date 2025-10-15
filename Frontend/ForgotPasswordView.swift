import SwiftUI

struct ForgotPasswordView: View {
    @State private var inputText: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isVerified: Bool = false
    @State private var showLoginView = false
    @State private var alertMessage: String = ""
    @State private var showingAlert = false
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            if showLoginView {
                LoginView()
                    .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
                    
            } else {
                forgotFormView
                    .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showLoginView)
        .alert("Message", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {
                if alertMessage == "Password reset successfully" {
                    withAnimation { showLoginView = true }
                }
            }
        } message: { Text(alertMessage) }
        .navigationBarBackButtonHidden(true)
    }
    
    var forgotFormView: some View {
        GeometryReader { geo in
            ZStack {
                // Enhanced gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#F8FAFC"),
                        Color(hex: "#E2E8F0")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Subtle background pattern
                Image("corecarelogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(0.08)
                    .frame(width: geo.size.width * 0.8)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.3)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Enhanced header section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "lock.shield")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(Color(hex: "#194A8C"))
                                
                                Text("Forgot Password")
                                    .font(.custom("Iceland", size: 32))
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(hex: "#194A8C"))
                            }
                            
                            Text("Enter your mobile number or email to reset your password")
                                .font(.custom("Inter", size: 18))
                                .foregroundColor(Color(hex: "#64748B"))
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 40)
                        
                        // Enhanced form card
                        VStack(alignment: .leading, spacing: 28) {
                            // Email/Phone input with enhanced styling
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(hex: "#194A8C"))
                                    
                                    Text("Email or Phone")
                                        .font(.custom("Inter", size: 16))
                                        .fontWeight(.medium)
                                        .foregroundColor(Color(hex: "#1E293B"))
                                }
                                
                                TextField("Enter your email or phone number", text: $inputText)
                                    .padding(16)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                inputText.isEmpty ? Color(hex: "#E2E8F0") : Color(hex: "#194A8C"),
                                                lineWidth: inputText.isEmpty ? 1 : 2
                                            )
                                    )
                                    .foregroundColor(.black)
                                    .font(.custom("Inter", size: 16))
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                            
                            // Enhanced verify button
                            if !isVerified {
                                Button {
                                    verifyUser()
                                } label: {
                                    HStack {
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.9)
                                        } else {
                                            Image(systemName: "checkmark.shield.fill")
                                                .font(.system(size: 16))
                                            
                                            Text("Verify Identity")
                                                .font(.custom("Inter", size: 16))
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 52)
                                }
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "#194A8C"),
                                            Color(hex: "#1E40AF")
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color(hex: "#194A8C").opacity(0.3), radius: 8, x: 0, y: 4)
                                .scaleEffect(isLoading ? 0.95 : 1.0)
                                .animation(.easeInOut(duration: 0.1), value: isLoading)
                            }
                            
                            // Enhanced password reset section
                            if isVerified {
                                VStack(alignment: .leading, spacing: 20) {
                                    // Success indicator
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 20))
                                        
                                        Text("Identity Verified")
                                            .font(.custom("Inter", size: 16))
                                            .fontWeight(.medium)
                                            .foregroundColor(.green)
                                    }
                                    .padding(.bottom, 8)
                                    
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "key.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(Color(hex: "#194A8C"))
                                            
                                            Text("New Password")
                                                .font(.custom("Inter", size: 16))
                                                .fontWeight(.medium)
                                        }
                                        
                                        SecureField("Create a strong password", text: $newPassword)
                                            .padding(16)
                                            .background(Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        newPassword.isEmpty ? Color(hex: "#E2E8F0") : Color(hex: "#194A8C"),
                                                        lineWidth: newPassword.isEmpty ? 1 : 2
                                                    )
                                            )
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled(true)
                                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(Color(hex: "#194A8C"))
                                            
                                            Text("Confirm Password")
                                                .font(.custom("Inter", size: 16))
                                                .fontWeight(.medium)
                                        }
                                        
                                        SecureField("Re-enter your password", text: $confirmPassword)
                                            .padding(16)
                                            .background(Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        confirmPassword.isEmpty ? Color(hex: "#E2E8F0") :
                                                        (newPassword == confirmPassword && !confirmPassword.isEmpty) ?
                                                        Color.green : Color.red,
                                                        lineWidth: confirmPassword.isEmpty ? 1 : 2
                                                    )
                                            )
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled(true)
                                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                    }
                                    
                                    // Password strength indicator
                                    if !newPassword.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Password Requirements:")
                                                .font(.custom("Inter", size: 14))
                                                .fontWeight(.medium)
                                                .foregroundColor(Color(hex: "#64748B"))
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                PasswordRequirementRow(
                                                    text: "At least 8 characters",
                                                    isValid: newPassword.count >= 8
                                                )
                                                PasswordRequirementRow(
                                                    text: "One uppercase letter",
                                                    isValid: newPassword.range(of: "[A-Z]", options: .regularExpression) != nil
                                                )
                                                PasswordRequirementRow(
                                                    text: "One lowercase letter",
                                                    isValid: newPassword.range(of: "[a-z]", options: .regularExpression) != nil
                                                )
                                                PasswordRequirementRow(
                                                    text: "One number",
                                                    isValid: newPassword.range(of: "[0-9]", options: .regularExpression) != nil
                                                )
                                                PasswordRequirementRow(
                                                    text: "One special character",
                                                    isValid: newPassword.range(of: "[\\W_]", options: .regularExpression) != nil
                                                )
                                            }
                                        }
                                        .padding(16)
                                        .background(Color(hex: "#F8FAFC"))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(hex: "#E2E8F0"), lineWidth: 1)
                                        )
                                    }
                                    
                                    Button("Reset Password") { resetPassword() }
                                        .font(.custom("Inter", size: 16))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, minHeight: 52)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(hex: "#2C2C2C"),
                                                    Color(hex: "#1F1F1F")
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                                }
                            }
                            
                            // Enhanced login redirect
                            VStack(spacing: 12) {
                                Rectangle()
                                    .fill(Color(hex: "#E2E8F0"))
                                    .frame(height: 1)
                                    .padding(.horizontal, 20)
                                
                                HStack(spacing: 8) {
                                    Text("Remember your password?")
                                        .font(.custom("Inter", size: 15))
                                        .foregroundColor(Color(hex: "#64748B"))
                                    
                                    Button(action: { withAnimation { showLoginView = true } }) {
                                        HStack(spacing: 4) {
                                            Text("Sign In")
                                                .font(.custom("Inter", size: 15))
                                                .fontWeight(.semibold)
                                                .foregroundColor(Color(hex: "#194A8C"))
                                            
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(Color(hex: "#194A8C"))
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(.top, 8)
                        }
                        .padding(28)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
                        )
                        .padding(.top, 32)
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            }
        }
    }
    
    // MARK: - Models
    struct ForgotResponse: Codable {
        let success: Bool
        let message: String
    }
    
    // MARK: - Verify User
    func verifyUser() {
        guard !inputText.isEmpty else {
            alertMessage = "Please enter email or phone"
            showingAlert = true
            return
        }
        
        isLoading = true
        
        guard let url = URL(string: "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare/forgot.php") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: String] = [
            "emailOrPhone": inputText,
            "new_password": "",
            "confirm_password": ""
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return }
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    alertMessage = "Network error: \(error.localizedDescription)"
                    showingAlert = true
                    return
                }
                
                guard let data = data else {
                    alertMessage = "No response from server"
                    showingAlert = true
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(ForgotResponse.self, from: data)
                    alertMessage = decoded.message
                    showingAlert = true
                    if decoded.success { isVerified = true }
                } catch {
                    let responseStr = String(data: data, encoding: .utf8) ?? ""
                    alertMessage = "Failed to parse server response: \(responseStr)"
                    showingAlert = true
                }
            }
        }.resume()
    }
    
    // MARK: - Reset Password
    func resetPassword() {
        guard newPassword == confirmPassword else {
            alertMessage = "Passwords do not match"
            showingAlert = true
            return
        }
        
        guard isPasswordValid(newPassword) else {
            alertMessage = "Password must be at least 8 characters with 1 uppercase, 1 lowercase, 1 number, and 1 symbol."
            showingAlert = true
            return
        }
        
        guard let url = URL(string: "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare/forgot.php") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: String] = [
            "emailOrPhone": inputText,
            "new_password": newPassword,
            "confirm_password": confirmPassword
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return }
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = "Network error: \(error.localizedDescription)"
                    showingAlert = true
                    return
                }
                
                guard let data = data else {
                    alertMessage = "No response from server"
                    showingAlert = true
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(ForgotResponse.self, from: data)
                    alertMessage = decoded.message
                    showingAlert = true
                    if decoded.success {
                        withAnimation { showLoginView = true }
                    }
                } catch {
                    let responseStr = String(data: data, encoding: .utf8) ?? ""
                    alertMessage = "Failed to parse server response: \(responseStr)"
                    showingAlert = true
                }
            }
        }.resume()
    }
}

// MARK: - Password Requirement Row Component
struct PasswordRequirementRow: View {
    let text: String
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(isValid ? .green : Color(hex: "#94A3B8"))
            
            Text(text)
                .font(.custom("Inter", size: 13))
                .foregroundColor(isValid ? .green : Color(hex: "#64748B"))
        }
    }
}

// MARK: - Helpers
func isPasswordValid(_ password: String) -> Bool {
    let pattern = #"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$"#
    return password.range(of: pattern, options: .regularExpression) != nil
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (r, g, b) = (1, 1, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: 1)
    }
}

#Preview {
    ForgotPasswordView()
}
