import SwiftUI

struct ForgotPasswordScreen: View {
    @State private var email = ""
    
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
                        // Handle back navigation
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
                
                // Send Reset Link button with custom image background
                Button(action: {
                    // Handle reset password action
                }) {
                    Image("button") // Replace with your custom button image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 100) // Adjust size as needed
                        .overlay(
                            Text("Send Reset Link")
                                .font(.custom("PressStart2P-Regular", size: 17))
                                .foregroundColor(.white)
                        )
                }
                .padding(.top, 20)
                
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
    }
}


struct ForgotPasswordScreen_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordScreen()
            .previewDevice("iPhone 14 Pro") // Change the preview device if needed
    }
}
