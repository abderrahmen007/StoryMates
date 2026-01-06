import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            if themeManager.isDarkMode {
                DarkThemeBackground()
            } else {
                Image("background_land")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                AnimatedClouds()
            }
            
            // Theme Toggle Button
            VStack {
                HStack {
                    Spacer()
                    AnimatedThemeToggle()
                        .padding(.top, 50)
                        .padding(.trailing, 20)
                }
                Spacer()
            }
            .zIndex(100)
            
            VStack(spacing: 0) {
                // Title at top
                Text("Profile")
                    .font(.custom("PressStart2P-Regular", size: 20))
                    .foregroundColor(themeManager.isDarkMode ? .white : .white)
                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Enhanced Profile Header with Favorite Game
                        ZStack {
                            // Favorite Game Background (if exists)
                            if let favoriteGame = viewModel.user?.favoriteGame {
                                AsyncImage(url: URL(string: favoriteGame.coverUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 200)
                                        .blur(radius: 8)
                                        .opacity(0.3)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 200)
                                }
                                .clipped()
                            }
                            
                            VStack(spacing: 15) {
                                // Profile Picture with Favorite Game Frame
                                ZStack {
                                    // Favorite game cover as frame
                                    if let favoriteGame = viewModel.user?.favoriteGame {
                                        AsyncImage(url: URL(string: favoriteGame.coverUrl)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 130, height: 130)
                                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(Color.yellow, lineWidth: 3)
                                                )
                                        } placeholder: {
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.white.opacity(0.2))
                                                .frame(width: 130, height: 130)
                                        }
                                    }
                                    
                                    // Profile icon in center
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 80, height: 80)
                                        .foregroundColor(.white)
                                        .background(
                                            Circle()
                                                .fill(Color.black.opacity(0.7))
                                                .frame(width: 90, height: 90)
                                        )
                                        .shadow(color: .black, radius: 5, x: 2, y: 2)
                                }
                                
                                // User Name
                                if let user = viewModel.user {
                                    Text(user.name)
                                        .font(.custom("PressStart2P-Regular", size: 16))
                                        .foregroundColor(.white)
                                        .shadow(color: .black, radius: 2, x: 1, y: 1)
                                    
                                    Text(user.email)
                                        .font(.custom("PressStart2P-Regular", size: 10))
                                        .foregroundColor(.white.opacity(0.7))
                                        .shadow(color: .black, radius: 1, x: 1, y: 1)
                                    
                                    // Favorite Game Name
                                    if let favoriteGame = user.favoriteGame {
                                        HStack(spacing: 5) {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                                .font(.system(size: 10))
                                            Text(favoriteGame.name)
                                                .font(.custom("PressStart2P-Regular", size: 10))
                                                .foregroundColor(.yellow)
                                                .lineLimit(1)
                                        }
                                        .shadow(color: .black, radius: 1, x: 1, y: 1)
                                    }
                                }
                                
                                Button(action: {
                                    viewModel.showingEditProfile = true
                                }) {
                                    Image("button")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: 180)
                                        .frame(height: 50)
                                        .overlay(
                                            Text("Edit Profile")
                                                .font(.custom("PressStart2P-Regular", size: 11))
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                            .padding(.vertical, 25)
                        }
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .padding(.horizontal, 20)
                        
                        // Bio Section
                        if let bio = viewModel.user?.bio, !bio.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("About Me")
                                    .font(.custom("PressStart2P-Regular", size: 14))
                                    .foregroundColor(.yellow)
                                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                                
                                Text(bio)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Level & XP Progress with Streak
                        VStack(spacing: 12) {
                            HStack {
                                Text("Level & Progress")
                                    .font(.custom("PressStart2P-Regular", size: 12))
                                    .foregroundColor(.yellow)
                                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                                
                                Spacer()
                                
                                // Streak Display
                                StreakDisplayView(
                                    currentStreak: viewModel.currentStreak,
                                    multiplier: viewModel.streakMultiplier
                                )
                            }
                            
                            LevelProgressView(
                                level: viewModel.currentLevel,
                                currentXP: viewModel.currentXP,
                                nextLevelXP: viewModel.nextLevelXP
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Achievements Showcase
                        if viewModel.hasAchievements {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Achievements")
                                    .font(.custom("PressStart2P-Regular", size: 14))
                                    .foregroundColor(.yellow)
                                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(viewModel.achievements, id: \.self) { achievementId in
                                            AchievementBadgeView(achievementId: achievementId, isUnlocked: true)
                                        }
                                        
                                        // Show some locked achievements
                                        ForEach(["collector", "speedrunner", "social"], id: \.self) { achievementId in
                                            if !viewModel.achievements.contains(achievementId) {
                                                AchievementBadgeView(achievementId: achievementId, isUnlocked: false)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Enhanced Stats Grid
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Gaming Stats")
                                .font(.custom("PressStart2P-Regular", size: 14))
                                .foregroundColor(.yellow)
                                .shadow(color: .black, radius: 2, x: 1, y: 1)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                EnhancedStatView(icon: "gamecontroller.fill", title: "Played", value: "\(viewModel.totalGamesPlayed)", color: .green)
                                EnhancedStatView(icon: "play.circle.fill", title: "Playing", value: "0", color: .blue)
                                EnhancedStatView(icon: "heart.fill", title: "Wishlist", value: "0", color: .red)
                                EnhancedStatView(icon: "trophy.fill", title: "Completed", value: "0", color: .yellow)
                                EnhancedStatView(icon: "clock.fill", title: "Hours", value: "\(viewModel.totalHoursPlayed)", color: .purple)
                                EnhancedStatView(icon: "star.fill", title: "Avg Rating", value: String(format: "%.1f", viewModel.averageRating), color: .orange)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Recent Activity Feed
                        if !viewModel.recentActivities.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Activity")
                                    .font(.custom("PressStart2P-Regular", size: 14))
                                    .foregroundColor(.yellow)
                                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                                
                                VStack(spacing: 10) {
                                    ForEach(viewModel.recentActivities.prefix(5)) { activity in
                                        ActivityRowView(activity: activity)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Gamer DNA Section
                        if let user = viewModel.user {
                            VStack(alignment: .leading, spacing: 20) {
                                // Tags
                                if let tags = user.gamerTags {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Gamer Tags")
                                            .font(.custom("PressStart2P-Regular", size: 16))
                                            .foregroundColor(.yellow)
                                            .shadow(color: .black, radius: 2, x: 1, y: 1)
                                        
                                        VStack(spacing: 8) {
                                            if let psn = tags.psn, !psn.isEmpty {
                                                TagRow(icon: "gamecontroller.fill", label: "PSN", value: psn)
                                            }
                                            if let xbox = tags.xbox, !xbox.isEmpty {
                                                TagRow(icon: "xbox.logo", label: "Xbox", value: xbox)
                                            }
                                            if let steam = tags.steam, !steam.isEmpty {
                                                TagRow(icon: "laptopcomputer", label: "Steam", value: steam)
                                            }
                                            if let discord = tags.discord, !discord.isEmpty {
                                                TagRow(icon: "bubble.left.fill", label: "Discord", value: discord)
                                            }
                                            if let nintendo = tags.nintendo, !nintendo.isEmpty {
                                                TagRow(icon: "gamecontroller", label: "Nintendo", value: nintendo)
                                            }
                                        }
                                    }
                                }
                                
                                // Play Styles
                                if let styles = user.playStyles, !styles.isEmpty {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Play Styles")
                                            .font(.custom("PressStart2P-Regular", size: 16))
                                            .foregroundColor(.yellow)
                                            .shadow(color: .black, radius: 2, x: 1, y: 1)
                                        
                                        FlowLayout(items: styles) { style in
                                            Text(style)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.black)
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 10)
                                                .background(Color.white)
                                                .cornerRadius(15)
                                        }
                                    }
                                }
                                
                                // Availability
                                if let availability = user.availability, !availability.isEmpty {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Availability")
                                            .font(.custom("PressStart2P-Regular", size: 16))
                                            .foregroundColor(.yellow)
                                            .shadow(color: .black, radius: 2, x: 1, y: 1)
                                        
                                        HStack {
                                            Image(systemName: "clock.fill")
                                                .foregroundColor(.white)
                                            Text(availability)
                                                .font(.system(size: 14))
                                                .foregroundColor(.white)
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Logout Button
                        Button(action: {
                            viewModel.logout()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16))
                                Text("Logout")
                                    .font(.custom("PressStart2P-Regular", size: 14))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                            .frame(minHeight: 100) // Extra space at bottom
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showingEditProfile) {
            EditProfileView(viewModel: viewModel)
        }
        .task {
            await viewModel.fetchProfile()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.custom("PressStart2P-Regular", size: 18))
                .foregroundColor(.yellow)
                .shadow(color: .black, radius: 2, x: 1, y: 1)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(title)
                .font(.custom("PressStart2P-Regular", size: 10))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .padding(.horizontal, 5)
        .background(Color.white.opacity(0.2))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white, lineWidth: 2)
        )
    }
}

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        ZStack {
            backgroundView
            
            VStack(spacing: 0) {
                headerView
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        bioSection
                        gamerTagsSection
                        availabilitySection
                        playStylesSection
                        languagesSection
                        favoriteGameSection
                    }
                    .padding(20)
                }
                saveButton
            }
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
            Text("Edit Profile")
                .font(.custom("PressStart2P-Regular", size: 20))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 2, x: 1, y: 1)
            Spacer()
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
            }
        }
        .padding(.top, 20)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    private var bioSection: some View {
        Group {
            Text("Bio")
                .font(.custom("PressStart2P-Regular", size: 14))
                .foregroundColor(.yellow)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
            
            TextEditor(text: $viewModel.editedBio)
                .frame(height: 100)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden) // Hide default background
                .padding(10)
                .background(Color.black.opacity(0.4))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if viewModel.editedBio.isEmpty {
                            Text("Tell us about yourself...")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.system(size: 14))
                                .padding(.leading, 14)
                                .padding(.top, 18)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
        }
    }
    
    private var gamerTagsSection: some View {
        Group {
            Text("Gamer Tags")
                .font(.custom("PressStart2P-Regular", size: 14))
                .foregroundColor(.yellow)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
            
            VStack(spacing: 12) {
                ProfileTextField(icon: "gamecontroller.fill", placeholder: "PSN ID", text: $viewModel.editedPsn)
                ProfileTextField(icon: "xbox.logo", placeholder: "Xbox Gamertag", text: $viewModel.editedXbox)
                ProfileTextField(icon: "laptopcomputer", placeholder: "Steam ID", text: $viewModel.editedSteam)
                ProfileTextField(icon: "bubble.left.fill", placeholder: "Discord", text: $viewModel.editedDiscord)
                ProfileTextField(icon: "gamecontroller", placeholder: "Nintendo ID", text: $viewModel.editedNintendo)
            }
        }
    }
    
    private var availabilitySection: some View {
        Group {
            Text("Availability")
                .font(.custom("PressStart2P-Regular", size: 14))
                .foregroundColor(.yellow)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
            
            ProfileTextField(icon: "clock.fill", placeholder: "e.g. Weeknights, Weekends", text: $viewModel.editedAvailability)
        }
    }
    
    private var playStylesSection: some View {
        Group {
            Text("Play Styles")
                .font(.custom("PressStart2P-Regular", size: 14))
                .foregroundColor(.yellow)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                ForEach(viewModel.availablePlayStyles, id: \.self) { style in
                    TagButton(title: style, isSelected: viewModel.selectedPlayStyles.contains(style)) {
                        if viewModel.selectedPlayStyles.contains(style) {
                            viewModel.selectedPlayStyles.remove(style)
                        } else {
                            viewModel.selectedPlayStyles.insert(style)
                        }
                    }
                }
            }
        }
    }
    
    private var languagesSection: some View {
        Group {
            Text("Languages")
                .font(.custom("PressStart2P-Regular", size: 14))
                .foregroundColor(.yellow)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                ForEach(viewModel.availableLanguages, id: \.self) { lang in
                    TagButton(title: lang, isSelected: viewModel.selectedLanguages.contains(lang)) {
                        if viewModel.selectedLanguages.contains(lang) {
                            viewModel.selectedLanguages.remove(lang)
                        } else {
                            viewModel.selectedLanguages.insert(lang)
                        }
                    }
                }
            }
        }
    }
    
    private var favoriteGameSection: some View {
        Group {
            Text("Favorite Game")
                .font(.custom("PressStart2P-Regular", size: 14))
                .foregroundColor(.yellow)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
            
            if let favoriteGame = viewModel.editedFavoriteGame {
                currentFavoriteGameView(favoriteGame)
            }
            
            gameSearchBar
            
            if !viewModel.searchResults.isEmpty {
                searchResultsList
            }
        }
    }
    
    private func currentFavoriteGameView(_ favoriteGame: FavoriteGame) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: favoriteGame.coverUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 60, height: 80)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(favoriteGame.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Button(action: {
                    viewModel.editedFavoriteGame = nil
                }) {
                    Text("Remove")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var gameSearchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white)
            
            TextField("", text: $viewModel.searchText)
                .placeholder(when: viewModel.searchText.isEmpty) {
                    Text("Search for a game...").foregroundColor(.white.opacity(0.5))
                }
                .foregroundColor(.white)
                .font(.system(size: 14))
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                    viewModel.searchResults = []
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
    }
    
    private var searchResultsList: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.searchResults.prefix(5)) { game in
                searchResultRow(game)
            }
        }
        .padding(.top, 8)
    }
    
    private func searchResultRow(_ game: Game) -> some View {
        Button(action: {
            viewModel.editedFavoriteGame = FavoriteGame(
                gameId: game.id,
                name: game.name,
                coverUrl: game.cover?.url ?? ""
            )
            viewModel.searchText = ""
            viewModel.searchResults = []
        }) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: game.cover?.url ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } placeholder: {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 70)
                }
                
                Text(game.name)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var saveButton: some View {
        Button(action: {
            Task {
                await viewModel.saveProfile()
            }
        }) {
            Image("button")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .overlay(
                    Text("Save Changes")
                        .font(.custom("PressStart2P-Regular", size: 14))
                        .foregroundColor(.white)
                )
        }
        .padding(.bottom, 20)
        .disabled(viewModel.isLoading)
    }
}


struct ProfileTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 24)
            
            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder).foregroundColor(.white.opacity(0.5))
                }
                .foregroundColor(.white)
                .font(.system(size: 14))
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct TagButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(isSelected ? Color.yellow : Color.black.opacity(0.4))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.yellow : Color.white, lineWidth: 1)
                )
        }
    }
}

struct EnhancedStatView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .shadow(color: .black, radius: 2, x: 1, y: 1)
            
            Text(value)
                .font(.custom("PressStart2P-Regular", size: 14))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
            
            Text(title)
                .font(.custom("PressStart2P-Regular", size: 8))
                .foregroundColor(.white.opacity(0.8))
                .shadow(color: .black, radius: 1, x: 1, y: 1)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.5), lineWidth: 2)
        )
    }
}
