//
//  ResetPasswordScreen.swift
//  StoryMates
//
//  Created by mac on 11/10/25.
//


import SwiftUI

struct ResetPasswordScreen: View {
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
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
                HStack {
                    // Back button
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
                Text("Reset Password")
                    .font(.custom("PressStart2P-Regular", size: 37))
                    .foregroundColor(.black)
                Text("Enter your new password")
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                
                // New Password field
                CustomTextField(placeholder: "NEW PASSWORD", text: $newPassword, isSecure: true)
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .padding(.horizontal, 20)
                
                // Confirm Password field
                CustomTextField(placeholder: "CONFIRM PASSWORD", text: $confirmPassword, isSecure: true)
                    .padding(.top, 10)
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .padding(.horizontal, 20)
                
                // Reset Password button with custom image background
                Button(action: {
                    // Handle reset password action
                }) {
                    Image("button") // Replace with your custom button image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 100) // Adjust size as needed
                        .overlay(
                            Text("Reset")
                                .font(.custom("PressStart2P-Regular", size: 20))
                                .foregroundColor(.white)
                        )
                }
                .padding(.top, 20)
                
                // Social login buttons (optional)
                SocialLoginButtons()
                    .padding(.top, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure full screen use
    }
}



struct ResetPasswordScreen_Previews: PreviewProvider {
    static var previews: some View {
        ResetPasswordScreen()
            .previewDevice("iPhone 14 Pro") // Change the preview device if needed
    }
}
