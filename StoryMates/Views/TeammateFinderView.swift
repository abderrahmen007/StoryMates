import SwiftUI

enum FindTeammatesMode {
    case selector
    case match
    case nearby
}

struct TeammateFinderView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = TeammateFinderViewModel()
    @State private var showingMatchAnimation = false
    @State private var matchedUser: User?
    @State private var currentMode: FindTeammatesMode = .selector
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            // Background
            if themeManager.isDarkMode {
                DarkThemeBackground()
            } else {
                Image("background_land")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            }
            // Cloud animation that fits the screen
            AnimatedClouds()
            
            
            switch currentMode {
            case .selector:
                modeSelectorView
            case .match:
                matchModeView
            case .nearby:
                NearbyTeammatesView(onBack: { currentMode = .selector })
                    .environmentObject(authManager)
            }
            
            if showingMatchAnimation, let user = matchedUser {
                MatchAnimationView(user: user, isShowing: $showingMatchAnimation)
            }
        }
        .navigationBarHidden(true)
    }
    
    private var modeSelectorView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Find Teammates")
                .font(.custom("PressStart2P-Regular", size: 20))
                .foregroundColor(.yellow)
                .shadow(color: .black, radius: 2, x: 1, y: 1)
            
            Text("Choose how to discover")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            // Match Mode Card
            ModeSelectionCard(
                icon: "person.2.fill",
                title: "MATCH",
                description: "Swipe through profiles and match with compatible gamers",
                color: .purple
            ) {
                currentMode = .match
            }
            
            // Nearby Mode Card
            ModeSelectionCard(
                icon: "location.fill",
                title: "NEARBY",
                description: "Find gamers near you actively searching right now",
                color: .cyan
            ) {
                currentMode = .nearby
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private var matchModeView: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: { currentMode = .selector }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.yellow)
                }
                
                Spacer()
                
                Text("MATCH")
                    .font(.custom("PressStart2P-Regular", size: 16))
                    .foregroundColor(.yellow)
                
                Spacer()
                
                Color.clear.frame(width: 20)
            }
            .padding()
            
            if viewModel.isLoading {
                loadingView
            } else if viewModel.candidates.isEmpty {
                emptyStateView
            } else {
                cardStackView
            }
            
            Spacer()
            actionButtonsView
        }
        .task {
            await viewModel.loadCandidates()
        }
    }
    
    private var backgroundView: some View {
        ZStack {
            Image("background_land")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            AnimatedClouds()
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Find Teammates")
                .font(.custom("PressStart2P-Regular", size: 20))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 2, x: 1, y: 1)
            Spacer()
        }
        .padding()
        .padding(.top, 20)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            Text("Finding teammates...")
                .font(.custom("PressStart2P-Regular", size: 12))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.6))
            Text("No more teammates")
                .font(.custom("PressStart2P-Regular", size: 14))
                .foregroundColor(.white)
            Text("Check back later!")
                .font(.custom("PressStart2P-Regular", size: 10))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var cardStackView: some View {
        let candidatesToShow = Array(viewModel.candidates.prefix(3))
        
        return ZStack {
            ForEach(candidatesToShow.indices, id: \.self) { index in
                let candidate = candidatesToShow[index]
                let isTopCard = index == 0
                
                UserCardView(user: candidate)
                    .offset(y: CGFloat(index * 10))
                    .scaleEffect(1 - CGFloat(index) * 0.05)
                    .opacity(isTopCard ? 1 : 0.5)
                    .zIndex(Double(candidatesToShow.count - index))
                    .gesture(
                        isTopCard ? DragGesture()
                            .onChanged { gesture in
                                viewModel.dragOffset = gesture.translation
                            }
                            .onEnded { gesture in
                                handleSwipe(gesture: gesture, user: candidate)
                            } : nil
                    )
                    .offset(isTopCard ? viewModel.dragOffset : .zero)
                    .rotationEffect(isTopCard ? .degrees(Double(viewModel.dragOffset.width / 20)) : .zero)
            }
        }
        .frame(height: 500)
        .padding(.horizontal, 20)
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 40) {
            Button(action: {
                if let currentUser = viewModel.candidates.first {
                    passUser(currentUser)
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 70, height: 70)
                    .background(Color.red.opacity(0.8))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            
            Button(action: {
                if let currentUser = viewModel.candidates.first {
                    likeUser(currentUser)
                }
            }) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 70, height: 70)
                    .background(Color.green.opacity(0.8))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
            }
        }
        .padding(.bottom, 40)
    }
    
    private func handleSwipe(gesture: DragGesture.Value, user: User) {
        let threshold: CGFloat = 100
        
        if gesture.translation.width > threshold {
            likeUser(user)
        } else if gesture.translation.width < -threshold {
            passUser(user)
        } else {
            withAnimation(.spring()) {
                viewModel.dragOffset = .zero
            }
        }
    }
    
    private func likeUser(_ user: User) {
        withAnimation(.spring()) {
            viewModel.dragOffset = CGSize(width: 500, height: 0)
        }
        
        Task {
            let result = await viewModel.swipe(on: user, action: .like)
            if result.match {
                matchedUser = user
                showingMatchAnimation = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.removeCurrentCandidate()
                viewModel.dragOffset = .zero
            }
        }
    }
    
    private func passUser(_ user: User) {
        withAnimation(.spring()) {
            viewModel.dragOffset = CGSize(width: -500, height: 0)
        }
        
        Task {
            _ = await viewModel.swipe(on: user, action: .pass)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.removeCurrentCandidate()
                viewModel.dragOffset = .zero
            }
        }
    }
}

struct UserCardView: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // User header
            HStack(spacing: 15) {
                ZStack(alignment: .bottomTrailing) {
                    // Profile Picture (Initial)
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(String(user.name.prefix(2)).uppercased())
                                .font(.custom("PressStart2P-Regular", size: 24))
                                .foregroundColor(.white)
                        )
                    
                    // Favorite Game Cover (Small badge)
                    if let favoriteGame = user.favoriteGame, let url = URL(string: favoriteGame.coverUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 35, height: 35)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.yellow, lineWidth: 2))
                                .shadow(radius: 3)
                        } placeholder: {
                            Color.clear
                        }
                        .offset(x: 5, y: 5)
                    }
                    
                    // Match Score Badge
                    if let score = user.matchScore {
                        ZStack {
                            Circle()
                                .fill(score >= 80 ? Color.green : (score >= 50 ? Color.yellow : Color.gray))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                            
                            VStack(spacing: 0) {
                                Text("\(score)%")
                                    .font(.custom("PressStart2P-Regular", size: 10))
                                    .foregroundColor(.white)
                            }
                        }
                        .offset(x: -5, y: -60) // Position at top right of avatar
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(user.name)
                        .font(.custom("PressStart2P-Regular", size: 16))
                        .foregroundColor(.white)
                    
                    if let favoriteGame = user.favoriteGame {
                        HStack(spacing: 5) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text(favoriteGame.name)
                                .font(.system(size: 12))
                                .lineLimit(1)
                        }
                        .foregroundColor(.yellow)
                    }
                }
                Spacer()
            }
            .padding(20)
            
            // Bio
            if let bio = user.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 15)
                    .lineLimit(3)
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Play styles
            if let playStyles = user.playStyles, !playStyles.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Play Styles")
                        .font(.custom("PressStart2P-Regular", size: 12))
                        .foregroundColor(.yellow)
                    
                    FlowLayout(items: playStyles) { style in
                        Text(style)
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(15)
                    }
                }
                .padding(20)
            }
            
            // Languages
            if let languages = user.languages, !languages.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Languages")
                        .font(.custom("PressStart2P-Regular", size: 12))
                        .foregroundColor(.yellow)
                    
                    FlowLayout(items: languages) { language in
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                                .font(.system(size: 10))
                            Text(language)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(15)
                    }
                }
                .padding(20)
            }
            
            // Availability
            if let availability = user.availability, !availability.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Availability")
                        .font(.custom("PressStart2P-Regular", size: 12))
                        .foregroundColor(.yellow)
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text(availability)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                }
                .padding(20)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.6),
                    Color.blue.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white, lineWidth: 3)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// Mode selection card for choosing between Match and Nearby
struct ModeSelectionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.custom("PressStart2P-Regular", size: 14))
                        .foregroundColor(.yellow)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color.opacity(0.5), lineWidth: 2)
            )
        }
    }
}
