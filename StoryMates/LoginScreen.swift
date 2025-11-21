import SwiftUI

struct LoginScreen: View {
    @StateObject private var networkManager = NetworkManager()
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    @State private var showRegisterScreen = false
    @State private var showHomeView = false
    @State private var showForgotPasswordScreen = false
    
    var body: some View {
        ZStack {
            // Background with gradient and land images
            Image("background_land") // Replace with your land image name
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            // Cloud animation that fits the screen
            AnimatedClouds()
            
            VStack {
                
                // Title
                Text("Login")
                    .font(.custom("PressStart2P-Regular", size: 37))
                    .foregroundColor(.black)
                Text("enter the realm")
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                
                // Email field
                CustomTextField(placeholder: "EMAIL", text: $email)
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .padding(.horizontal, 20)
                
                // Password field
                CustomTextField(placeholder: "PASSWORD", text: $password, isSecure: true)
                    .padding(.top, 10)
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .padding(.horizontal, 20)   
                
                // Forgot password text
                HStack {
                    Spacer()
                    Button(action: {
                        showForgotPasswordScreen = true
                    }) {
                        Text("forgot password?")
                            .font(.custom("PressStart2P-Regular", size: 10))
                            .foregroundColor(.red)
                            .padding(.top, 10)
                    }
                    Spacer()
                }
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.custom("PressStart2P-Regular", size: 10))
                        .foregroundColor(.red)
                        .padding(.top, 10)
                        .padding(.horizontal, 20)
                }
                
                // Login button with custom image background
                Button(action: {
                    Task {
                        await handleLogin()
                    }
                }) {
                    Image("button") // Replace with your custom button image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 100) // Adjust size as needed
                        .overlay(
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Login")
                                        .font(.custom("PressStart2P-Regular", size: 20))
                                        .foregroundColor(.white)
                                }
                            }
                        )
                }
                .padding(.top, 20)
                .disabled(isLoading)
                
                // New adventurer text and Create Account button
                HStack {
                    Text("New adventurer?")
                        .font(.custom("PressStart2P-Regular", size: 10))
                        .foregroundColor(.black)
                    Button(action: {
                        showRegisterScreen = true
                    }) {
                        Text("CREATE ACCOUNT")
                            .foregroundColor(.yellow)
                            .font(Font.custom("PressStart2P-Regular", size: 10))
                            .padding(5)
                    }
                }
                .padding(.top, 20)
                
                ZStack {
                    // Background image for the social buttons
                    Image("bg") // Replace with your background image name
                        .resizable()
                        .frame(maxWidth: 300, maxHeight: 120)
                    
                    Text("or login with")
                        .font(.custom("PressStart2P-Regular", size: 10))
                        .padding(.bottom, 80)
                    
                    HStack {
                        Spacer()
                        
                        // Facebook button
                        Button(action: {
                            // Handle Facebook login action
                        }) {
                            Image("Facebook") // Replace with your Facebook icon image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                        }
                        
                        // Reddit button
                        Button(action: {
                            // Handle Reddit login action
                        }) {
                            Image("Reddit") // Replace with your Reddit icon image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                        }
                        
                        // Steam button
                        Button(action: {
                            // Handle Steam login action
                        }) {
                            Image("Steam") // Replace with your Steam icon image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 20) // Add horizontal padding for spacing
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure full screen use
        }
        .sheet(isPresented: $showRegisterScreen) {
            RegisterScreen()
        }
        .sheet(isPresented: $showForgotPasswordScreen) {
            ForgotPasswordScreen()
        }
        .fullScreenCover(isPresented: $showHomeView) {
            HomeView()
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {
                showHomeView = true
            }
        } message: {
            Text("Login successful!")
        }
    }
    
    private func handleLogin() async {
        errorMessage = nil
        
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        
        do {
            let authResponse = try await networkManager.login(email: email, password: password)
            let userId = authResponse.userId
            authManager.saveTokens(
                userId: userId,
                accessToken: authResponse.token.accessToken,
                refreshToken: authResponse.token.refreshToken
            )
            isLoading = false
            showSuccessAlert = true
        } catch let error as NetworkError {
            isLoading = false
            errorMessage = error.errorDescription
        } catch {
            isLoading = false
            errorMessage = "An unexpected error occurred"
        }
    }
}

struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen()
            .previewDevice("iPhone 14 Pro") // Change the preview device if needed
    }
}
