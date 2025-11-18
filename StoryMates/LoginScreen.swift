import SwiftUI

struct LoginScreen: View {
    @State private var username = ""
    @State private var password = ""
    
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
                
                // Username field
                CustomTextField(placeholder: "USERNAME", text: $username)
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
                    Text("forgot password?")
                        .font(.custom("PressStart2P-Regular", size: 10))
                        .foregroundColor(.red)
                        .padding(.top, 10)
                    Spacer()
                }
                
                // Login button with custom image background
                Button(action: {
                    // Handle login action
                }) {
                    Image("button") // Replace with your custom button image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 100) // Adjust size as needed
                        .overlay(
                            Text("Login")
                                .font(.custom("PressStart2P-Regular", size: 20))
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
                            .padding(5)                   }
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
    }
}

struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen()
            .previewDevice("iPhone 14 Pro") // Change the preview device if needed
    }
}
