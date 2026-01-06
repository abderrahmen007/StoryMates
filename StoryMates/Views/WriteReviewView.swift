import SwiftUI

struct WriteReviewView: View {
    @Environment(\.presentationMode) var presentationMode
    let gameId: Int
    let gameName: String
    let onReviewSubmitted: () -> Void
    
    @State private var rating: Int = 0
    @State private var reviewText: String = ""
    @State private var quickThoughts: String = ""
    @State private var isLoading = false
    @State private var isGeneratingAI = false
    @State private var showAIDraft = false
    @State private var aiGeneratedReview: String = ""
    @State private var errorMessage: String?
    
    private let networkManager = NetworkManager()
    private let authManager = AuthManager.shared
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text("Review \(gameName)")
                            .font(.custom("PressStart2P-Regular", size: 14))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        Spacer()
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    
                    // Star Rating
                    VStack(spacing: 8) {
                        Text("Your Rating")
                            .font(.custom("PressStart2P-Regular", size: 10))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 15) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 30))
                                    .foregroundColor(.yellow)
                                    .onTapGesture {
                                        rating = star
                                    }
                            }
                        }
                    }
                    .padding(.vertical)
                    
                    // Quick Thoughts (for AI)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Thoughts")
                            .font(.custom("PressStart2P-Regular", size: 10))
                            .foregroundColor(.yellow)
                        
                        TextField("loved the combat, story was meh...", text: $quickThoughts)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        
                        // AI Generate Button
                        Button(action: generateAIReview) {
                            HStack {
                                if isGeneratingAI {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.black)
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("AI Write for Me")
                                        .font(.custom("PressStart2P-Regular", size: 10))
                                }
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                        }
                        .disabled(rating == 0 || quickThoughts.isEmpty || isGeneratingAI)
                        .opacity(rating == 0 || quickThoughts.isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal)
                    
                    // AI Draft Preview (if generated)
                    if showAIDraft && !aiGeneratedReview.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple)
                                Text("AI Draft")
                                    .font(.custom("PressStart2P-Regular", size: 10))
                                    .foregroundColor(.purple)
                                Spacer()
                                Button("Use This") {
                                    reviewText = aiGeneratedReview
                                    showAIDraft = false
                                }
                                .font(.custom("PressStart2P-Regular", size: 8))
                                .foregroundColor(.green)
                            }
                            
                            Text(aiGeneratedReview)
                                .padding(12)
                                .foregroundColor(.white)
                                .background(Color.purple.opacity(0.2))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.purple, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Review Text Editor
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Review")
                            .font(.custom("PressStart2P-Regular", size: 10))
                            .foregroundColor(.yellow)
                        
                        TextEditor(text: $reviewText)
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
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    // Submit Button
                    Button(action: submitReview) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Submit Review")
                                .font(.custom("PressStart2P-Regular", size: 12))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(rating > 0 && !reviewText.isEmpty ? Color.blue : Color.gray)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(rating == 0 || reviewText.isEmpty || isLoading)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
    }
    
    private func generateAIReview() {
        guard rating > 0, !quickThoughts.isEmpty else { return }
        
        isGeneratingAI = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await networkManager.generateAIReview(
                    gameName: gameName,
                    rating: rating,
                    quickThoughts: quickThoughts
                )
                await MainActor.run {
                    aiGeneratedReview = response.generatedReview
                    showAIDraft = true
                    isGeneratingAI = false
                }
            } catch {
                await MainActor.run {
                    isGeneratingAI = false
                    errorMessage = "AI generation failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func submitReview() {
        guard let userId = authManager.userId else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await networkManager.createReview(
                    userId: userId,
                    gameId: gameId,
                    rating: rating,
                    text: reviewText
                )
                await MainActor.run {
                    isLoading = false
                    onReviewSubmitted()
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
