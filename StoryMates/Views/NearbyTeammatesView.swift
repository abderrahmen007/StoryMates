//
//  NearbyTeammatesView.swift
//  StoryMates
//
//  Find teammates near your location
//

import SwiftUI
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdating() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}

@MainActor
class NearbyTeammatesViewModel: ObservableObject {
    @Published var isSearching = false
    @Published var isLoading = false
    @Published var nearbyUsers: [NetworkManager.NearbyUser] = []
    @Published var searchRange = 50
    @Published var errorMessage: String?
    
    // Game filter
    @Published var selectedGameId: Int? = nil
    @Published var selectedGameName: String? = nil
    
    private let networkManager = NetworkManager()
    private var pollingTask: Task<Void, Never>?
    
    func startSearching(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await networkManager.startNearbySearch(userId: userId, range: searchRange)
            isSearching = true
            startPolling(userId: userId)
        } catch {
            errorMessage = "Failed to start search: \(error.localizedDescription)"
        }
    }
    
    func stopSearching(userId: String) async {
        pollingTask?.cancel()
        
        do {
            try await networkManager.stopNearbySearch(userId: userId)
            isSearching = false
            nearbyUsers = []
        } catch {
            errorMessage = "Failed to stop search: \(error.localizedDescription)"
        }
    }
    
    func updateLocation(userId: String, location: CLLocation) async {
        do {
            try await networkManager.updateLocation(
                userId: userId,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        } catch {
            print("Failed to update location: \(error)")
        }
    }
    
    func updateRange(_ range: Int, userId: String) async {
        searchRange = range
        if isSearching {
            do {
                try await networkManager.startNearbySearch(userId: userId, range: range)
            } catch {
                print("Failed to update range: \(error)")
            }
        }
    }
    
    func setGameFilter(gameId: Int?, gameName: String?) {
        selectedGameId = gameId
        selectedGameName = gameName
        print("🎮 [Nearby] Game filter set: \(gameName ?? "None")")
    }
    
    func clearGameFilter() {
        selectedGameId = nil
        selectedGameName = nil
    }
    
    private func startPolling(userId: String) {
        pollingTask?.cancel()
        
        pollingTask = Task {
            while isSearching && !Task.isCancelled {
                do {
                    let users = try await networkManager.getNearbyUsers(userId: userId, range: searchRange, gameId: selectedGameId)
                    await MainActor.run {
                        nearbyUsers = users
                    }
                } catch {
                    print("Polling error: \(error)")
                }
                
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            }
        }
    }
    
    func cleanup(userId: String) {
        pollingTask?.cancel()
        if isSearching {
            Task {
                await stopSearching(userId: userId)
            }
        }
    }
}

struct NearbyTeammatesView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = NearbyTeammatesViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var matchingGames: [(String, Int)] = []
    @State private var selectedUser: NetworkManager.NearbyUser?
    @State private var gameSearchText = ""
    
    let onBack: () -> Void
    
    private let gameDatabase: [String: Int] = [
        "Witcher 3": 3328,
        "The Witcher 3": 3328,
        "Fortnite": 47137,
        "God of War": 29179,
        "Minecraft": 22509,
        "GTA V": 3498,
        "GTA 5": 3498,
        "Elden Ring": 326243,
        "Zelda: BOTW": 22511,
        "Call of Duty": 4200,
        "FIFA 24": 1140,
        "Assassin's Creed": 4729,
        "Valorant": 326278,
        "League of Legends": 10213,
        "PUBG": 326240,
        "Apex Legends": 326241
    ]
    
    private func updateSearch(query: String) {
        if query.count >= 2 {
            let term = query.lowercased()
            matchingGames = gameDatabase
                .filter { $0.key.lowercased().contains(term) }
                .map { ($0.key, $0.value) }
                .sorted { $0.0 < $1.0 }
        } else {
            matchingGames = []
        }
    }
    
    private func selectGame(name: String, id: Int) {
        gameSearchText = name
        matchingGames = []
        viewModel.setGameFilter(gameId: id, gameName: name)
        
        // Hide keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    var body: some View {
        ZStack {
            backgroundView
            
            VStack(spacing: 0) {
                headerView
                
                if locationManager.authorizationStatus == .notDetermined ||
                   locationManager.authorizationStatus == .denied ||
                   locationManager.authorizationStatus == .restricted {
                    permissionView
                } else {
                    mainContentView
                }
            }
        }
        .sheet(item: $selectedUser) { user in
            GamerCardSheet(user: user)
        }
        .onAppear {
            locationManager.requestPermission()
        }
        .onChange(of: locationManager.location) { oldValue, newLocation in
            guard let location = newLocation,
                  let userId = authManager.userId else { return }
            
            Task {
                await viewModel.updateLocation(userId: userId, location: location)
            }
        }
        .onDisappear {
            if let userId = authManager.userId {
                viewModel.cleanup(userId: userId)
            }
            locationManager.stopUpdating()
        }
    }
    
    private var backgroundView: some View {
        ZStack {
            if themeManager.isDarkMode {
                DarkThemeBackground()
            } else {
                Image("background_land")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                AnimatedClouds()
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(themeManager.isDarkMode ? .yellow : .orange)
            }
            
            Spacer()
            
            Text("NEARBY")
                .font(.custom("PressStart2P-Regular", size: 16))
                .foregroundColor(themeManager.isDarkMode ? .yellow : .black)
                .shadow(color: themeManager.isDarkMode ? .clear : .white.opacity(0.5), radius: 1)
            
            Spacer()
            
            Color.clear.frame(width: 20)
        }
        .padding()
    }
    
    private var permissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Location Required")
                .font(.custom("PressStart2P-Regular", size: 14))
                .foregroundColor(.white)
            
            Text("Enable location access to find nearby teammates")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.custom("PressStart2P-Regular", size: 12))
            .foregroundColor(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.yellow)
            .cornerRadius(10)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
    
    private var mainContentView: some View {
        VStack(spacing: 20) {
            // Range slider
            VStack(alignment: .leading, spacing: 10) {
                Text("Search Range: \(viewModel.searchRange) km")
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                HStack {
                    Text("5")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.searchRange) },
                            set: { newValue in
                                Task {
                                    await viewModel.updateRange(Int(newValue), userId: authManager.userId ?? "")
                                }
                            }
                        ),
                        in: 5...100,
                        step: 5
                    )
                    .tint(themeManager.isDarkMode ? .yellow : .orange)
                    
                    Text("100")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            
                // Game Filter with Dropdown
                ZStack(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FILTER BY GAME:")
                            .font(.custom("PressStart2P-Regular", size: 8))
                            .foregroundColor(.gray)
                        
                        HStack {
                            // Search input
                            HStack {
                                Image(systemName: "gamecontroller.fill")
                                    .foregroundColor(viewModel.selectedGameId != nil ? .yellow : .gray)
                                    .font(.system(size: 14))
                                
                                TextField("Type to search game...", text: $gameSearchText)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .autocorrectionDisabled()
                                    .onChange(of: gameSearchText) { oldValue, newValue in
                                        updateSearch(query: newValue)
                                    }
                                
                                if !gameSearchText.isEmpty {
                                    Button(action: {
                                        gameSearchText = ""
                                        viewModel.clearGameFilter()
                                        matchingGames = []
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        // Show current filter
                        if let gameName = viewModel.selectedGameName {
                            HStack {
                                Text("Filtering:")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                Text(gameName)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    .zIndex(1)
                    
                    // Dropdown List
                    if !matchingGames.isEmpty {
                        VStack(spacing: 0) {
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(matchingGames, id: \.1) { game in
                                        Button(action: {
                                            selectGame(name: game.0, id: game.1)
                                        }) {
                                            HStack {
                                                Image(systemName: "play.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.yellow)
                                                Text(game.0)
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                                        }
                                        Divider().background(Color.white.opacity(0.1))
                                    }
                                }
                            }
                        }
                        .frame(height: min(CGFloat(matchingGames.count * 44), 200))
                        .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                        .offset(y: 60) // Check alignment
                        .zIndex(100) // Ensure on top
                    }
                }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Radar
            RadarAnimationView(
                nearbyUsers: viewModel.nearbyUsers,
                range: viewModel.searchRange,
                onUserTapped: { user in
                    selectedUser = user
                }
            )
            .frame(height: 280)
            .padding(.horizontal, 20)
            
            // Nearby users list
            if !viewModel.nearbyUsers.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.nearbyUsers) { user in
                            NearbyUserRow(user: user)
                                .onTapGesture {
                                    selectedUser = user
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 200)
            } else if viewModel.isSearching {
                Text("Scanning for nearby players...")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .padding()
            }
            
            Spacer()
            
            // Search button
            Button(action: {
                guard let userId = authManager.userId else { return }
                
                Task {
                    if viewModel.isSearching {
                        await viewModel.stopSearching(userId: userId)
                        locationManager.stopUpdating()
                    } else {
                        locationManager.startUpdating()
                        await viewModel.startSearching(userId: userId)
                    }
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: viewModel.isSearching ? "stop.fill" : "antenna.radiowaves.left.and.right")
                        Text(viewModel.isSearching ? "STOP" : "START SCANNING")
                            .font(.custom("PressStart2P-Regular", size: 12))
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isSearching ? Color.red : Color.yellow)
                .cornerRadius(15)
            }
            .disabled(viewModel.isLoading)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }
}

struct GamerCardSheet: View {
    let user: NetworkManager.NearbyUser
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showFullProfile = false
    
    var body: some View {
        ZStack {
            // Themed background
            if themeManager.isDarkMode {
                Color(red: 0.1, green: 0.1, blue: 0.15)
                    .ignoresSafeArea()
            } else {
                Color(red: 0.9, green: 0.92, blue: 0.95)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 24) {
                // Handle bar
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 6)
                    .padding(.top, 10)
                
                HStack(alignment: .center, spacing: 20) {
                    // Avatar
                    AsyncImage(url: URL(string: user.avatar ?? "")) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Circle().fill(Color.gray)
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.yellow, lineWidth: 2))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        
                        Label("\(user.distance) km away", systemImage: "location.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // Status Box
                HStack {
                    Image(systemName: "gamecontroller.fill")
                        .foregroundColor(.black)
                    Text(user.favoriteGame != nil ? "Looking for \(user.favoriteGame!.name)" : "Online")
                        .font(.custom("PressStart2P-Regular", size: 10))
                        .foregroundColor(.black)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.yellow)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Actions
                HStack(spacing: 15) {
                    Button(action: {
                        showFullProfile = true
                    }) {
                        Text("View Profile")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                         // Invite logic handled in Profile View or here? 
                         // User asked for Invite Logic.
                         // I added Invite Button in UserProfileSheet.
                         // But I also have an "Invite" button here in GamerCardSheet.
                         // I should implement it here OR open profile.
                         // Let's make "Invite" here open profile to invite (simplest) or implement direct invite.
                         // Direct invite needs NetworkManager reference. GamerCardSheet doesn't have it.
                         // So opening Profile to Invite is improved flow.
                         showFullProfile = true
                    }) {
                        Text("Invite")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .presentationDetents([.fraction(0.40)])
        .sheet(isPresented: $showFullProfile) {
            UserProfileSheet(
                userId: user.id,
                initialName: user.name,
                initialAvatar: user.avatar
            )
        }
    }
}
            


struct NearbyUserRow: View {
    let user: NetworkManager.NearbyUser
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar placeholder
            Circle()
                .fill(themeManager.isDarkMode ? Color.cyan.opacity(0.3) : Color.orange.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(user.name.prefix(2)).uppercased())
                        .font(.custom("PressStart2P-Regular", size: 14))
                        .foregroundColor(themeManager.isDarkMode ? .cyan : .orange)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.custom("PressStart2P-Regular", size: 12))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                if let game = user.favoriteGame {
                    Text(game.name)
                        .font(.system(size: 11))
                        .foregroundColor(themeManager.isDarkMode ? .yellow : .orange)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(user.distance) km")
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .foregroundColor(themeManager.isDarkMode ? .cyan : .orange)
                
                Text("away")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.08))
        .cornerRadius(15)
    }
}
