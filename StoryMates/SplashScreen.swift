//
//  SplashScreen.swift
//  StoryMates
//
//  Created by mac on 11/10/25.
//


import SwiftUI

struct SplashScreen: View {
    var body: some View {
        VStack {
            // Image for splash s#imageLiteral(resourceName: "background_land.png")creen
            Image("splashscreen") // Ensure the logo image is added to your assets
                .resizable()
                .scaledToFit()
                .frame(width: 1920, height: 880)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.green]), startPoint: .top, endPoint: .bottom)
        )
        .edgesIgnoringSafeArea(.all)
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
