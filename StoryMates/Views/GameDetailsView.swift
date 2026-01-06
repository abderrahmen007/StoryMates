import SwiftUI

struct GameDetailsView: View {
    @StateObject private var viewModel: GameDetailsViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    init(gameId: Int) {
        _viewModel = StateObject(wrappedValue: GameDetailsViewModel(gameId: gameId))
    }
    
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
                
                // Cloud animation
                AnimatedClouds()
            }
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                PixelatedNavigationBar(title: "Game Details", showBackButton: true) {
                    dismiss()
                }
                .padding(.top, 40) // Restore padding to clear status bar/notch since we are in edgesIgnoringSafeArea context

                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else if let game = viewModel.gameDetails {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Cover Image
                            AsyncImage(url: game.coverUrl) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 250)
                                        .frame(maxWidth: .infinity)
                                        .clipped()
                                        .cornerRadius(15)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(Color.white, lineWidth: 3)
                                        )
                                        .shadow(color: .black.opacity(0.3), radius: 5, x: 2, y: 2)
                                default:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.5))
                                        .frame(height: 250)
                                        .cornerRadius(15)
                                        .overlay(
                                            Image(systemName: "gamecontroller.fill")
                                                .font(.system(size: 50))
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(alignment: .leading, spacing: 15) {
                                // Title
                                Text(game.name)
                                    .font(.custom("PressStart2P-Regular", size: 18))
                                    .foregroundColor(.white)
                                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                                    .lineLimit(3)
                                
                                // Rating
                                if let rating = viewModel.gameRating {
                                    HStack(spacing: 8) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .font(.system(size: 16))
                                        Text(String(format: "%.1f", rating.average))
                                            .font(.custom("PressStart2P-Regular", size: 14))
                                            .foregroundColor(.white)
                                        Text("(\(rating.count) reviews)")
                                            .font(.custom("PressStart2P-Regular", size: 10))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.4))
                                    .cornerRadius(8)
                                    .shadow(color: .black, radius: 1, x: 1, y: 1)
                                }
                                
                                // Add to Collection Section
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Add to Collection")
                                        .font(.custom("PressStart2P-Regular", size: 14))
                                        .foregroundColor(.yellow)
                                        .shadow(color: .black, radius: 2, x: 1, y: 1)
                                    
                                    HStack(spacing: 10) {
                                        Picker("Status", selection: $viewModel.selectedStatus) {
                                            ForEach(viewModel.statuses, id: \.0) { status in
                                                Text(status.1).tag(status.0)
                                            }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .font(.custom("PressStart2P-Regular", size: 10))
                                        .accentColor(.black)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(Color.white.opacity(0.9))
                                        .cornerRadius(8)
                                        
                                        Button(action: {
                                            viewModel.addToCollection()
                                        }) {
                                            Image("button")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 120, height: 50)
                                                .overlay(
                                                    Text("Save")
                                                        .font(.custom("PressStart2P-Regular", size: 12))
                                                        .foregroundColor(.white)
                                                )
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                
                                // Description
                                if let description = game.description {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("About")
                                            .font(.custom("PressStart2P-Regular", size: 14))
                                            .foregroundColor(.yellow)
                                            .shadow(color: .black, radius: 2, x: 1, y: 1)
                                        
                                        Text(stripHTML(from: description))
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .shadow(color: .black, radius: 1, x: 1, y: 1)
                                            .lineLimit(nil)
                                            .padding()
                                            .background(Color.black.opacity(0.4))
                                            .cornerRadius(10)
                                    }
                                }
                                
                                // Screenshots
                                if let screenshots = game.screenshots, !screenshots.isEmpty {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Screenshots")
                                            .font(.custom("PressStart2P-Regular", size: 14))
                                            .foregroundColor(.yellow)
                                            .shadow(color: .black, radius: 2, x: 1, y: 1)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 15) {
                                                ForEach(screenshots, id: \.self) { urlString in
                                                    AsyncImage(url: URL(string: urlString)) { image in
                                                        image
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 220, height: 130)
                                                            .cornerRadius(10)
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 10)
                                                                    .stroke(Color.white, lineWidth: 2)
                                                            )
                                                    } placeholder: {
                                                        Rectangle()
                                                            .fill(Color.gray.opacity(0.5))
                                                            .frame(width: 220, height: 130)
                                                            .cornerRadius(10)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                        
                        // Reviews Section
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Reviews")
                                    .font(.custom("PressStart2P-Regular", size: 14))
                                    .foregroundColor(.yellow)
                                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.showingWriteReview = true
                                }) {
                                    Text("Rate & Review")
                                        .font(.custom("PressStart2P-Regular", size: 10))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            if viewModel.reviews.isEmpty {
                                Text("No reviews yet. Be the first!")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 20)
                            } else {
                                VStack(spacing: 15) {
                                    ForEach(viewModel.reviews) { review in
                                        ReviewRow(
                                            review: review,
                                            currentUserId: viewModel.currentUserId,
                                            onEdit: { review in
                                                viewModel.reviewToEdit = review
                                                viewModel.showingEditReview = true
                                            },
                                            onDelete: { review in
                                                viewModel.reviewToDelete = review
                                                viewModel.showingDeleteConfirmation = true
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 30)
                            }
                        }
                        
                        // Similar Games Section
                        if !viewModel.recommendations.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Similar Games")
                                    .font(.custom("PressStart2P-Regular", size: 14))
                                    .foregroundColor(.yellow)
                                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                                    .padding(.horizontal, 20)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(viewModel.recommendations) { recGame in
                                            RecommendationCard(game: recGame, sourceGameId: viewModel.gameId)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                .padding(.bottom, 30)
                            }
                        }
                    }
                    .padding(.bottom, 120) // Add padding for floating tab bar
                } else {
                    Spacer()
                    Text("Failed to load game details")
                        .font(.custom("PressStart2P-Regular", size: 12))
                        .foregroundColor(.red)
                        .shadow(color: .black, radius: 2, x: 1, y: 1)
                    Spacer()
                }
            }
            .edgesIgnoringSafeArea(.top) // Ensure backgorund fills top but content is padded manually
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadDetails()
        }
        .alert("Success", isPresented: $viewModel.showingStatusAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Game added to collection!")
        }
        .sheet(isPresented: $viewModel.showingWriteReview) {
            if let game = viewModel.gameDetails {
                WriteReviewView(
                    gameId: game.id,
                    gameName: game.name,
                    onReviewSubmitted: {
                        Task {
                            await viewModel.refreshReviews()
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showingEditReview, onDismiss: {
            viewModel.reviewToEdit = nil
        }) {
            if let _ = viewModel.reviewToEdit {
                EditReviewSheet(viewModel: viewModel)
            }
        }
        .alert("Delete Review", isPresented: $viewModel.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.reviewToDelete = nil
            }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteReview()
                }
            }
        } message: {
            Text("Are you sure you want to delete this review? This action cannot be undone.")
        }
    }
    
    private func stripHTML(from string: String) -> String {
        guard let data = string.data(using: .utf8) else { return string }
        if let attributedString = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil
        ) {
            return attributedString.string
        }
        return string
    }
}

// MARK: - Edit Review Sheet
struct EditReviewSheet: View {
    @ObservedObject var viewModel: GameDetailsViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Edit Review")
                        .font(.custom("PressStart2P-Regular", size: 14))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                // Star Rating
                VStack(spacing: 8) {
                    Text("Rating")
                        .font(.custom("PressStart2P-Regular", size: 10))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 15) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= viewModel.editedRating ? "star.fill" : "star")
                                .font(.system(size: 30))
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    viewModel.editedRating = star
                                }
                        }
                    }
                }
                .padding(.vertical)
                
                // Review Text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Review")
                        .font(.custom("PressStart2P-Regular", size: 10))
                        .foregroundColor(.yellow)
                    
                    TextEditor(text: $viewModel.editedText)
                        .frame(height: 150)
                        .padding(10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Save Button
                Button(action: {
                    Task {
                        await viewModel.updateReview()
                        dismiss()
                    }
                }) {
                    Text("Save Changes")
                        .font(.custom("PressStart2P-Regular", size: 12))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .disabled(viewModel.editedRating == 0 || viewModel.editedText.isEmpty)
                .padding()
            }
        }
        .onAppear {
            viewModel.prepareEditReview()
        }
    }
}

struct ReviewRow: View {
    let review: Review
    let currentUserId: String?
    let onEdit: ((Review) -> Void)?
    let onDelete: ((Review) -> Void)?
    
    // Check if this review belongs to current user
    var isOwnReview: Bool {
        guard let currentUserId = currentUserId else { return false }
        return review.userId == currentUserId
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Avatar
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Text(review.user?.avatar ?? "?")
                            .font(.custom("PressStart2P-Regular", size: 10))
                            .foregroundColor(.white)
                    )
                
                Text(review.user?.name ?? "Unknown")
                    .font(.custom("PressStart2P-Regular", size: 12))
                    .foregroundColor(.white)
                
                if isOwnReview {
                    Text("(You)")
                        .font(.custom("PressStart2P-Regular", size: 8))
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < review.rating ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            Text(review.text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(nil)
            
            HStack {
                Text(formatDate(review.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                // Edit/Delete buttons for own reviews
                if isOwnReview {
                    HStack(spacing: 12) {
                        Button(action: { onEdit?(review) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                Text("Edit")
                            }
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                        }
                        
                        Button(action: { onDelete?(review) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .padding()
        .background(isOwnReview ? Color.blue.opacity(0.15) : Color.white.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isOwnReview ? Color.blue.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct RecommendationCard: View {
    let game: Game
    let sourceGameId: Int
    private let networkManager = NetworkManager()
    private let authManager = AuthManager.shared
    
    var body: some View {
        NavigationLink(destination: GameDetailsView(gameId: game.id)) {
            VStack(alignment: .leading, spacing: 8) {
                // Game Cover
                AsyncImage(url: game.coverUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 140, height: 180)
                            .clipped()
                            .cornerRadius(10)
                    default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 140, height: 180)
                            .cornerRadius(10)
                            .overlay(
                                Image(systemName: "gamecontroller.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white, lineWidth: 2)
                )
                
                // Game Name
                Text(game.name)
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(width: 140, alignment: .leading)
                    .multilineTextAlignment(.leading)
                
                // Rating
                if let rating = game.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating / 20))
                            .font(.custom("PressStart2P-Regular", size: 8))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(width: 140)
        }
        .simultaneousGesture(TapGesture().onEnded {
            trackClick()
        })
    }
    
    private func trackClick() {
        guard let userId = authManager.userId else { return }
        
        Task {
            do {
                try await networkManager.trackRecommendationClick(
                    userId: userId,
                    sourceGameId: sourceGameId,
                    clickedGameId: game.id
                )
            } catch {
                print("Failed to track recommendation click: \(error)")
            }
        }
    }
}
