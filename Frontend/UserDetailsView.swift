import SwiftUI

struct UserDetailsView: View {
    @EnvironmentObject var userManager: UserManager
    let userId: Int
    let initialEditMode: Bool
    
    @State private var currentPage: HomePageSection = .userDetails
    @State private var isEditing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showSuccessAnimation = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showLogoutView = false
    @State private var showAvatarSelector = false

    // Delete account states
    @State private var showDeleteConfirmation = false
    @State private var showFinalDeleteWarning = false
    @State private var deleteConfirmationText = ""
    @State private var isDeleting = false

    // Convenience initializer for existing users
    init(userId: Int) {
        self.userId = userId
        self.initialEditMode = false
    }
    
    // Initializer for new users (with edit mode)
    init(userId: Int, initialEditMode: Bool) {
        self.userId = userId
        self.initialEditMode = initialEditMode
    }

    // Get userId from parameter with validation
    private var currentUserId: Int {
        print("UserDetailsView - Parameter userId: \(userId)")
        print("UserDetailsView - UserManager ID: \(userManager.currentUserId ?? -1)")
        
        if userId > 0 {
            return userId
        } else if let managerId = userManager.currentUserId, managerId > 0 {
            return managerId
        } else {
            print("WARNING: No valid user ID available in UserDetailsView!")
            return 0
        }
    }

    // Stored data
    @State private var name: String = ""
    @State private var ageString: String = ""
    @State private var sex: String = ""
    @State private var heightString: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var selectedAvatar: String = ""

    // Editable copy
    @State private var editName: String = ""
    @State private var editAge: String = ""
    @State private var editSex: String = ""
    @State private var editHeight: String = ""
    @State private var editPhone: String = ""
    @State private var editEmail: String = ""
    @State private var editAvatar: String = ""

    private var age: Int? { Int(editAge) }
    private var height: Double? { Double(editHeight) }

    @FocusState private var focusedField: Field?
    @State private var avatarScale: CGFloat = 1.0
    @State private var hasLoadedOnce = false

    enum Field { case name, age, sex, height, phone, email }
    
    // Available avatars (1-12)
    private let availableAvatars = (1...12).map { "avatar\($0)" }
    
    // Colors matching HomePageView
    private let primaryColor = Color(red: 0.11, green: 0.13, blue: 0.19)
    private let secondaryColor = Color(red: 0.96, green: 0.96, blue: 0.98)
    private let accentColor = Color(red: 0.33, green: 0.42, blue: 0.95)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                secondaryColor
                    .ignoresSafeArea()

                if showLogoutView {
                    LogoutView()
                        .environmentObject(userManager)
                        .transition(.opacity)
                } else {
                    contentView(geo: geo)
                    
                    if currentPage == .userDetails {
                        bottomNavigation(geo: geo)
                    }
                }

                if isLoading || isDeleting {
                    LoadingOverlay()
                }

                if showSuccessAnimation {
                    SuccessfulAnimation()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSuccessAnimation = false
                            }
                        }
                }
                
                if showAvatarSelector {
                    avatarSelectorSheet
                        .transition(.opacity)
                }
                
                // Delete confirmation overlays
                if showDeleteConfirmation {
                    deleteConfirmationSheet
                        .transition(.opacity)
                }
                
                if showFinalDeleteWarning {
                    finalDeleteWarningSheet
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            validateUserSession()
            guard !hasLoadedOnce && currentUserId != 0 else { return }
            hasLoadedOnce = true
            
            if initialEditMode {
                print("Setting initial edit mode for new user")
                isEditing = true
                // Set empty values for editing
                editName = ""
                editAge = ""
                editSex = ""
                editHeight = ""
                editPhone = ""
                editEmail = ""
                editAvatar = ""
            }
            
            loadUserDataFromServer()
        }
        .alert("Notice", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .animation(.easeInOut(duration: 0.3), value: showLogoutView)
        .animation(.easeInOut(duration: 0.3), value: showAvatarSelector)
        .animation(.easeInOut(duration: 0.3), value: showDeleteConfirmation)
        .animation(.easeInOut(duration: 0.3), value: showFinalDeleteWarning)
        .onChange(of: showLogoutView) { oldValue, newValue in
            print("UserDetailsView: showLogoutView changed to: \(newValue)")
        }
    }
    
    // MARK: - Enhanced User Session Validation
    private func validateUserSession() {
        print("Validating user session in UserDetailsView...")
        print("UserManager isLoggedIn: \(userManager.isLoggedIn)")
        print("UserManager userData: \(userManager.userData?.user_id ?? -1)")
        print("Computed currentUserId: \(currentUserId)")
        
        if currentUserId == 0 {
            showError = true
            errorMessage = "Invalid user session. Please log in again."
        }
    }
    
    @ViewBuilder
    private func contentView(geo: GeometryProxy) -> some View {
        switch currentPage {
        case .userDetails:
            userDetailsContent(geo: geo)
        case .home:
            HomePageView(userId: currentUserId)
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
        case .moodWellness:
            BloodSugarView()
                .environmentObject(userManager)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
        }
    }
    
    private func userDetailsContent(geo: GeometryProxy) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection(geo: geo)
                    .padding(.top, geo.safeAreaInsets.top > 0 ? geo.safeAreaInsets.top - 10 : 20)
                    .padding(.bottom, 20)

                if initialEditMode && name.isEmpty {
                    welcomeCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }

                profileCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                formSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)

                actionButtons
                    .padding(.horizontal, 20)
                    .padding(.bottom, geo.size.height * 0.2)
            }
        }
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Welcome Card for New Users
    private var welcomeCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "hand.wave.fill")
                    .foregroundColor(accentColor)
                    .font(.title2)
                
                Text("Welcome to CoreCare!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(primaryColor)
                
                Spacer()
            }
            
            HStack {
                Text("Please complete your profile to get started with personalized healthcare recommendations.")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [accentColor.opacity(0.1), accentColor.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Header with Avatar Selection
    private func headerSection(geo: GeometryProxy) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(initialEditMode && name.isEmpty ? "Complete Your Profile" : "Your Profile")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(primaryColor.opacity(0.7))
                
                Text(name.isEmpty ? (initialEditMode ? "New User" : "User") : name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(primaryColor)
                
            }
            Spacer()
            
            Button(action: {
                if isEditing {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAvatarSelector = true
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [accentColor, accentColor.opacity(0.8)]),
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 50, height: 50)
                        .scaleEffect(avatarScale)
                    
                    if !getCurrentAvatar().isEmpty {
                        Image(getCurrentAvatar())
                            .resizable()
                            .scaledToFill()
                            .frame(width: 45, height: 45)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    if isEditing {
                        VStack {
                            Spacer(minLength: 15)
                            HStack {
                                
                                Circle()
                                    .fill(accentColor)
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        Image(systemName: "pencil")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 5, y: 5)
                            }
                        }
                    }
                }
            }
            .disabled(!isEditing)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    avatarScale = 1.05
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(secondaryColor)
    }
    
    private func getCurrentAvatar() -> String {
        return isEditing ? editAvatar : selectedAvatar
    }

    // MARK: - Avatar Selector Sheet
    private var avatarSelectorSheet: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAvatarSelector = false
                    }
                }
            
            VStack(spacing: 20) {
                HStack {
                    Text("Choose Your Avatar")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(primaryColor)
                    
                    Spacer()
                    
                    Button("✕") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAvatarSelector = false
                        }
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.gray)
                }
                
                Button(action: {
                    editAvatar = ""
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAvatarSelector = false
                    }
                }) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(editAvatar.isEmpty ? accentColor : Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        
                        Text("Default Avatar")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(editAvatar.isEmpty ? accentColor : .gray)
                        
                        Spacer()
                        
                        if editAvatar.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(accentColor)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(editAvatar.isEmpty ? accentColor.opacity(0.1) : Color.clear)
                    .cornerRadius(12)
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                    ForEach(availableAvatars, id: \.self) { avatarName in
                        Button(action: {
                            editAvatar = avatarName
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAvatarSelector = false
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(editAvatar == avatarName ? accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                                    .frame(width: 60, height: 60)
                                
                                Image(avatarName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 55, height: 55)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(editAvatar == avatarName ? accentColor : Color.clear, lineWidth: 3)
                                    )
                                
                                if editAvatar == avatarName {
                                    VStack {
                                        HStack {
                                            Spacer()
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(accentColor)
                                                .background(Circle().fill(Color.white))
                                        }
                                        Spacer()
                                    }
                                    .frame(width: 55, height: 55)
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Profile Card
    private var profileCard: some View {
        VStack(spacing: 15) {
            HStack(spacing: 20) {
                StatView(value: isEditing ? (editAge.isEmpty ? "--" : editAge) : (ageString.isEmpty ? "--" : ageString),
                         label: "Age", icon: "calendar")
                StatView(value: isEditing ? (editHeight.isEmpty ? "--" : "\(editHeight) cm") : (heightString.isEmpty ? "--" : "\(heightString) cm"),
                         label: "Height", icon: "ruler")
                StatView(value: isEditing ? (editSex.isEmpty ? "--" : editSex.prefix(1).uppercased()) : (sex.isEmpty ? "--" : sex.prefix(1).uppercased()),
                         label: "Sex", icon: "person")
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "person.text.rectangle").foregroundColor(accentColor)
                Text(initialEditMode && name.isEmpty ? "Enter Your Details" : "Personal Information")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(primaryColor)
                Spacer()
            }
            
            if isEditing {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 150)), count: 2), spacing: 20) {
                    EnhancedDetailField(title: "Full Name", text: $editName, editable: true, icon: "person", systemImage: true)
                        .focused($focusedField, equals: .name)
                    EnhancedDetailField(title: "Age", text: $editAge, editable: true, icon: "number", systemImage: true, keyboardType: .numberPad)
                        .focused($focusedField, equals: .age)
                    EnhancedDetailField(title: "Gender", text: $editSex, editable: true, icon: "person.2", systemImage: true)
                        .focused($focusedField, equals: .sex)
                    EnhancedDetailField(title: "Height (cm)", text: $editHeight, editable: true, icon: "ruler", systemImage: true, keyboardType: .decimalPad)
                        .focused($focusedField, equals: .height)
                    EnhancedDetailField(title: "Phone", text: $editPhone, editable: true, icon: "phone", systemImage: true, keyboardType: .phonePad)
                        .focused($focusedField, equals: .phone)
                    EnhancedDetailField(title: "Email", text: $editEmail, editable: true, icon: "envelope", systemImage: true, keyboardType: .emailAddress)
                        .focused($focusedField, equals: .email)
                }
            } else {
                VStack(spacing: 12) {
                    DetailRow(label: "Full Name", value: name)
                    DetailRow(label: "Age", value: ageString)
                    DetailRow(label: "Gender", value: sex)
                    DetailRow(label: "Height (cm)", value: heightString)
                    DetailRow(label: "Phone", value: phone)
                    DetailRow(label: "Email", value: email)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Action Buttons with Delete Account
    private var actionButtons: some View {
        VStack(spacing: 15) {
            Button(action: handleEditSave) {
                HStack {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil")
                        .font(.system(size: 18, weight: .semibold))
                    Text(isEditing ? (initialEditMode && name.isEmpty ? "Complete Profile" : "Save Changes") : "Edit Profile")
                        .font(.system(size: 16, weight: .semibold))
                    if isEditing {
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [accentColor, accentColor.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(isLoading || isDeleting)

            // Logout and Delete buttons - Only show when NOT editing
            if !isEditing {
                Button(action: {
                    print("UserDetailsView: Logout button tapped")
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.showLogoutView = true
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Log Out")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.92, anchor: .center).combined(with: .opacity),
                    removal: .scale(scale: 1.08, anchor: .center).combined(with: .opacity)
                ))
                
                // Delete Account Button
                // 1️⃣  Action button (inside `actionButtons` stack)
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showDeleteConfirmation = true
                    }
                } label: {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(
                                    AngularGradient(
                                        colors: [.red, .orange, .purple, .red],
                                        center: .center
                                    )
                                )
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Image(systemName: "trash")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                )
                            // Subtle pulsing ring
                            Circle()
                                .stroke(.red.opacity(0.4), lineWidth: 2)
                                .frame(width: 32, height: 32)
                                .scaleEffect(showDeleteConfirmation ? 1.1 : 1)
                                .opacity(showDeleteConfirmation ? 0 : 1)
                                .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: showDeleteConfirmation)
                        }
                        Text("Delete Account")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.red.opacity(0.1))
                            .background(
                                // Embossed surface
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(.white.opacity(0.7), lineWidth: 0.2)
                                    .blendMode(.overlay)
                            )
                    )
                }
                .disabled(isDeleting)
                .transition(.scale.combined(with: .opacity))

            }
        }
        .animation(.easeInOut(duration: 0.3), value: isEditing)
    }
    
    // MARK: - Delete Account Confirmation Sheet
    private var deleteConfirmationSheet: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showDeleteConfirmation = false
                        deleteConfirmationText = ""
                    }
                }
            
            VStack(spacing: 24) {
                // Warning Icon
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("Delete Account")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(primaryColor)
                }
                
                // Warning Text
                VStack(spacing: 12) {
                    Text("This action cannot be undone!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    
                    Text("Deleting your account will permanently remove all your health data, history, and profile information from CoreCare.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Confirmation Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type 'DELETE' to confirm:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(primaryColor)
                    
                    TextField("Type DELETE here", text: $deleteConfirmationText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                }
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showDeleteConfirmation = false
                            deleteConfirmationText = ""
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.clear)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentColor, lineWidth: 2))
                    
                    Button("Continue") {
                        if deleteConfirmationText == "DELETE" {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDeleteConfirmation = false
                                showFinalDeleteWarning = true
                            }
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(deleteConfirmationText == "DELETE" ? Color.red : Color.gray.opacity(0.5))
                    .cornerRadius(12)
                    .disabled(deleteConfirmationText != "DELETE")
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Final Delete Warning Sheet
    private var finalDeleteWarningSheet: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Danger Icon
                VStack(spacing: 16) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("Final Warning")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                }
                
                // Final Warning Text
                VStack(spacing: 12) {
                    Text("Are you absolutely sure?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(primaryColor)
                        .multilineTextAlignment(.center)
                    
                    Text("This will immediately and permanently delete your account and all associated data. You will be logged out and cannot recover this information.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Final Action Buttons
                HStack(spacing: 16) {
                    Button("Keep My Account") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showFinalDeleteWarning = false
                            deleteConfirmationText = ""
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentColor, lineWidth: 2))
                    
                    Button("Delete Forever") {
                        deleteConfirmationText = ""
                        showFinalDeleteWarning = false
                        deleteUserAccount()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.red)
                    .cornerRadius(12)
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 15)
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Bottom Navigation
    private func bottomNavigation(geo: GeometryProxy) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        currentPage = .home
                    }
                } label: {
                    EnhancedBottomNavItem(
                        systemName: "house.fill",
                        label: "Home",
                        isActive: currentPage == .home
                    )
                }
                .frame(maxWidth: .infinity)
                .disabled(currentPage == .home)

                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        currentPage = .history
                    }
                } label: {
                    EnhancedBottomNavItem(
                        systemName: "clock.fill",
                        label: "History",
                        isActive: currentPage == .history
                    )
                }
                .frame(maxWidth: .infinity)
                .disabled(currentPage == .history)

                Button {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                } label: {
                    EnhancedBottomNavItem(
                        systemName: "person.fill",
                        label: "Profile",
                        isActive: currentPage == .userDetails
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -5)
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                }
            )
            .padding(.horizontal, 20)
            .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? geo.safeAreaInsets.bottom + 10 : 30)
        }
    }

    // MARK: - Handle edit/save with avatar
    private func handleEditSave() {
        if isEditing {
            focusedField = nil
            if validateFields() {
                print("Validation passed, saving user data")
                saveUserDataToServer()
            } else {
                showAlert = true
            }
        } else {
            print("Entering edit mode")
            editName = name
            editAge = ageString
            editSex = sex
            editHeight = heightString
            editPhone = phone
            editEmail = email
            editAvatar = selectedAvatar
            
            withAnimation(.easeInOut(duration: 0.3)) {
                isEditing = true
            }
        }
    }

    func validateFields() -> Bool {
        if editName.isEmpty || editAge.isEmpty || editSex.isEmpty || editHeight.isEmpty || editPhone.isEmpty || editEmail.isEmpty {
            alertMessage = "Please fill in all fields."
            return false
        }
        if !editEmail.contains("@") || !editEmail.contains(".") {
            alertMessage = "Please enter a valid email address."
            return false
        }
        if editPhone.filter({ $0.isNumber }).count != 10 {
            alertMessage = "Please enter a valid 10-digit phone number."
            return false
        }
        if Int(editAge) == nil {
            alertMessage = "Enter valid age."
            return false
        }
        if Double(editHeight) == nil {
            alertMessage = "Enter valid height in cm."
            return false
        }
        return true
    }

    // MARK: - FIXED Server Functions
    func loadUserDataFromServer() {
        guard currentUserId > 0,
              let url = URL(string: "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare/user.php?user_id=\(currentUserId)") else {
            print("Invalid userId (\(currentUserId)) or URL in UserDetailsView")
            showAlert = true
            alertMessage = "Invalid user session"
            return
        }

        print("Loading user data for user ID: \(currentUserId)")
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Network error loading user data: \(error.localizedDescription)")
                    self.alertMessage = "Network error: \(error.localizedDescription)"
                    self.showAlert = true
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.alertMessage = "Invalid response format"
                    self.showAlert = true
                    return
                }
                
                print("HTTP Status Code: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    print("HTTP Error: \(httpResponse.statusCode)")
                    self.alertMessage = "Server error: HTTP \(httpResponse.statusCode)"
                    self.showAlert = true
                    return
                }
                
                guard let data = data else {
                    self.alertMessage = "No data received from server"
                    self.showAlert = true
                    return
                }
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw server response: \(responseString)")
                }
                
                do {
                    let response = try JSONDecoder().decode(ServerUserResponse.self, from: data)
                    print("Successfully decoded response: \(response)")
                    
                    guard response.status == "success", let user = response.data else {
                        self.alertMessage = response.message ?? "User not found."
                        self.showAlert = true
                        return
                    }
                    
                    // Update all user data including avatar
                    self.name = user.name ?? ""
                    self.ageString = "\(user.age ?? 0)"
                    self.sex = user.sex ?? ""
                    self.heightString = user.height ?? ""
                    self.phone = user.phone ?? ""
                    self.email = user.email ?? ""
                    self.selectedAvatar = user.profile_picture ?? ""
                    
                    print("User data loaded successfully with avatar: \(self.selectedAvatar)")
                    
                    if self.isEditing {
                        self.editName = self.name
                        self.editAge = self.ageString
                        self.editSex = self.sex
                        self.editHeight = self.heightString
                        self.editPhone = self.phone
                        self.editEmail = self.email
                        self.editAvatar = self.selectedAvatar
                        print("Edit fields updated with avatar")
                    }
                    
                    NotificationCenter.default.post(
                        name: NSNotification.Name("UserAvatarChanged"),
                        object: nil,
                        userInfo: ["avatar": self.selectedAvatar]
                    )
                    
                } catch {
                    print("JSON Decoding error: \(error)")
                    self.alertMessage = "Failed to parse server response"
                    self.showAlert = true
                }
            }
        }.resume()
    }

    func saveUserDataToServer() {
        guard currentUserId > 0,
              let url = URL(string: "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare/user.php") else {
            print("Invalid userId (\(currentUserId)) or URL for saving user data")
            showAlert = true
            alertMessage = "Invalid user session"
            return
        }

        isLoading = true
        
        // FIXED: Match PHP expectations exactly
        let payload: [String: Any] = [
            "user_id": currentUserId,  // This matches PHP $_POST validation
            "name": editName,
            "age": Int(editAge) ?? 0,
            "sex": editSex,
            "height": editHeight,  // Send as string to match PHP expectation
            "phone": editPhone,
            "email": editEmail,
            "profile_picture": editAvatar
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            alertMessage = "Failed to encode user data."
            showAlert = true
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        print("Saving user data with payload: \(payload)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Network error saving user data: \(error.localizedDescription)")
                    self.alertMessage = "Network error: \(error.localizedDescription)"
                    self.showAlert = true
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.alertMessage = "Invalid response format"
                    self.showAlert = true
                    return
                }
                
                print("HTTP Status Code: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    print("HTTP Error: \(httpResponse.statusCode)")
                    self.alertMessage = "Server error: HTTP \(httpResponse.statusCode)"
                    self.showAlert = true
                    return
                }
                
                guard let data = data else {
                    self.alertMessage = "No data received from server"
                    self.showAlert = true
                    return
                }
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw server response: \(responseString)")
                }
                
                do {
                    let response = try JSONDecoder().decode(SaveUserResponse.self, from: data)
                    print("Decoded response status: \(response.status)")
                    print("Decoded response message: \(response.message ?? "No message")")
                    
                    self.alertMessage = response.message ?? "Unknown response"
                    self.showAlert = true
                    
                    if response.status == "success" {
                        print("Save successful!")
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.name = self.editName
                            self.ageString = self.editAge
                            self.sex = self.editSex
                            self.heightString = self.editHeight
                            self.phone = self.editPhone
                            self.email = self.editEmail
                            self.selectedAvatar = self.editAvatar
                        }
                        
                        print("State updated with avatar: \(self.selectedAvatar)")
                        
                        NotificationCenter.default.post(
                            name: NSNotification.Name("UserAvatarChanged"),
                            object: nil,
                            userInfo: ["avatar": self.selectedAvatar]
                        )
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.isEditing = false
                        }
                        
                        self.showSuccessAnimation = true
                        print("Save process completed successfully")
                    } else {
                        print("Save failed with status: \(response.status)")
                    }
                } catch {
                    print("JSON Decoding error: \(error)")
                    self.alertMessage = "Failed to parse server response"
                    self.showAlert = true
                }
            }
        }.resume()
    }
    
    // MARK: - Delete Account Function
    private func deleteUserAccount() {
        guard currentUserId > 0,
              let url = URL(string: "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare/user.php") else {
            print("Invalid userId (\(currentUserId)) or URL for deleting user account")
            showAlert = true
            alertMessage = "Invalid user session"
            return
        }

        isDeleting = true
        
        let payload: [String: Any] = [
            "user_id": currentUserId
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            alertMessage = "Failed to prepare delete request."
            showAlert = true
            isDeleting = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        print("Deleting user account with payload: \(payload)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isDeleting = false
                
                if let error = error {
                    print("Network error deleting user account: \(error.localizedDescription)")
                    self.alertMessage = "Network error: \(error.localizedDescription)"
                    self.showAlert = true
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.alertMessage = "Invalid response format"
                    self.showAlert = true
                    return
                }
                
                print("HTTP Status Code: \(httpResponse.statusCode)")
                
                guard let data = data else {
                    self.alertMessage = "No data received from server"
                    self.showAlert = true
                    return
                }
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw server response: \(responseString)")
                }
                
                do {
                    let response = try JSONDecoder().decode(SaveUserResponse.self, from: data)
                    print("Decoded response status: \(response.status)")
                    print("Decoded response message: \(response.message ?? "No message")")
                    
                    if response.status == "success" {
                        print("Account deletion successful!")
                        
                        // Clear user session and navigate to login
                        DispatchQueue.main.async {
                            // Clear user data
                            self.userManager.logout()
                            
                            // Navigate to login screen
                            // This assumes you have a way to navigate to the root/login view
                            // You might need to adjust this based on your app's navigation structure
                            NotificationCenter.default.post(name: NSNotification.Name("UserAccountDeleted"), object: nil)
                        }
                        
                    } else {
                        self.alertMessage = response.message ?? "Account deletion failed"
                        self.showAlert = true
                    }
                    
                } catch {
                    print("JSON Decoding error: \(error)")
                    self.alertMessage = "Failed to parse server response"
                    self.showAlert = true
                }
            }
        }.resume()
    }
}

// MARK: - Components
struct EnhancedDetailField: View {
    let title: String
    @Binding var text: String
    var editable: Bool
    var icon: String
    var systemImage: Bool
    var keyboardType: UIKeyboardType = .default
    var disableAutocorrection: Bool = false
    
    private let accentColor = Color(red: 0.33, green: 0.42, blue: 0.95)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if systemImage {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(accentColor)
                }
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            if editable {
                TextField("", text: $text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(disableAutocorrection)
            } else {
                Text(text.isEmpty ? "Not set" : text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(text.isEmpty ? .gray : .black)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            Spacer()
            Text(value.isEmpty ? "Not set" : value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct StatView: View {
    let value: String
    let label: String
    let icon: String
    
    private let accentColor = Color(red: 0.33, green: 0.42, blue: 0.95)
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(accentColor)
            }
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SuccessfulAnimation: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                Text("Saved!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(20)
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(15)
        }
    }
}

struct LoadingsOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    
                Text("Loading...")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(30)
            .background(Color(.systemBackground).opacity(0.95))
            .cornerRadius(15)
            .shadow(radius: 10)
        }
    }
}

// MARK: - Server Response Models
struct ServeresUserResponse: Codable {
    let status: String
    let data: ServerUserData?
    let message: String?
}

struct ServeresUserData: Codable {
    let name: String?
    let age: Int?
    let sex: String?
    let height: String?
    let phone: String?
    let email: String?
    let profile_picture: String?
}

struct SaveUserResponse: Codable {
    let status: String
    let data: ServerUserData?
    var message: String?
}

struct EnhancesBottomNavItem: View {
    var systemName: String
    var label: String
    var isActive: Bool
    
    private let activeColor = Color(red: 0.33, green: 0.42, blue: 0.95)
    private let inactiveColor = Color.gray
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.system(size: isActive ? 22 : 20, weight: isActive ? .bold : .medium))
                .foregroundColor(isActive ? activeColor : inactiveColor.opacity(isActive ? 1.0 : 0.6))
                .scaleEffect(isActive ? 1.1 : 1.0)
            
            Text(label)
                .font(.system(size: 12, weight: isActive ? .semibold : .medium))
                .foregroundColor(isActive ? activeColor : inactiveColor.opacity(isActive ? 1.0 : 0.6))
        }
        .frame(width: 60)
        .padding(.vertical, 15)
        .background(isActive ? activeColor.opacity(0.1) : Color.clear)
        .cornerRadius(12)
        .opacity(isActive ? 1.0 : 0.7)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

struct UserDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        UserDetailsView(userId: 1)
            .environmentObject(UserManager.shared)
    }
}
