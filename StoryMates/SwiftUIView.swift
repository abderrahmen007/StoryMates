import SwiftUI

struct ForgotPasswordScreen: View {
    @StateObject private var networkManager = NetworkManager()
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    @State private var showResetPasswordScreen = false
    @Environment(\.dismiss) var dismiss
    
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
                
                // Back button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.black)
                    }
                    .padding(.top, 40)
                    .padding(.leading, 20)
                    
                    Spacer()
                }
                
                // Title
                Text("Forgot Password")
                    .font(.custom("PressStart2P-Regular", size: 33))
                    .foregroundColor(.black)
                Text("Enter your email to reset the password")
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .foregroundColor(.gray)
                    .padding(.bottom, 20).frame(width: 350)
                
                // Email field
                CustomTextField(placeholder: "EMAIL", text: $email)
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .padding(.horizontal, 20)
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.custom("PressStart2P-Regular", size: 10))
                        .foregroundColor(.red)
                        .padding(.top, 10)
                        .padding(.horizontal, 20)
                }
                
                // Send Reset Link button with custom image background
                Button(action: {
                    Task {
                        await handleForgotPassword()
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
                                    Text("Send Reset Link")
                                        .font(.custom("PressStart2P-Regular", size: 17))
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
                        // Handle account creation action
                    }) {
                        Text("CREATE ACCOUNT")
                            .foregroundColor(.yellow)
                            .font(Font.custom("PressStart2P-Regular", size: 10))
                            .padding(5)
                    }
                }
                .padding(.top, 20)
                
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure full screen use
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                showResetPasswordScreen = true
            }
        } message: {
            Text("Password reset code has been sent to your email. Please check your inbox.")
        }
        .fullScreenCover(isPresented: $showResetPasswordScreen) {
            ResetPasswordScreen(email: email)
        }
    }
    
    private func handleForgotPassword() async {
        // Reset error message
        errorMessage = nil
        
        // Validate input
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        
        // Basic email validation
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Please enter a valid email"
            return
        }
        
        isLoading = true
        
        do {
            try await networkManager.forgotPassword(email: email)
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


struct ForgotPasswordScreen_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordScreen()
            .previewDevice("iPhone 14 Pro") // Change the preview device if needed
    }
}
